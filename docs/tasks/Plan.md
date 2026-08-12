# 📋 Plan de Implementación — HoopAnalytics Mobile

> Cada tarea es un commit independiente. Ejecutar en orden secuencial.
> Referencia de arquitectura: `docs/agents/Agent_Mobile.md`
> Referencia de diseño visual: `docs/images/`

---

## Fase 0 — Scaffolding del Proyecto

### T-001: Crear proyecto Flutter y configurar entorno base
**Objetivo:** Inicializar el proyecto Flutter con la estructura de carpetas definida en Agent_Mobile.md §5.
**Acciones:**
1. `flutter create --org com.hoopanalytics --project-name hoop_analytics .` (en la raíz del repo)
2. Configurar `analysis_options.yaml` con reglas estrictas (`strict-casts`, `strict-raw-types`, `strict-inference`).
3. Crear la estructura de carpetas completa bajo `lib/`:
   - `core/config/`, `core/network/`, `core/error/`, `core/database/`, `core/usecases/`, `core/theme/`, `core/l10n/`, `core/widgets/`
   - `features/auth/`, `features/clubs/`, `features/teams/`, `features/players/`, `features/competitions/`, `features/seasons/`, `features/matches/`, `features/statistics/`, `features/settings/`, `features/analytics/`
   - Dentro de cada feature crear: `data/models/`, `data/datasources/`, `data/repositories/`, `domain/entities/`, `domain/repositories/`, `domain/usecases/`, `presentation/pages/`, `presentation/widgets/`, `presentation/providers/`
4. Crear archivos placeholder `.gitkeep` en carpetas vacías.
5. Crear los entry points: `main.dart`, `main_dev.dart`, `main_staging.dart`, `main_prod.dart`.
**Resultado:** Proyecto compila con `flutter run` sin errores y la estructura de carpetas está lista.

---

### T-002: Configurar dependencias del proyecto (pubspec.yaml)
**Objetivo:** Añadir todas las dependencias del stack tecnológico (§4 Agent_Mobile.md).
**Acciones:**
1. Añadir dependencias principales:
   ```yaml
   dependencies:
     flutter_riverpod: ^2.5.0
     riverpod_annotation: ^2.3.0
     dio: ^5.4.0
     socket_io_client: ^2.0.3
     go_router: ^14.0.0
     freezed_annotation: ^2.4.0
     json_annotation: ^4.9.0
     flutter_secure_storage: ^9.2.0
     shared_preferences: ^2.2.0
     drift: ^2.18.0
     sqlite3_flutter_libs: ^0.5.0
     path_provider: ^2.1.0
     path: ^1.9.0
     connectivity_plus: ^6.0.0
     cached_network_image: ^3.3.0
     logger: ^2.3.0
     sentry_flutter: ^8.2.0
     uuid: ^4.4.0
     intl: ^0.19.0

   dev_dependencies:
     flutter_test:
       sdk: flutter
     riverpod_generator: ^2.4.0
     build_runner: ^2.4.0
     freezed: ^2.5.0
     json_serializable: ^6.8.0
     drift_dev: ^2.18.0
     mocktail: ^1.0.0
     integration_test:
       sdk: flutter
   ```
2. Ejecutar `flutter pub get`.
**Resultado:** Todas las dependencias resuelven correctamente.

---

### T-003: Configurar sistema de entornos (Flavors)
**Objetivo:** Implementar la configuración multi-entorno (§11 Agent_Mobile.md).
**Acciones:**
1. Crear `lib/core/config/environment.dart` con el enum `Environment { dev, staging, prod }`.
2. Crear `lib/core/config/env_config.dart` con clase singleton que almacene: `baseUrl`, `wsUrl`, feature flags (`enableOfflineMode`, `enableShotChart`, `enableAnalyticsModule`).
3. Implementar `main_dev.dart`, `main_staging.dart`, `main_prod.dart` que inicialicen `EnvConfig` con valores correspondientes y llamen a `runApp()`.
4. El `main.dart` por defecto apuntará a dev.
**Resultado:** La app puede arrancarse con diferentes entry points para cada entorno.

---

## Fase 1 — Core Infrastructure

### T-004: Implementar sistema de diseño (Theme)
**Objetivo:** Crear el sistema de diseño visual basado en las capturas de pantalla (fondo oscuro #1a1a2e, acentos naranja #F5A623, verde #4CAF50, rojo #E53935).
**Acciones:**
1. Crear `lib/core/theme/app_colors.dart`:
   - `background`: #0D1117 (oscuro principal)
   - `surface`: #1C2128 (cards/contenedores)
   - `primary`: #F5A623 (naranja — botón principal, acentos)
   - `success`: #4CAF50 (verde — canastas anotadas, conectado)
   - `error`: #E53935 (rojo — faltas, errores)
   - `warning`: #FF9800 (naranja claro — reconectando)
   - `textPrimary`: #FFFFFF
   - `textSecondary`: #9E9E9E
   - `divider`: #2D333B
2. Crear `lib/core/theme/app_typography.dart` con estilos: headline (marcador grande), title, body, caption.
3. Crear `lib/core/theme/ui_constants.dart`:
   - `kMinTouchTarget = 48.0`
   - `kActionButtonSize = 56.0`
   - `kSpacingXS = 4.0`, `kSpacingS = 8.0`, `kSpacingM = 16.0`, `kSpacingL = 24.0`, `kSpacingXL = 32.0`
4. Crear `lib/core/theme/app_theme.dart` que construya `ThemeData` dark usando los colores y tipografías.
**Resultado:** `Theme.of(context)` disponible globalmente con el sistema de diseño de la app.

---

### T-005: Implementar manejo global de errores y Failures
**Objetivo:** Crear las clases de error que mapean respuestas de la API (§5 y §6 Agent_Mobile.md).
**Acciones:**
1. Crear `lib/core/error/failures.dart`:
   - `Failure` (clase base sealed/abstract)
   - `ServerFailure(String message, String code, int statusCode)`
   - `NetworkFailure()`
   - `CacheFailure()`
   - `AuthFailure()` (token expirado sin refresh posible)
2. Crear `lib/core/error/exceptions.dart`:
   - `ServerException`, `NetworkException`, `CacheException`
3. Crear `lib/core/error/error_mapper.dart` que parsee el formato JSON de error del backend (`{ success: false, errors: [...] }`) y lo convierta en `ServerFailure`.
4. Crear `lib/core/usecases/usecase.dart` con la interfaz base `UseCase<Type, Params>`.
**Resultado:** Sistema de error tipado listo para usar en repositories.

---

### T-006: Implementar cliente Dio con interceptores
**Objetivo:** Configurar Dio con AuthInterceptor y RetryInterceptor (§8.3 y §9.2 Agent_Mobile.md).
**Acciones:**
1. Crear `lib/core/network/dio_client.dart`:
   - Instancia de Dio configurada con `baseUrl` desde `EnvConfig`.
   - Timeout de conexión: 15s, timeout de respuesta: 15s.
   - Content-Type: `application/json`.
2. Crear `lib/core/network/auth_interceptor.dart`:
   - `onRequest`: Lee access token de secure storage, inyecta `Authorization: Bearer <token>`.
   - `onError` (401): Implementa refresh con `Completer<String>` para evitar race conditions. Si refresh falla → limpiar tokens y emitir evento de logout.
3. Crear `lib/core/network/retry_interceptor.dart`:
   - Retry en status 408, 429, 500, 502, 503, 504.
   - Máximo 3 reintentos con backoff exponencial (500ms → 1s → 2s).
   - Nunca reintentar 4xx (excepto 408/429).
4. Crear `lib/core/network/api_response_parser.dart` para parsear el wrapper `{ success, statusCode, data, meta, timestamp }`.
**Resultado:** Toda petición HTTP pasa por auth + retry automáticamente.

---

### T-007: Implementar WebSocket Manager
**Objetivo:** Crear el singleton de conexión WebSocket con reconexión automática (§8.1 Agent_Mobile.md).
**Acciones:**
1. Crear `lib/core/network/ws_manager.dart`:
   - Conexión via `socket_io_client` con auth en handshake (`auth: { token: JWT }`).
   - Método `joinMatch(String matchId)` → emite `joinMatch` y se suscribe a la room.
   - Método `leaveMatch(String matchId)` → emite `leaveMatch`.
   - Stream de eventos: `onEventCreated`, `onScoreUpdated`, `onMatchUpdated`.
   - Reconexión automática con backoff exponencial (1s → 2s → 4s → 8s → 16s → 30s cap, jitter ±20%).
   - Exposición de un `Stream<WsConnectionState>` (connected, reconnecting, disconnected).
2. Crear `lib/core/network/connectivity_monitor.dart`:
   - Usa `connectivity_plus` para detectar estado de red.
   - Expone `Stream<bool> isOnline`.
**Resultado:** WebSocket se conecta, reconecta automáticamente y expone streams tipados.

---

### T-008: Implementar base de datos local (Drift)
**Objetivo:** Configurar Drift con la tabla de cola offline (§10.1 Agent_Mobile.md).
**Acciones:**
1. Crear `lib/core/database/app_database.dart`:
   - Tabla `pending_events`: `id` (text PK), `matchId` (text), `eventPayload` (text/JSON), `status` (text: pending|syncing|synced|failed), `retryCount` (integer), `createdAt` (dateTime), `syncedAt` (dateTime nullable).
   - Tabla `match_cache`: `matchId` (text PK), `data` (text/JSON), `updatedAt` (dateTime) — para state restoration.
2. Crear `lib/core/database/daos/pending_events_dao.dart`:
   - `insertEvent`, `markSyncing`, `markSynced`, `markFailed`, `getPendingEvents` (ordenados por createdAt ASC), `getFailedEvents`, `getPendingCount`.
3. Ejecutar `dart run build_runner build` para generar código de Drift.
**Resultado:** BD local funcional con tabla de cola offline lista para el SyncService.

---

### T-009: Implementar SyncService (cola offline)
**Objetivo:** Servicio que sincroniza eventos pendientes cuando hay red (§10.2 Agent_Mobile.md).
**Acciones:**
1. Crear `lib/core/network/sync_service.dart`:
   - Escucha `ConnectivityMonitor.isOnline`.
   - Cuando la red vuelve: procesa `pending_events` en orden FIFO.
   - Para cada evento: marcar `syncing` → POST → si 2xx marcar `synced` → si 4xx marcar `failed` → si 5xx/timeout dejar `pending` e incrementar `retryCount`.
   - Expone `Stream<int> pendingCount` para el badge visual.
   - Expone `Stream<List<PendingEvent>> failedEvents` para notificar al usuario.
2. Registrar como provider de Riverpod que se inicia con la app.
**Resultado:** Eventos nunca se pierden; se sincronizan automáticamente al recuperar red.

---

## Fase 2 — Feature: Autenticación

### T-010: Implementar domain y data layer de Auth
**Objetivo:** Crear entidades, repositorio e interfaz para autenticación.
**Acciones:**
1. `features/auth/domain/entities/user.dart`: Entidad `User` con `id`, `email`, `name`, `role` (enum), `clubId`, `avatarUrl`.
2. `features/auth/domain/entities/auth_tokens.dart`: `AuthTokens` con `accessToken`, `refreshToken`.
3. `features/auth/domain/repositories/auth_repository.dart`: Interfaz abstracta con `login(email, password)`, `refresh()`, `logout()`, `getCurrentUser()`.
4. `features/auth/data/models/user_model.dart`: Modelo Freezed alineado con el DTO del backend.
5. `features/auth/data/models/login_response_model.dart`: Freezed para la respuesta de login.
6. `features/auth/data/datasources/auth_remote_datasource.dart`: Llamadas a `POST /auth/login`, `POST /auth/refresh`.
7. `features/auth/data/datasources/auth_local_datasource.dart`: Lectura/escritura de tokens en `flutter_secure_storage`.
8. `features/auth/data/repositories/auth_repository_impl.dart`: Implementación que coordina remote + local.
**Resultado:** Capa de datos de auth completa y testeable.

---

### T-011: Implementar presentation layer de Auth (Login Screen)
**Objetivo:** Crear la pantalla de Login basada en el diseño de `login_screen.png`.
**Referencia visual:** `docs/images/login_screen.png`
**Diseño a implementar:**
- Fondo oscuro (#0D1117) con imagen de cancha de baloncesto en la parte superior (gradiente con fade).
- Logo "BASKETSTATS — ANOTA · SINCRONIZA · COMPITE" centrado sobre la imagen.
- Título: "Bienvenido de nuevo" (blanco, bold) + subtítulo "Inicia sesión para continuar" (gris).
- Campo "Correo electrónico" con icono de sobre, placeholder "tu@email.com", borde redondeado, fondo gris oscuro.
- Campo "Contraseña" con icono de candado, dots de password, botón de ojo para toggle visibility, fondo gris oscuro.
- Link "¿Olvidaste tu contraseña?" alineado a la derecha (color naranja/azul claro).
- Botón "Iniciar sesión" full-width, fondo naranja (#F5A623), texto blanco bold, border-radius ~12px.
- Separador "o continúa con" con líneas a los lados.
- Footer: "© 2024 BasketStats. Todos los derechos reservados." (gris, centrado).
**Acciones:**
1. Crear `features/auth/presentation/pages/login_page.dart`.
2. Crear `features/auth/presentation/widgets/login_form.dart` (campos + validación).
3. Crear `features/auth/presentation/widgets/login_header.dart` (imagen + logo).
4. Crear `features/auth/presentation/providers/auth_providers.dart`:
   - `authStateProvider`: Notifier que gestiona login/logout.
   - `currentUserProvider`: Expone el usuario actual o null.
5. Manejar estados: idle, loading (botón con spinner), error (SnackBar rojo).
**Resultado:** Login funcional con validación de campos y feedback visual.

---

### T-012: Configurar go_router con guards de autenticación
**Objetivo:** Definir el árbol de rutas con protección por auth y rol (§9.3 Agent_Mobile.md).
**Acciones:**
1. Crear `lib/app_router.dart`:
   - Ruta `/login` → LoginPage (pública).
   - Ruta `/` → MainMenuPage (protegida).
   - Ruta `/matches/:id/live` → MatchLivePage (protegida).
   - Ruta `/matches/:id/annotate` → CourtViewPage (protegida, solo STATISTICIAN/CLUB_ADMIN).
   - Ruta `/teams` → TeamsPage (protegida).
   - Ruta `/players` → PlayersPage (protegida).
   - Ruta `/settings` → SettingsPage (protegida).
2. Implementar `redirect` global: si no hay token válido → `/login`. Si hay token y está en `/login` → `/`.
3. Implementar guard de rol para rutas de anotación.
**Resultado:** Navegación completa con protección; deep links resuelven auth antes de renderizar.

---

## Fase 3 — Feature: Menú Principal (Home)

### T-013: Implementar pantalla de Menú Principal (Home)
**Objetivo:** Crear la pantalla principal post-login basada en `main_menu_screen.png`.
**Referencia visual:** `docs/images/main_menu_screen.png`
**Diseño a implementar:**
- **Header:** Avatar circular del usuario (con borde naranja) + "Hola, {nombre}" (blanco bold) + "Tu perfil" (gris, clickable) — esquina superior izquierda.
- **Logo central:** Logo de BasketStats grande con el balón y el escudo, tagline "ANOTA · SINCRONIZA · COMPITE".
- **Sección "¿Qué quieres hacer?"** (título blanco).
- **Grupo "PARTIDO EN DIRECTO"** (label gris uppercase):
  - Card "Tomar anotaciones" — icono de portapapeles/anotación (naranja), subtítulo "Registra las acciones en directo de un partido", flecha ">". Borde izquierdo naranja.
  - Card "Asistir a un partido" — icono de señal/broadcast (naranja), subtítulo "Sigue el partido en directo como espectador", flecha ">". Borde izquierdo naranja.
- **Grupo "ADMINISTRACIÓN"** (label gris uppercase):
  - Card "Estadísticas y resultados" — icono barras (verde), subtítulo "Consulta estadísticas, resultados y clasificaciones". Borde izquierdo verde.
  - Card "Administrar mi equipo" — icono persona con escudo (púrpura), subtítulo "Gestiona jugadores, cuerpo técnico y configuración del equipo". Borde izquierdo púrpura.
  - Card "Panel de administración" — icono engranaje (amarillo), subtítulo "Administra la plataforma, usuarios, equipos y competiciones". Borde izquierdo amarillo.
- Fondo: oscuro (#0D1117). Cards: fondo gris oscuro (#1C2128) con bordes sutiles.
- **Visibilidad por rol:** Las cards se muestran/ocultan según el rol del JWT:
  - `VIEWER`: solo "Asistir a un partido" y "Estadísticas y resultados".
  - `STATISTICIAN`: + "Tomar anotaciones".
  - `COACH`: + "Estadísticas y resultados", "Administrar mi equipo".
  - `CLUB_ADMIN`: todas excepto "Panel de administración".
  - `SUPER_ADMIN`: todas.
**Acciones:**
1. Crear `features/auth/presentation/pages/main_menu_page.dart`.
2. Crear widget `menu_card.dart` reutilizable (icono, título, subtítulo, color de borde, onTap).
3. Crear widget `user_header.dart` (avatar + saludo).
4. Conectar cada card con la navegación de `go_router`.
**Resultado:** Home page funcional con navegación condicional por rol.

---

## Fase 4 — Feature: Matches (Modelo de datos)

### T-014: Implementar modelos de datos de Matches y Events
**Objetivo:** Crear los modelos Freezed alineados con la API (§6 Agent_Mobile.md).
**Acciones:**
1. Crear `features/matches/data/models/event_type.dart` con el enum completo (19 tipos).
2. Crear `features/matches/data/models/coordinates.dart`: `@freezed class Coordinates { x, y }`.
3. Crear `features/matches/data/models/event_model.dart` (Freezed, con factory fromJson).
4. Crear `features/matches/data/models/match_model.dart`: `id`, `homeTeamId`, `awayTeamId`, `status` (enum: scheduled, inProgress, finished), `competitionId`, `seasonId`, `scheduledAt`, `startedAt`, `finishedAt`.
5. Crear `features/matches/data/models/match_score_model.dart`: `matchId`, `homeTeamScore`, `awayTeamScore`, `currentPeriod`, `gameClock`.
6. Crear `features/matches/data/models/player_match_stats_model.dart`: `playerId`, `points`, `rebounds`, `assists`, `steals`, `blocks`, `turnovers`, `fouls`, `minutes`.
7. Crear `features/statistics/data/models/` con modelos equivalentes para la feature de estadísticas.
8. Ejecutar `dart run build_runner build`.
**Resultado:** Modelos inmutables generados, serializables a/desde JSON del backend.

---

### T-015: Implementar domain layer de Matches
**Objetivo:** Entidades puras y repositorio abstracto.
**Acciones:**
1. Crear `features/matches/domain/entities/match.dart` (entidad pura sin dependencias).
2. Crear `features/matches/domain/entities/match_event.dart`.
3. Crear `features/matches/domain/entities/match_score.dart`.
4. Crear `features/matches/domain/repositories/match_repository.dart`:
   - `getMatches(page, limit)` → lista paginada.
   - `getMatch(matchId)` → detalle.
   - `startMatch(matchId)` → Match actualizado.
   - `getMatchStatistics(matchId)` → MatchScore + PlayerMatchStats[].
   - `getMatchEvents(matchId, {since})` → lista de eventos paginada.
5. Crear `features/matches/domain/repositories/event_repository.dart`:
   - `recordEvent(matchId, EventParams)` → Event.
   - `undoLastEvent(matchId)` → void.
6. Crear use cases: `StartMatchUseCase`, `RecordEventUseCase`, `GetLiveScoreUseCase`, `GetMatchEventsUseCase`.
**Resultado:** Capa de dominio limpia, sin dependencias externas.

---

### T-016: Implementar data layer de Matches (datasources + repository)
**Objetivo:** Conectar con la API y el WebSocket.
**Acciones:**
1. Crear `features/matches/data/datasources/match_remote_datasource.dart`:
   - Usa `DioClient` para las llamadas REST.
   - Parsea respuestas con `ApiResponseParser`.
2. Crear `features/matches/data/datasources/match_ws_datasource.dart`:
   - Usa `WsManager` para exponer Streams de `event.created`, `score.updated`, `match.updated`.
3. Crear `features/matches/data/datasources/match_local_datasource.dart`:
   - Usa `AppDatabase` (Drift) para cola offline y caché de estado.
4. Crear `features/matches/data/repositories/match_repository_impl.dart`:
   - Implementa `MatchRepository`.
   - En `recordEvent`: persiste siempre en Drift como `pending` → intenta POST → actualiza estado.
   - Implementa reconciliación (§7.3): al reconectar WS, pide eventos `since` y sincroniza.
**Resultado:** Repository completo con soporte offline-first.

---

## Fase 5 — Feature: Sala de Retransmisión (Live Match)

### T-017: Implementar pantalla de Retransmisión en Directo
**Objetivo:** Crear la pantalla de espectador basada en `sala_restransmision_partido.png`.
**Referencia visual:** `docs/images/sala_restransmision_partido.png`
**Diseño a implementar:**
- **AppBar:**
  - Flecha atrás (izquierda).
  - Título centrado: "Tigres vs Águilas" (blanco bold) + subtítulo "Liga Nacional · Jornada 12" (gris).
  - Badge "EN DIRECTO" (rojo con icono de broadcast, esquina superior derecha).
- **Score Header (card oscura):**
  - Escudo equipo local (izquierda) + nombre "TIGRES" + nombre club "Tigres Basket".
  - Marcador grande: "72 - 68" (números blancos enormes ~48sp, el equipo ganador en verde).
  - Escudo equipo visitante (derecha) + nombre "ÁGUILAS" + nombre club "Águilas BC".
  - Centro inferior: "Q3 · 05:47" (período en verde, tiempo en blanco) + "Tiempo de cuarto".
  - Dots de navegación (5 dots: Q1, Q2, Q3, Q4, resumen) debajo.
- **Play-by-Play Feed (lista scrollable):**
  - Cada item: `gameClock` (izquierda, gris) | icono circular del tipo de evento (coloreado) | Texto del evento (bold) + detalle (#número jugador) | Marcador parcial (derecha) + nombre equipo.
  - Iconos por tipo: canasta (aro verde), rebote (círculo naranja), sustitución (flechas azul/verde), falta (mano roja), triple (balón verde), pérdida (estrellas azules).
  - Marcador parcial: el equipo que anotó tiene su score en verde.
  - Sustituciones: "Entra #9 Álvaro Ruiz" (verde) / "Sale #15 Daniel Torres" (rojo).
- **Botón inferior:** "↓ Cargar acciones anteriores" (borde azul, full-width).
- Fondo: oscuro (#0D1117).
**Acciones:**
1. Crear `features/matches/presentation/pages/match_live_page.dart`.
2. Crear `features/matches/presentation/widgets/score_header_widget.dart` (marcador + escudos + período).
3. Crear `features/matches/presentation/widgets/play_by_play_feed.dart` (ListView.builder).
4. Crear `features/matches/presentation/widgets/event_feed_item.dart` (icono + texto + marcador parcial).
5. Crear `features/matches/presentation/widgets/live_badge.dart`.
6. Crear `features/matches/presentation/widgets/connection_indicator.dart` (punto verde/amarillo/rojo).
7. Crear `features/matches/presentation/providers/live_match_provider.dart`:
   - Se suscribe al WebSocket al entrar (`joinMatch`).
   - Expone `MatchScore` y `List<EventModel>` como streams.
   - Se desuscribe al salir (`leaveMatch`).
   - Implementa reconciliación tras reconexión.
**Resultado:** Pantalla de partido en vivo con actualización en tiempo real vía WebSocket.

---

## Fase 6 — Feature: Pantalla de Anotación (Court View)

### T-018: Implementar pantalla de Anotación — Layout y Score Header
**Objetivo:** Crear la estructura base de la pantalla de anotación basada en `anotation_screen.png`.
**Referencia visual:** `docs/images/anotation_screen.png`
**Diseño a implementar (parte superior):**
- **Barra superior:** Icono hamburguesa (izq) | "1er CUARTO ▾" (dropdown para cambiar período, centro) | Icono engranaje/settings (der).
- **Score Header compacto:**
  - Escudo local (icono pequeño) + "TIGRES" + score grande "24" (blanco) | Reloj central "07:32" (naranja grande, con icono play debajo) | "ÁGUILAS" + score grande "18" + escudo visitante.
  - Debajo de cada equipo: "FALTAS ●●●●" (dots verdes para faltas contadas, grises para las que quedan).
- **Tab bar:** "⚡ ANOTAR ACCIÓN" (activo, borde naranja inferior) | "≡ HISTORIAL" (inactivo, gris).
**Acciones:**
1. Crear `features/matches/presentation/pages/court_view_page.dart` (scaffold principal, portrait forzado en esta versión).
2. Crear `features/matches/presentation/widgets/annotation_score_header.dart`.
3. Crear `features/matches/presentation/widgets/period_selector.dart` (dropdown).
4. Crear `features/matches/presentation/widgets/foul_indicator.dart` (dots de faltas por equipo).
5. Crear `features/matches/presentation/widgets/game_clock_widget.dart` (reloj central naranja).
**Resultado:** Parte superior de la pantalla de anotación con marcador y período funcionales.

---

### T-019: Implementar pantalla de Anotación — Panel de Acciones
**Objetivo:** Crear el grid de botones de acción con el flujo de 3 taps.
**Referencia visual:** `docs/images/anotation_screen.png`
**Diseño a implementar (parte central — grid de acciones):**
- **Sección "TIRO"** (separador con texto centrado):
  - Botón "2 PT CANASTA" — icono aro verde, fondo card oscuro, texto verde.
  - Botón "3 PT CANASTA" — icono balón con arco verde, fondo card oscuro, texto verde.
  - Botón "FALLO" — icono aro con X, fondo card oscuro, texto blanco.
- **Sección "ACCIONES"** (separador):
  - Botón "ASISTENCIA" — icono dos jugadores pasándose balón (naranja).
  - Botón "REBOTE" — icono jugador saltando con balón (naranja).
  - Botón "PÉRDIDA" — icono flechas circulares (naranja).
- **Sección "FALTAS"** (separador):
  - Botón "FALTA PERSONAL" — icono mano abierta (rojo), fondo rojizo oscuro.
  - Botón "FALTA EN ATAQUE" — icono manos (rojo), fondo rojizo oscuro.
  - Botón "TIROS LIBRES" — icono diana/target (rojo), fondo rojizo oscuro.
- **Indicador de flujo (bottom de la sección):** "① TIPO DE ACCIÓN ---- ② JUGADOR ---- ③ DETALLES (OPCIONAL)" — steps con el paso actual resaltado en naranja.
- Todos los botones: zona táctil ≥ 56x56dp, border-radius, icono encima + texto debajo.
**Acciones:**
1. Crear `features/matches/presentation/widgets/action_button.dart` (widget reutilizable: icono, label, color, onTap, con feedback háptico).
2. Crear `features/matches/presentation/widgets/action_grid.dart` (organiza los 9 botones en 3 secciones de 3 columnas).
3. Crear `features/matches/presentation/widgets/annotation_stepper.dart` (indicador visual del paso 1-2-3).
4. Implementar feedback háptico (vibración 15ms) al pulsar cualquier acción.
**Resultado:** Grid de acciones interactivo con indicador del flujo de anotación.

---

### T-020: Implementar pantalla de Anotación — Selector de Jugador
**Objetivo:** Crear el carrusel de selección de jugador (roster en pista).
**Referencia visual:** `docs/images/anotation_screen.png`
**Diseño a implementar (parte inferior):**
- **Sección "JUGADOR"** (label centrado):
  - Carrusel horizontal con flechas "<" y ">" en los extremos.
  - Cada jugador: círculo con su dorsal (#4, #7, #11, #23, #32).
  - Jugador seleccionado: círculo naranja sólido con número blanco + nombre debajo.
  - Jugadores no seleccionados: círculo con borde gris + número gris + nombre debajo (más tenue).
- **Barra inferior fija:**
  - Izquierda: icono grupo + "EQUIPO TIGRES ▾" (dropdown para cambiar equipo anotando).
  - Derecha: icono undo + "DESHACER ÚLTIMA ACCIÓN" (naranja, botón de emergencia).
**Acciones:**
1. Crear `features/matches/presentation/widgets/player_carousel.dart` (scroll horizontal con selección).
2. Crear `features/matches/presentation/widgets/player_chip.dart` (círculo con dorsal).
3. Crear `features/matches/presentation/widgets/annotation_bottom_bar.dart` (equipo + undo).
4. Crear `features/matches/presentation/providers/annotation_state_provider.dart`:
   - Estado: `selectedAction`, `selectedPlayer`, `currentStep` (1, 2, 3).
   - Lógica: al seleccionar acción → paso 2. Al seleccionar jugador → si acción requiere coordenadas → paso 3, si no → registrar evento.
   - Al registrar: persiste en Drift + envía POST + optimistic UI + haptic feedback.
   - Undo: llama endpoint de compensación.
**Resultado:** Flujo completo de anotación en ≤ 3 taps funcional end-to-end.

---

### T-021: Implementar tab de Historial en Court View
**Objetivo:** Crear la segunda tab "HISTORIAL" de la pantalla de anotación.
**Acciones:**
1. Reutilizar `play_by_play_feed.dart` de la pantalla de retransmisión (T-017).
2. Mostrar los eventos registrados en el partido actual en orden cronológico inverso (más reciente arriba).
3. Permitir swipe-to-undo en eventos recientes (últimos 30 segundos) con confirmación.
4. Indicar eventos `pending` (sin sincronizar) con un icono de reloj/nube.
5. Indicar eventos `failed` con icono de advertencia y opción de reintentar.
**Resultado:** El anotador puede ver el historial y corregir errores recientes.

---

## Fase 7 — Feature: Listado de Partidos

### T-022: Implementar pantalla de selección de partido (para anotar y para ver)
**Objetivo:** Pantalla intermedia entre Home y Court View / Live que lista los partidos disponibles.
**Acciones:**
1. Crear `features/matches/presentation/pages/match_list_page.dart`:
   - Recibe un `mode` param: `annotate` o `spectate`.
   - Lista partidos del club del usuario (paginados).
   - Para modo `annotate`: mostrar partidos con status `scheduled` o `inProgress` asignados al usuario.
   - Para modo `spectate`: mostrar partidos con status `inProgress` (en directo).
2. Cada card de partido muestra: equipos, fecha/hora, estado (badge), competición.
3. Al tocar un partido → navegar a Court View (si annotate) o Match Live (si spectate).
4. Pull-to-refresh + paginación infinite scroll.
**Resultado:** El usuario puede seleccionar a qué partido entrar.

---

## Fase 8 — Features Secundarias

### T-023: Implementar feature Teams/Players (listados básicos)
**Objetivo:** Pantallas de administración básica de equipos y jugadores.
**Acciones:**
1. Crear domain + data layer para Teams (`GET /teams?clubId=X`).
2. Crear domain + data layer para Players (`GET /players?teamId=X`).
3. Crear pantalla de lista de equipos con navegación a jugadores.
4. Crear pantalla de lista de jugadores (dorsal, nombre, posición, foto).
5. Conectar con la card "Administrar mi equipo" del menú principal.
**Resultado:** Navegación funcional Club → Equipos → Jugadores.

---

### T-024: Implementar feature Settings (perfil y preferencias)
**Objetivo:** Pantalla de configuración del usuario.
**Acciones:**
1. Crear `features/settings/presentation/pages/settings_page.dart`:
   - Foto de perfil + nombre + email + rol.
   - Toggle de notificaciones.
   - Selector de idioma (scaffold para i18n futuro).
   - Versión de la app.
   - Botón "Cerrar sesión" (limpia tokens, navega a login).
2. Conectar con el "Tu perfil" del header del menú principal.
**Resultado:** El usuario puede ver su perfil y cerrar sesión.

---

## Fase 9 — Observabilidad y Polish

### T-025: Integrar Sentry y logging estructurado
**Objetivo:** Configurar crash reporting y logging (§4 Agent_Mobile.md — Observabilidad).
**Acciones:**
1. Inicializar Sentry en `main.dart` con DSN desde `EnvConfig` (solo staging/prod).
2. Configurar `FlutterError.onError` y `PlatformDispatcher.instance.onError` para capturar crashes.
3. Crear `lib/core/logging/app_logger.dart` que use `logger` y opcionalmente envíe breadcrumbs a Sentry.
4. Añadir logging en puntos clave: login success/fail, event recorded, WS connect/disconnect, sync completed.
**Resultado:** Crash reporting funcional en staging/prod con contexto suficiente para debug.

---

### T-026: Implementar indicadores de conexión y sincronización globales
**Objetivo:** Widgets globales que muestran el estado del sistema.
**Acciones:**
1. Crear `lib/core/widgets/connection_indicator.dart` — punto verde/amarillo/rojo en la barra superior de pantallas de partido.
2. Crear `lib/core/widgets/sync_badge.dart` — badge con número de eventos pendientes.
3. Integrar ambos en `court_view_page.dart` y `match_live_page.dart`.
4. Mostrar SnackBar naranja automático cuando se pierde conexión: "Sin conexión — eventos guardados localmente".
**Resultado:** El usuario siempre sabe el estado de su conexión y sincronización.

---

## Fase 10 — Testing y CI

### T-027: Implementar unit tests del core y domain
**Objetivo:** Cobertura ≥ 80% en domain + core (§14 Agent_Mobile.md).
**Acciones:**
1. Tests para `AuthInterceptor` (inyección de token, refresh on 401, race condition).
2. Tests para `RetryInterceptor` (retry en 5xx, no retry en 4xx).
3. Tests para `SyncService` (procesa cola FIFO, maneja errores 4xx vs 5xx).
4. Tests para `ErrorMapper` (parsea formato de error del backend).
5. Tests para todos los UseCases (mock del repository con mocktail).
6. Tests para modelos Freezed (serialización/deserialización JSON).
**Resultado:** Suite de unit tests que valida la lógica core sin dependencias externas.

---

### T-028: Implementar widget tests de pantallas críticas
**Objetivo:** Validar la UI del Court View y Login.
**Acciones:**
1. Widget test de `LoginPage`: renderiza campos, valida inputs vacíos, muestra error en credenciales inválidas.
2. Widget test de `CourtViewPage`: renderiza grid de acciones, seleccionar acción cambia paso, seleccionar jugador dispara evento.
3. Widget test de `MatchLivePage`: renderiza score header, feed se actualiza al recibir evento en stream mock.
4. Widget test de `MainMenuPage`: cards correctas según rol del usuario.
**Resultado:** Tests de UI que previenen regresiones en pantallas críticas.

---

### T-029: Configurar pipeline CI (GitHub Actions)
**Objetivo:** Pipeline automatizado de calidad (§15 Agent_Mobile.md).
**Acciones:**
1. Crear `.github/workflows/ci.yml`:
   - Trigger: push a `main`, PRs.
   - Steps: checkout → setup Flutter → `dart analyze --fatal-infos` → `dart format --set-exit-if-changed .` → `flutter test --coverage` → verificar cobertura ≥ 70% → `flutter build apk --release`.
2. Crear `.github/workflows/release.yml`:
   - Trigger: tags `v*`.
   - Steps: build APK/AAB → upload a Firebase App Distribution (staging) o artifact.
**Resultado:** Cada PR se valida automáticamente; releases se distribuyen via CI.

---

## Fase 11 — State Restoration y Final Polish

### T-030: Implementar state restoration de partido en progreso
**Objetivo:** Persistir estado del partido para recuperación tras kill del SO (§17 Agent_Mobile.md).
**Acciones:**
1. En `annotation_state_provider.dart`: cada vez que se registra un evento o cambia el período/reloj, persistir snapshot en `match_cache` (Drift).
2. Al iniciar la app: verificar si existe un `match_cache` con partido no finalizado.
3. Si existe: mostrar diálogo "Tienes un partido en curso. ¿Retomar?" → navegar a CourtView con estado restaurado.
4. Si el usuario descarta: limpiar caché (pero mantener `pending_events` para sincronizar).
**Resultado:** El anotador nunca pierde contexto de un partido aunque el SO mate la app.

---

## Resumen de Fases

| Fase | Tareas | Descripción |
|---|---|---|
| 0 | T-001 a T-003 | Scaffolding y configuración |
| 1 | T-004 a T-009 | Core infrastructure (theme, network, DB, sync) |
| 2 | T-010 a T-012 | Autenticación completa (login + routing) |
| 3 | T-013 | Menú principal |
| 4 | T-014 a T-016 | Modelos y data layer de Matches |
| 5 | T-017 | Sala de retransmisión en directo |
| 6 | T-018 a T-021 | Pantalla de anotación (la más compleja) |
| 7 | T-022 | Listado y selección de partidos |
| 8 | T-023 a T-024 | Features secundarias (teams, settings) |
| 9 | T-025 a T-026 | Observabilidad y UX polish |
| 10 | T-027 a T-029 | Testing y CI/CD |
| 11 | T-030 | State restoration |

**Total: 30 tareas / 11 fases.**

> Cada tarea es un commit atómico. Se recomienda hacer PR por fase completa.
