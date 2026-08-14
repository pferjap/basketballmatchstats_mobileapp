import 'dart:async';
import 'dart:math';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/env_config.dart';
import 'token_storage.dart';

/// Visible connection state of the realtime WebSocket channel
/// (Agent_Mobile.md §8.2).
enum WsConnectionState { connected, reconnecting, disconnected }

/// Exponential-backoff reconnection policy (Agent_Mobile.md §8.1).
class ReconnectConfig {
  const ReconnectConfig({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.multiplier = 2.0,
    this.maxAttempts,
    this.jitter = true,
    this.jitterFactor = 0.2,
  });

  /// Delay before the first reconnection attempt.
  final Duration initialDelay;

  /// Upper bound for the backoff delay.
  final Duration maxDelay;

  /// Growth factor applied per attempt (1s → 2s → 4s …).
  final double multiplier;

  /// Maximum reconnection attempts, or `null` to retry indefinitely.
  final int? maxAttempts;

  /// Whether to add randomized jitter to spread reconnection attempts.
  final bool jitter;

  /// Jitter magnitude as a fraction of the computed delay (±20% by default).
  final double jitterFactor;

  /// Backoff delay for a 1-based [attempt], capped at [maxDelay] and optionally
  /// spread by ±[jitterFactor].
  Duration delayForAttempt(int attempt, {Random? random}) {
    assert(attempt >= 1, 'attempt is 1-based');
    final base = initialDelay.inMilliseconds * pow(multiplier, attempt - 1);
    final capped = min(base, maxDelay.inMilliseconds.toDouble());
    if (!jitter) {
      return Duration(milliseconds: capped.round());
    }
    final rng = random ?? Random();
    final delta = capped * jitterFactor * (rng.nextDouble() * 2 - 1);
    final jittered = (capped + delta).clamp(0.0, double.infinity);
    return Duration(milliseconds: jittered.round());
  }
}

/// Default reconnection policy for the WebSocket channel.
const ReconnectConfig wsReconnectConfig = ReconnectConfig();

/// Supplies the JWT used to authenticate the WebSocket handshake.
typedef TokenProvider = FutureOr<String?> Function();

/// Builds an [io.Socket]; overridable in tests.
typedef SocketFactory = io.Socket Function(
  String url,
  Map<String, dynamic> options,
);

/// Singleton manager for the realtime read/notification channel
/// (Agent_Mobile.md §7.2, §8).
///
/// The WebSocket is strictly a read channel: it never persists data. The JWT is
/// sent in the handshake (`auth: { token }`); the client joins/leaves the
/// `match:{matchId}` room and exposes typed payload streams plus a connection
/// state stream for the UI's connection indicator.
class WsManager {
  WsManager({
    String? url,
    TokenProvider? tokenProvider,
    TokenStorage? tokenStorage,
    this.config = wsReconnectConfig,
    SocketFactory? socketFactory,
  })  : _url = url ?? EnvConfig.instance.wsUrl,
        _tokenProvider = tokenProvider ?? tokenStorage?.readAccessToken,
        _socketFactory = socketFactory ?? _defaultSocketFactory;

  final String _url;
  final TokenProvider? _tokenProvider;

  /// Reconnection policy applied to the underlying socket.
  final ReconnectConfig config;
  final SocketFactory _socketFactory;

  io.Socket? _socket;
  WsConnectionState _state = WsConnectionState.disconnected;

  final StreamController<WsConnectionState> _connectionController =
      StreamController<WsConnectionState>.broadcast();
  final StreamController<Map<String, dynamic>> _eventCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _scoreUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _matchUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Current connection state.
  WsConnectionState get state => _state;

  /// Whether the underlying socket reports an active connection.
  bool get isConnected => _socket?.connected ?? false;

  /// Connection state transitions for the UI connection indicator.
  Stream<WsConnectionState> get connectionState => _connectionController.stream;

  /// Emits when a new match event is created (`event.created`).
  Stream<Map<String, dynamic>> get onEventCreated =>
      _eventCreatedController.stream;

  /// Emits when the match score is updated (`score.updated`).
  Stream<Map<String, dynamic>> get onScoreUpdated =>
      _scoreUpdatedController.stream;

  /// Emits when the match state changes (`match.updated`).
  Stream<Map<String, dynamic>> get onMatchUpdated =>
      _matchUpdatedController.stream;

  /// Opens the WebSocket connection with handshake authentication.
  Future<void> connect() async {
    if (_socket != null) {
      return;
    }
    final token = await _tokenProvider?.call();
    final auth = <String, dynamic>{};
    if (token != null) {
      auth['token'] = token;
    }
    final options = io.OptionBuilder()
        .setTransports(<String>['websocket'])
        .disableAutoConnect()
        .enableReconnection()
        .setReconnectionDelay(config.initialDelay.inMilliseconds)
        .setReconnectionDelayMax(config.maxDelay.inMilliseconds)
        .setRandomizationFactor(config.jitter ? config.jitterFactor : 0)
        .setAuth(auth)
        .build();
    final maxAttempts = config.maxAttempts;
    if (maxAttempts != null) {
      options['reconnectionAttempts'] = maxAttempts;
    }
    final socket = _socketFactory(_url, options);
    _socket = socket;
    _wireHandlers(socket);
    socket.connect();
  }

  /// Joins the room for [matchId] to start receiving its events.
  void joinMatch(String matchId) {
    _socket?.emit('joinMatch', <String, dynamic>{'matchId': matchId});
  }

  /// Leaves the room for [matchId].
  void leaveMatch(String matchId) {
    _socket?.emit('leaveMatch', <String, dynamic>{'matchId': matchId});
  }

  /// Closes the socket and marks the connection as disconnected.
  void disconnect() {
    final socket = _socket;
    if (socket != null) {
      socket.dispose();
      _socket = null;
    }
    _setState(WsConnectionState.disconnected);
  }

  /// Disconnects and releases all stream resources.
  Future<void> dispose() async {
    disconnect();
    await _connectionController.close();
    await _eventCreatedController.close();
    await _scoreUpdatedController.close();
    await _matchUpdatedController.close();
  }

  void _wireHandlers(io.Socket socket) {
    socket.onConnect((_) => _setState(WsConnectionState.connected));
    socket.onDisconnect((_) => _setState(WsConnectionState.disconnected));
    socket.onConnectError((_) => _setState(WsConnectionState.reconnecting));
    socket.onReconnectAttempt((_) => _setState(WsConnectionState.reconnecting));
    socket.onReconnect((_) => _setState(WsConnectionState.connected));
    socket.on('event.created', (dynamic d) => _emit(_eventCreatedController, d));
    socket.on('score.updated', (dynamic d) => _emit(_scoreUpdatedController, d));
    socket.on('match.updated', (dynamic d) => _emit(_matchUpdatedController, d));
  }

  void _setState(WsConnectionState next) {
    _state = next;
    if (!_connectionController.isClosed) {
      _connectionController.add(next);
    }
  }

  void _emit(StreamController<Map<String, dynamic>> controller, dynamic data) {
    if (!controller.isClosed) {
      controller.add(payloadToMap(data));
    }
  }

  static io.Socket _defaultSocketFactory(
    String url,
    Map<String, dynamic> options,
  ) =>
      io.io(url, options);
}

/// Normalizes a dynamic socket payload into a `Map<String, dynamic>`.
///
/// Non-map payloads are wrapped under a `data` key so downstream consumers
/// always receive a map.
Map<String, dynamic> payloadToMap(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return data.map(
      (dynamic key, dynamic value) => MapEntry<String, dynamic>(
        key.toString(),
        value,
      ),
    );
  }
  return <String, dynamic>{'data': data};
}
