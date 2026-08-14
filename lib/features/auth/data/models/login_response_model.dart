import '../../domain/entities/auth_tokens.dart';
import 'user_model.dart';

/// Data-layer DTO for the `POST /auth/login` payload (the unwrapped `data`
/// object of the response envelope).
///
/// Hand-written (no Freezed) to stay compatible with the installed Dart SDK.
class LoginResponseModel {
  const LoginResponseModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        user: UserModel.fromJson(
          (json['user'] as Map).cast<String, dynamic>(),
        ),
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );

  final UserModel user;
  final String accessToken;
  final String refreshToken;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'user': user.toJson(),
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };

  /// The token pair as a domain [AuthTokens] value.
  AuthTokens toTokens() =>
      AuthTokens(accessToken: accessToken, refreshToken: refreshToken);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginResponseModel &&
          other.user == user &&
          other.accessToken == accessToken &&
          other.refreshToken == refreshToken;

  @override
  int get hashCode => Object.hash(user, accessToken, refreshToken);
}
