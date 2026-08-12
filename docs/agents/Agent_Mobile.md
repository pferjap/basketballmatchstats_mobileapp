# 📱 Agent.md — HoopAnalytics Mobile (Flutter App)

## 1. Rol y Perfil

Eres un **Arquitecto Mobile Senior especializado en Flutter y Dart**, con amplia experiencia en aplicaciones reactivas, manejo complejo de estados, comunicación bidireccional (WebSockets/REST) y estrategias offline-first.

Tu objetivo principal es construir una aplicación robusta, orientada a la **baja latencia y alta usabilidad**, garantizando que los anotadores de baloncesto puedan registrar acciones sin fallos bajo presión de tiempo, y que los espectadores puedan consumir datos en directo sin cuelgues ni pantallas congeladas.

Este cliente móvil consume la API backend de **HoopAnalytics** (NestJS + PostgreSQL/Supabase). La API es la **Fuente Única de Verdad**. Antes de generar código, el agente debe consultar estas reglas y comprobar que la solución propuesta es coherente con ellas y con el `Agent_api.md` del backend.

> **Referencia API**: `docs/agents/api/Agent_api.md` (fuente de verdad de endpoints, DTOs y modelo de dominio).

---

## 2. Visión del Producto y Métricas Clave

HoopAnalytics es una plataforma SaaS profesional multitenant para anotación de partidos de baloncesto en tiempo real, análisis táctico y explotación estadística.

### Métricas de Rendimiento Objetivo
| Métrica | Objetivo |
|---|---|
| Latencia end-to-end (tap → evento persistido) | `< 100ms` |
| Taps para registrar un evento complejo | `≤ 3` |
| Tiempo de carga de estadísticas en vivo | `< 100ms` (lectura de `MatchScore`) |
| Reconexión WebSocket tras caída | `< 5s` (primer reintento) |
| Tiempo de inicio en frío de la app | `< 2s` |

### Flujos UX Principales

- **Modo Anotador (`Statistician`):** Optimizado para velocidad extrema — layout apaisado, botones grandes, zonas táctiles amplias, feedback háptico, Shot Chart interactivo con coordenadas X/Y normalizadas (0-100).
- **Modo Espectador/Entrenador (`Viewer`/`Coach`):** Optimizado para lectura fluida de datos en tiempo real — play-by-play en vivo, marcador (lectura de `MatchScore`), box score por jugador (`PlayerMatchStats`), gráficas de tiro.

### Funcionalidades Core
- Autenticación y gestión de sesión segura (JWT + Refresh Token).
- Exploración de la jerarquía del Club (Club → Equipos → Jugadores).
- Gestión de partidos (Programar, iniciar, pausar entre cuartos, finalizar).
- Registro de eventos de partido (Play-by-play en ≤ 3 taps) con Optimistic UI.
- Seguimiento en directo vía WebSockets (sala `match:{matchId}`).
- Consulta de resultados históricos y box scores.
- *(Aplazado: Módulo profundo de analítica BI/IA — el scaffold de la feature debe existir).*

---

## 3. Principios Fundamentales de Desarrollo

1. **La Regla de los 3 Taps:** Registrar cualquier evento complejo (ej. "Triple anotado por Jugador 5 desde esquina derecha") con un máximo de 3 interacciones.
2. **Separación Estricta de Responsabilidades:** Cero lógica de negocio, peticiones HTTP o transformaciones de datos dentro de Widgets. Los Widgets solo leen estado y despachan intenciones.
3. **UX Orientada al Baloncesto:** Zonas táctiles ≥ 48x48dp, feedback visual inmediato y háptico (vibración corta) tras cada evento registrado.
4. **Optimistic UI como Estrategia Predeterminada:** Al registrar un evento, la UI se actualiza inmediatamente sin esperar confirmación del servidor. Si el servidor rechaza (4xx), se revierte el estado local y se muestra un `SnackBar` de error con el mensaje del backend (`errors[0].message`).
5. **Sincronización en Tiempo Real:** La UI debe reaccionar instantáneamente a eventos recibidos por WebSockets (`event.created`, `score.updated`, `match.updated`).
6. **Offline-First para Anotación:** El anotador nunca debe perder eventos por falta de red (ver §10).
7. **Seguridad Móvil:** Almacenamiento seguro de tokens (Secure Storage), sin exponer lógicas de autorización sensibles en el cliente.

---

## 4. Stack Tecnológico

### Core
| Categoría | Tecnología | Justificación |
|---|---|---|
| Framework | Flutter (última estable) | Cross-platform, alto rendimiento de render |
| Lenguaje | Dart (strict mode, `analysis_options.yaml` estricto) | Type-safety completo |
| Gestión de Estado | `Riverpod` (v2+) | Inmutabilidad, integración nativa con Streams/WebSockets, fácil testing con overrides |
| Red REST | `Dio` | Interceptores de Auth, retry, logging |
| Red WebSocket | `socket_io_client` | Compatibilidad con el Gateway NestJS (`@nestjs/platform-socket.io`) |
| Navegación | `go_router` | Deeplinks, guards de ruta, estado declarativo |
| Modelos | `freezed` + `json_serializable` | Modelos inmutables mapeados exactamente a los DTOs del backend |

### Persistencia Local
| Categoría | Tecnología | Uso |
|---|---|---|
| Tokens | `flutter_secure_storage` | JWT access token y refresh token |
| Configuraciones | `shared_preferences` | Preferencias de usuario, último entorno seleccionado |
| Base de datos offline | `Drift` (SQLite) | Cola de eventos offline, caché de plantillas/jugadores, estado de partido en progreso |

### Calidad y Observabilidad
| Categoría | Tecnología |
|---|---|
| Crash Reporting | `Sentry` (o Firebase Crashlytics) |
| Logging estructurado | `logger` (con niveles: verbose, debug, info, warning, error) |
| Analytics de uso | Firebase Analytics (eventos clave: `match_started`, `event_recorded`, `ws_reconnected`) |
| Testing | `flutter_test` (unit + widget), `integration_test`, `mocktail` para mocks |

---

## 5. Arquitectura Clean Architecture por Features

```text
lib/
├── core/                            # Elementos transversales
│   ├── config/                      # Configuración de entornos (ver §11)
│   │   └── env_config.dart          # Base URLs, feature flags por environment
│   ├── network/                     # Configuración de Dio, WebSockets, Interceptores
│   │   ├── dio_client.dart          # Instancia de Dio con interceptores
│   │   ├── auth_interceptor.dart    # Inyecta JWT, maneja 401 con refresh
│   │   ├── retry_interceptor.dart   # Retry con backoff exponencial
│   │   ├── ws_manager.dart          # Singleton de conexión WebSocket
│   │   └── connectivity_monitor.dart # Monitoreo de estado de red
│   ├── error/                       # Manejo global de excepciones
│   │   ├── failures.dart            # Clases Failure (ServerFailure, NetworkFailure, CacheFailure)
│   │   └── error_mapper.dart        # Mapea respuestas de error del backend (§10 API) a Failures
│   ├── database/                    # Configuración de Drift (SQLite)
│   │   └── app_database.dart        # Definición de tablas y DAOs
│   ├── usecases/                    # Interfaz base UseCase<Type, Params>
│   ├── theme/                       # Sistema de diseño
│   │   ├── app_theme.dart           # ThemeData light/dark
│   │   ├── app_colors.dart          # Paleta de colores semántica
│   │   ├── app_typography.dart      # Estilos de texto
│   │   └── ui_constants.dart        # Tamaños mínimos de touch target (48dp), spacing
│   ├── l10n/                        # Internacionalización (ARB files)
│   └── widgets/                     # Widgets reutilizables globales
│       ├── async_value_builder.dart # Wrapper para AsyncValue (Loading/Data/Error)
│       └── connection_indicator.dart # Punto verde/rojo de estado WS
├── features/
│   ├── auth/                        # Autenticación y sesión
│   ├── clubs/                       # Gestión de Clubs
│   ├── teams/                       # Equipos (separado de clubs, alineado con API)
│   ├── players/                     # Jugadores y fichas técnicas
│   ├── competitions/                # Ligas, Torneos, Fases
│   ├── seasons/                     # Temporadas deportivas
│   ├── matches/                     # Core Engine: Anotación y Live Score
│   ├── statistics/                  # Consulta de estadísticas (MatchScore, PlayerMatchStats)
│   ├── settings/                    # Perfil de usuario y preferencias
│   └── analytics/                   # (Scaffold) — Módulo BI/IA futuro
├── app.dart                         # MaterialApp con ProviderScope
└── main.dart                        # Entry point con inicialización de env
```

### Estructura Interna Obligatoria de cada Feature:
```text
lib/features/matches/
├── data/
│   ├── models/                  # Modelos Freezed mapeados a DTOs del backend
│   │   ├── match_model.dart
│   │   ├── event_model.dart     # Incluye EventType enum alineado con la API
│   │   └── match_score_model.dart
│   ├── datasources/
│   │   ├── match_remote_datasource.dart   # Llamadas REST via Dio
│   │   ├── match_ws_datasource.dart       # Streams desde WebSocket
│   │   └── match_local_datasource.dart    # Drift: caché y cola offline
│   └── repositories/
│       └── match_repository_impl.dart     # Implementa la interfaz del domain
├── domain/
│   ├── entities/                # Entidades puras de Dart (sin dependencias externas)
│   │   ├── match.dart
│   │   └── match_event.dart
│   ├── repositories/            # Interfaces abstractas
│   │   └── match_repository.dart
│   └── usecases/                # Casos de uso concretos
│       ├── start_match_usecase.dart
│       ├── record_event_usecase.dart
│       └── get_live_score_usecase.dart
└── presentation/
    ├── pages/                   # Pantallas (Scaffolds)
    │   ├── match_list_page.dart
    │   ├── match_live_page.dart
    │   └── court_view_page.dart # Pantalla de anotación
    ├── widgets/                 # Componentes UI específicos
    │   ├── shot_chart_widget.dart   # Cancha interactiva con coordenadas (0-100)
    │   ├── play_by_play_feed.dart
    │   └── score_header_widget.dart
    └── providers/               # Riverpod Providers
        ├── match_providers.dart
        └── live_score_provider.dart  # StreamProvider sobre WebSocket
```

---

## 6. Modelo de Datos del Cliente (Alineación con la API)

Los modelos Freezed del cliente deben mapear **exactamente** los DTOs y enums documentados en la API.

### Enum `EventType` (espejo de la API):
```dart
enum EventType {
  pointsMade,          // POINTS_MADE
  pointsMissed,        // POINTS_MISSED
  reboundOffensive,    // REBOUND_OFFENSIVE
  reboundDefensive,    // REBOUND_DEFENSIVE
  assist,              // ASSIST
  turnover,            // TURNOVER
  steal,               // STEAL
  block,               // BLOCK
  foulPersonal,        // FOUL_PERSONAL
  foulTechnical,       // FOUL_TECHNICAL
  foulUnsportsmanlike, // FOUL_UNSPORTSMANLIKE
  foulDisqualifying,   // FOUL_DISQUALIFYING
  freeThrowAwarded,    // FREE_THROW_AWARDED
  substitution,        // SUBSTITUTION
  timeout,             // TIMEOUT
  quarterStart,        // QUARTER_START
  quarterEnd,          // QUARTER_END
  matchStart,          // MATCH_START
  matchFinish,         // MATCH_FINISH
}
```

### Modelo de Evento (Freezed):
```dart
@freezed
class EventModel with _$EventModel {
  const factory EventModel({
    required String id,             // UUID v4
    required String matchId,
    required String teamId,
    String? playerId,               // Opcional para eventos de equipo
    required EventType eventType,
    required int period,            // 1..4 cuartos, 5+ prórrogas
    required String gameClock,      // "08:42" mm:ss
    Coordinates? coordinates,       // { x: 0-100, y: 0-100 } para Shot Charts
    Map<String, dynamic>? metadata, // JSONB del backend
    required DateTime createdAt,
  }) = _EventModel;

  factory EventModel.fromJson(Map<String, dynamic> json) =>
      _$EventModelFromJson(json);
}
```

### Formato de Respuesta del Backend
El cliente debe parsear siempre el wrapper estándar de la API:
```dart
@freezed
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required bool success,
    required int statusCode,
    required T data,
    ApiMeta? meta,              // Paginación: page, limit, total
    required DateTime timestamp,
  }) = _ApiResponse;
}

@freezed
class ApiError with _$ApiError {
  const factory ApiError({
    required bool success,      // siempre false
    required int statusCode,
    required List<ErrorDetail> errors, // code, message, details
    required DateTime timestamp,
  }) = _ApiError;
}
```

---

## 7. Flujo de Comunicación Cliente-Servidor

### 7.1. Operaciones REST (Mutaciones vía HTTP)
Todas las mutaciones son peticiones HTTP al backend NestJS. El cliente **nunca** persiste datos a través del WebSocket.

```text
Anotador (UI)
     │ tap
     ▼
Riverpod Provider (Optimistic Update local)
     │
     ▼ POST /api/v1/matches/:id/events
Dio (AuthInterceptor → RetryInterceptor)
     │
     ▼ Respuesta 201 → confirma │ 4xx → rollback + SnackBar error
Provider actualiza estado final
```

**Endpoints principales consumidos:**
- `POST /api/v1/auth/login` — Login (devuelve JWT access + refresh)
- `POST /api/v1/auth/refresh` — Refresh token
- `GET /api/v1/clubs` — Listar clubs del tenant
- `GET /api/v1/teams?clubId=X` — Equipos de un club
- `GET /api/v1/players?teamId=X` — Jugadores de un equipo
- `POST /api/v1/matches/:id/start` — Iniciar partido
- `POST /api/v1/matches/:id/events` — Registrar evento (body: EventType, playerId, period, gameClock, coordinates, metadata)
- `GET /api/v1/matches/:id/statistics` — Leer `MatchScore` + `PlayerMatchStats` (respuesta instantánea, read model proyectado)
- `GET /api/v1/matches/:id/events` — Historial completo de eventos (paginado)

### 7.2. Conexión WebSocket (Canal de Lectura en Tiempo Real)
El WebSocket es estrictamente un **canal de lectura/notificación**. Nunca persiste datos.

```text
┌─────────────────────────────────────────────────────┐
│ Handshake: io.connect(URL, { auth: { token: JWT }}) │
│ → joinMatch({ matchId })                            │
│                                                     │
│ Eventos escuchados (Streams):                       │
│   • event.created   → Nuevo evento en el partido    │
│   • score.updated   → MatchScore actualizado        │
│   • match.updated   → Cambio de estado del partido  │
│                                                     │
│ Al salir: leaveMatch({ matchId }) → disconnect      │
└─────────────────────────────────────────────────────┘
```

**Reglas:**
- La autenticación del WS se realiza en el handshake enviando el JWT en `auth.token`. Si el token es inválido, el servidor rechaza la conexión.
- El cliente se une a la sala `match:{matchId}` — solo recibe eventos de ese partido.
- La UI se reconstruye vía `StreamProvider` de Riverpod al recibir cada payload JSON.
- Al navegar fuera de la pantalla del partido: `leaveMatch` + dispose del stream.

### 7.3. Reconciliación tras Reconexión
Cuando el WebSocket se desconecta y reconecta, pueden haberse perdido eventos. El cliente debe:
1. Detectar la reconexión exitosa.
2. Solicitar vía REST `GET /api/v1/matches/:id/events?since={lastEventTimestamp}` los eventos perdidos.
3. Solicitar `GET /api/v1/matches/:id/statistics` para sincronizar el `MatchScore`.
4. Mergear con el estado local y actualizar la UI.

---

## 8. Estrategia de WebSocket y Resiliencia de Red

### 8.1. Reconexión Automática con Backoff Exponencial
```dart
// Configuración de reconexión en ws_manager.dart
const wsReconnectConfig = ReconnectConfig(
  initialDelay: Duration(seconds: 1),
  maxDelay: Duration(seconds: 30),
  multiplier: 2.0,            // 1s → 2s → 4s → 8s → 16s → 30s (cap)
  maxAttempts: null,           // Reintentar indefinidamente mientras la app esté activa
  jitter: true,                // Añadir ±20% de jitter para evitar thundering herd
);
```

### 8.2. Estados de Conexión Visibles al Usuario
El `ConnectionIndicator` widget debe reflejar estos estados:
- 🟢 **Conectado** — WebSocket activo y recibiendo heartbeats.
- 🟡 **Reconectando** — Intentando reconectar (mostrar intento N).
- 🔴 **Sin conexión** — Red no disponible (detectado por `connectivity_plus`).

### 8.3. Retry en Peticiones HTTP (Dio)
```dart
// retry_interceptor.dart
const httpRetryConfig = RetryConfig(
  maxRetries: 3,
  retryableStatuses: {408, 429, 500, 502, 503, 504},
  initialBackoff: Duration(milliseconds: 500),
  multiplier: 2.0,
);
// Las peticiones 4xx (excepto 408/429) NUNCA se reintentan — son errores de negocio.
```

---

## 9. Seguridad y Gestión de Sesión

### 9.1. Almacenamiento de Tokens
- **Access Token** y **Refresh Token**: almacenados en `flutter_secure_storage` (cifrado por el SO).
- Nunca almacenar tokens en `shared_preferences`, logs, o código fuente.

### 9.2. Auth Interceptor (Dio)
```text
Petición saliente:
  → Leer access token de secure storage
  → Inyectar header: Authorization: Bearer <accessToken>

Respuesta 401:
  → ¿Hay refresh token?
    → SÍ: Encolar peticiones pendientes, llamar POST /auth/refresh
      → Éxito: Actualizar tokens en secure storage, reintentar cola
      → Fallo: Limpiar tokens, redirigir a Login via go_router
    → NO: Redirigir a Login
```

**Race condition handling:** Cuando múltiples peticiones reciben 401 simultáneamente, solo UNA debe ejecutar el refresh. Las demás se encolan y esperan el resultado. Implementar con un `Completer<String>` compartido en el interceptor.

### 9.3. Protección de Rutas (go_router)
- Las rutas protegidas verifican la existencia de un token válido antes de renderizar.
- Si el token no existe o está expirado sin posibilidad de refresh → redirect a `/login`.
- Deep links a partidos (`/matches/:id/live`) deben pasar por el guard de auth primero.

---

## 10. Estrategia Offline-First (Anotación)

El anotador opera frecuentemente en pabellones deportivos con cobertura de red pobre o inexistente. La app **nunca debe perder un evento registrado**.

### 10.1. Cola de Eventos Offline (Drift/SQLite)
```text
┌──────────────────────────────────────────────────────┐
│ Tabla: pending_events                                │
│ ─────────────────────────────────────────────────────│
│ id (UUID)         │ Generado localmente              │
│ match_id          │ UUID del partido                 │
│ event_payload     │ JSON completo del evento          │
│ status            │ pending | syncing | synced | failed│
│ retry_count       │ Número de reintentos             │
│ created_at        │ Timestamp local                  │
│ synced_at         │ Timestamp de confirmación         │
└──────────────────────────────────────────────────────┘
```

### 10.2. Flujo de Sincronización
1. El anotador registra un evento → se persiste **siempre** en Drift como `pending`.
2. Si hay red: enviar inmediatamente vía `POST /events`. Si respuesta 2xx → marcar `synced`.
3. Si no hay red o falla: mantener como `pending`, reintentar cuando la red vuelva.
4. Al restaurar conectividad: un `SyncService` procesa la cola en orden FIFO (por `created_at`), respetando el orden cronológico de los eventos.
5. Si el servidor responde 4xx (error de negocio, ej. jugador no en pista): marcar como `failed`, notificar al anotador con opción de corregir o descartar.

### 10.3. Indicador Visual de Sincronización
- Mostrar un badge discreto con el número de eventos pendientes de sincronizar.
- Si hay eventos `failed`, mostrar un indicador de alerta que permita revisar y corregir.

---

## 11. Gestión de Entornos y Configuración

### Flavors de Flutter
Tres entornos con configuración independiente:

| Entorno | Base URL | Bundle ID suffix | Uso |
|---|---|---|---|
| `dev` | `http://localhost:3000/api/v1` | `.dev` | Desarrollo local |
| `staging` | `https://staging-api.hoopanalytics.com/api/v1` | `.staging` | QA y pruebas |
| `prod` | `https://api.hoopanalytics.com/api/v1` | (ninguno) | Producción |

```dart
// main_dev.dart / main_staging.dart / main_prod.dart
void main() {
  EnvConfig.init(Environment.dev); // o staging, prod
  runApp(const ProviderScope(child: HoopAnalyticsApp()));
}
```

**Feature flags:** Configurar en `EnvConfig` flags como `enableAnalyticsModule`, `enableShotChart`, `enableOfflineMode` para activar funcionalidades progresivamente.

---

## 12. Directrices de Diseño UI/UX

### 12.1. Pantalla de Anotación (Court View) — La Pantalla Más Crítica
- **Layout apaisado (landscape) forzado** para maximizar el área de interacción.
- **Shot Chart interactivo:** Representación gráfica de media cancha. Al tocar una zona, se capturan coordenadas normalizadas `{ x: 0-100, y: 0-100 }` que se envían en el campo `coordinates` del evento.
- **Botones de acción principales:** Tiro de 2, Tiro de 3, Tiro Libre, Rebote, Falta, Asistencia, Pérdida, Robo, Tapón, Sustitución, Tiempo muerto — todos con zona táctil ≥ 56x56dp.
- **Flujo rápido de anotación:** Seleccionar jugador (roster visible) → Seleccionar tipo de evento → (opcional) Tocar zona de cancha → Evento registrado. Máximo 3 taps.
- **Feedback inmediato:** Vibración háptica corta (15ms) + animación visual confirmando el evento registrado.
- **Undo rápido:** Botón de deshacer la última acción (registra un evento de compensación / soft-delete en la API).

### 12.2. Manejo de Errores No Intrusivo
- Errores de red: `SnackBar` naranja con "Sin conexión — evento guardado localmente".
- Errores de negocio (4xx): `SnackBar` rojo con el `message` del objeto `errors[0]` de la API.
- Errores críticos (500): `SnackBar` rojo + logging a Sentry.
- **Nunca** mostrar un diálogo modal bloqueante durante la anotación de un partido.

### 12.3. Indicadores Visuales Obligatorios
- **Estado de conexión WS:** Punto verde/amarillo/rojo persistente en la barra superior.
- **Período y reloj de juego:** Siempre visible y prominente.
- **Marcador:** Header sticky con `homeTeamScore` / `awayTeamScore` desde el read model `MatchScore`.
- **Faltas de equipo:** Contador visible por equipo y período (crítico para arbitraje).

### 12.4. Accesibilidad (a11y)
- Todos los widgets interactivos deben tener `Semantics` labels descriptivos.
- Contraste mínimo de 4.5:1 (WCAG AA) para texto sobre fondo.
- Touch targets mínimos de 48x48dp (Material guidelines).
- Soporte de `MediaQuery.textScaleFactor` para tamaños de texto accesibles.

---

## 13. Multitenancy y Roles (Alineado con la API)

### Roles del Sistema (espejo del backend):
| Rol | Permisos en la App |
|---|---|
| `SUPER_ADMIN` | Acceso total, gestión de todos los clubs |
| `CLUB_ADMIN` | Gestión completa de su club: equipos, jugadores, partidos |
| `COACH` | Ver equipos asignados, ver partidos y estadísticas, no anotar |
| `STATISTICIAN` | Anotar partidos asignados (Court View), ver estadísticas |
| `VIEWER` | Solo lectura: partidos en vivo, resultados históricos |

### Aislamiento en el Cliente
- El JWT contiene el `clubId` y roles del usuario. El cliente **nunca** debe permitir navegación o peticiones a recursos de otro club.
- Las rutas de `go_router` deben tener guards que verifiquen el rol antes de renderizar (ej. un `VIEWER` no puede acceder a `/matches/:id/annotate`).
- Los botones/acciones de la UI se muestran/ocultan según el rol del usuario decodificado del JWT.

---

## 14. Estrategia de Testing

### Pirámide de Tests
| Nivel | Herramienta | Cobertura mínima | Qué testear |
|---|---|---|---|
| **Unit** | `flutter_test` + `mocktail` | 80% en domain y data | UseCases, Repositories, modelos Freezed, lógica de cola offline, mappers |
| **Widget** | `flutter_test` | Features críticas | Court View (interacción Shot Chart), formularios, AsyncValue states |
| **Integration** | `integration_test` | Flujos E2E críticos | Login → Listar partidos → Abrir partido → Anotar evento → Verificar marcador |
| **Golden** | `flutter_test` (golden files) | Pantallas principales | Verificar regresiones visuales del Court View, marcador, play-by-play |

### Reglas de Testing
- Todo Provider de Riverpod debe ser testeable mediante `overrides` en `ProviderScope`.
- Los datasources remotos se mockean con `mocktail`; nunca hacer HTTP real en unit tests.
- El `SyncService` (cola offline) debe tener tests de integración con Drift in-memory.

---

## 15. CI/CD y Distribución

### Pipeline (GitHub Actions)
```text
PR / Push a main:
  1. analyze   → dart analyze --fatal-infos
  2. format    → dart format --set-exit-if-changed .
  3. test      → flutter test --coverage
  4. coverage  → Verificar umbral ≥ 70%
  5. build     → flutter build apk --release / flutter build ios --release

Release (tag vX.Y.Z):
  6. build     → Generar APK/AAB + IPA
  7. distribute → Firebase App Distribution (staging) / TestFlight + Play Console (prod)
```

### Versionado
- Seguir Conventional Commits (`feat:`, `fix:`, `chore:`, etc.).
- Versionado semántico en `pubspec.yaml`: `version: X.Y.Z+buildNumber`.

---

## 16. Performance y Optimización

1. **`const` constructors** en todos los widgets que no dependan de estado mutable.
2. **`RepaintBoundary`** en el Shot Chart y el feed de play-by-play para aislar repaints.
3. **`select()` en Riverpod** para que los widgets solo se reconstruyan ante cambios en el slice de estado que consumen.
4. **`ListView.builder`** (lazy) para listas de eventos, jugadores y partidos — nunca `ListView` con children directos para listas dinámicas.
5. **`cached_network_image`** para fotos de jugadores y escudos de equipos, con placeholder y manejo de error.
6. **Evitar rebuilds innecesarios:** No crear objetos nuevos (listas, maps) dentro del `build()`. Cachear en el provider.

---

## 17. State Restoration y Persistencia de Sesión

Si el SO mata la app durante un partido en anotación:
1. El estado del partido en progreso (marcador, período, reloj, roster en pista) se persiste periódicamente en Drift (cada 5 segundos o tras cada evento).
2. Al reabrir la app, si existe un partido en progreso, mostrar un diálogo: "Tienes un partido en curso. ¿Retomar?".
3. La cola de eventos offline (`pending_events`) sobrevive siempre al cierre de la app.

---

## 18. Reglas de Generación de Código para el Agente IA

Al generar código para esta app, el Agente DEBE seguir estas reglas:

1. **Modelos Inmutables:** Usar siempre `@freezed` para estados y modelos de datos, mapeando exactamente los DTOs del backend.
2. **Cero Lógica en Widgets:** La UI solo lee `AsyncValue` / estado y despacha intenciones a providers.
3. **Manejo Exhaustivo de Estados:** Todo provider asíncrono debe renderizar 3 estados: `loading`, `data`, `error`, usando `AsyncValue.when()` o el wrapper `AsyncValueBuilder`.
4. **Sistema de Diseño:** Usar `Theme.of(context)` y constantes de `app_colors.dart` / `app_typography.dart`. Nunca hardcodear colores, tamaños o tipografías.
5. **Código Completo:** Generar archivos completos con imports correctos. Sin `// TODO` ni pseudocódigo.
6. **Tipado Estricto:** Cero uso de `dynamic` sin cast explícito. Definir tipos para todo.
7. **Convenciones de Nombrado:** Archivos en `snake_case`, clases en `PascalCase`, variables/métodos en `camelCase`, constantes en `camelCase` prefijadas con `k` (ej. `kMinTouchTarget`).
8. **Breve Explicación:** Antes de mostrar código, explicar en 2-3 frases la decisión de diseño.

---

## 19. Prioridades de Decisiones de Arquitectura

En caso de dudas o conflictos de implementación, aplicar en orden descendente:

1. **Fiabilidad de la Anotación** — El anotador nunca pierde un evento (offline-first, cola persistente).
2. **Velocidad de Interacción** — La regla de 3 taps y el feedback < 100ms son innegociables.
3. **Seguridad y Aislamiento Multi-tenant** — No filtrar datos entre clubs, proteger tokens.
4. **Mantenibilidad y Limpieza** — Clean Architecture, separación de capas, código testeable.
5. **Rendimiento de UI** — Sin jank, 60fps constantes en la pantalla de anotación.
6. **Escalabilidad Futura** — Facilidad para añadir el módulo de analítica BI/IA.
7. **Simplicidad (KISS)** — No sobre-diseñar cuando una solución simple cumple los criterios.
