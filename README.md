# 🏀 HoopAnalytics Mobile

Flutter client for the HoopAnalytics SaaS platform — real-time basketball match annotation, live scoring, and statistical analysis.

## Overview

This app serves two primary user flows:

- **Statistician (Annotator):** Ultra-fast event recording during live matches (≤ 3 taps per event, < 100ms latency, haptic feedback, interactive shot chart with normalized X/Y coordinates).
- **Spectator/Coach:** Real-time play-by-play feed, live scoreboard (`MatchScore`), and per-player box scores (`PlayerMatchStats`) via WebSocket.

The backend NestJS API (PostgreSQL/Supabase) is the single source of truth; the client mirrors its DTOs and enums exactly.

## Performance Targets

| Metric | Target |
|---|---|
| End-to-end latency (tap → event persisted) | `< 100ms` |
| Taps to record a complex event | `≤ 3` |
| Live stats read (`MatchScore`) | `< 100ms` |
| WebSocket reconnect after drop | `< 5s` (first retry) |
| App cold start | `< 2s` |

## Core Features

- Secure authentication and session management (JWT + refresh token).
- Club hierarchy browsing (Club → Teams → Players).
- Match management (schedule, start, pause between quarters, finish).
- Play-by-play event recording (≤ 3 taps) with Optimistic UI.
- Live match tracking over WebSockets (room `match:{matchId}`).
- Historical results and box scores.
- User registration and role/privilege management.
- *(Deferred: deep BI/AI analytics module — feature scaffold exists.)*

## Key Development Principles

- **The 3-Tap Rule:** Any complex event (e.g. "3-pointer made by Player 5 from the right corner") is recorded in ≤ 3 interactions.
- **Strict separation of concerns:** No business logic, HTTP, or data transformation inside widgets — widgets only read state and dispatch intents.
- **Optimistic UI by default:** UI updates immediately on tap; on server rejection (4xx) it rolls back and shows the backend error (`errors[0].message`).
- **Offline-first annotation:** The annotator never loses an event due to poor connectivity.
- **Mobile security:** Tokens in secure storage; no sensitive authorization logic exposed on the client.

See [Agent_Mobile.md](docs/agents/Agent_Mobile.md) §2–§3 for the full product vision and principles.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (latest stable) |
| State Management | Riverpod v2+ |
| Networking | Dio (REST) + socket_io_client (WebSocket) |
| Navigation | go_router |
| Models | Freezed + json_serializable |
| Local DB (offline) | Drift (SQLite) |
| Secure Storage | flutter_secure_storage |
| Crash Reporting | Sentry |

## Project Structure

Clean Architecture organized by feature, with three layers per module (`data/ → domain/ → presentation/`):

```
lib/
├── core/                # Cross-cutting concerns
│   ├── config/          # Environment config and feature flags
│   ├── network/         # Dio client, interceptors, WebSocket manager, connectivity
│   ├── error/           # Failures and error mapping
│   ├── database/        # Drift (SQLite) setup and DAOs
│   ├── theme/           # Colors, typography, UI constants (48dp touch targets)
│   ├── l10n/            # Internationalization (ARB files)
│   └── widgets/         # Shared reusable widgets
├── features/
│   ├── auth/            # JWT login + refresh token flow
│   ├── clubs/           # Club management
│   ├── teams/           # Team management
│   ├── players/         # Player roster
│   ├── competitions/    # Leagues, tournaments, phases
│   ├── seasons/         # Sport seasons
│   ├── matches/         # Core engine: annotation (Court View) + live score
│   ├── statistics/      # MatchScore / PlayerMatchStats consumption
│   ├── settings/        # Profile and preferences
│   └── analytics/       # (Scaffold) future BI/AI module
├── app.dart             # MaterialApp wrapped in ProviderScope
└── main.dart            # Entry point with environment initialization
```

Each feature keeps the same internal layout: `data/{models,datasources,repositories}`, `domain/{entities,repositories,usecases}`, and `presentation/{pages,widgets,providers}`. See [Agent_Mobile.md](docs/agents/Agent_Mobile.md) §5 for the full tree.

## Key Design Decisions

- **Offline-first annotation:** Events are always persisted locally (Drift) before sending to API. A SyncService processes the queue when connectivity returns.
- **Optimistic UI:** UI updates immediately on tap; rolls back on server rejection (4xx).
- **WebSocket is read-only:** All mutations go through REST; WS only broadcasts updates to spectators.
- **Reconnection with reconciliation:** On WS reconnect, fetch missed events via REST and sync state.
- **Multi-tenant isolation:** JWT contains clubId/roles; client enforces role-based UI visibility and route guards.

## Client–Server Communication

- **REST (mutations):** Every mutation is an HTTP request to the NestJS backend via Dio (`AuthInterceptor` → `RetryInterceptor`). The client never persists data through the WebSocket.
- **WebSocket (read-only channel):** Authenticated on handshake (`auth.token = JWT`), joins room `match:{matchId}`, and listens to `event.created`, `score.updated`, and `match.updated` streams that drive Riverpod `StreamProvider`s.
- **Resilience:** WS reconnects with exponential backoff + jitter (1s → 30s cap); HTTP retries only idempotent/transient statuses (408, 429, 5xx). Business errors (4xx) are never retried.
- **Reconciliation:** After a reconnect, the client fetches missed events (`GET /matches/:id/events?since=...`) and re-syncs `MatchScore` before merging into local state.

See [Agent_Mobile.md](docs/agents/Agent_Mobile.md) §7–§9 for endpoints, WS contract, and the auth/refresh flow.

## Offline-First Strategy

The annotator often works in venues with poor or no connectivity, so no recorded event is ever lost:

1. Each event is **always** persisted to a Drift (`pending_events`) queue as `pending`.
2. If online, it is sent immediately via `POST /events`; on 2xx it is marked `synced`.
3. If offline or the request fails, it stays `pending` and is retried when the network returns.
4. On reconnect, a `SyncService` drains the queue in FIFO order (by `created_at`), preserving chronological order.
5. On a 4xx business error, the event is marked `failed` and surfaced to the annotator to correct or discard.

A discreet badge shows the number of pending (and any failed) events. See [Agent_Mobile.md](docs/agents/Agent_Mobile.md) §10 and §17 for the sync flow and state restoration.

## Roles & Multitenancy

Roles mirror the backend and are decoded from the JWT; the client hides actions and guards routes accordingly, and never allows access to another club's resources.

| Role | Permissions in the app |
|---|---|
| `SUPER_ADMIN` | Full access; manage all clubs |
| `CLUB_ADMIN` | Full management of own club: teams, players, matches |
| `COACH` | View assigned teams, matches and stats; cannot annotate |
| `STATISTICIAN` | Annotate assigned matches (Court View); view stats |
| `VIEWER` | Read-only: live matches, historical results |

## Environments

| Env | Entry Point | Base URL |
|---|---|---|
| dev | `main_dev.dart` | `http://localhost:3000/api/v1` |
| staging | `main_staging.dart` | `https://staging-api.hoopanalytics.com/api/v1` |
| prod | `main_prod.dart` | `https://api.hoopanalytics.com/api/v1` |

## Installation & Running

### Prerequisites

- Flutter SDK (latest stable) and Dart in strict mode.
- A running instance of the HoopAnalytics NestJS backend (defaults to `http://localhost:3000/api/v1` for `dev`).
- Android Studio / Xcode for the target platform emulators or devices.

### Setup

```bash
flutter pub get                                             # install dependencies
dart run build_runner build --delete-conflicting-outputs    # generate Freezed/Riverpod/Drift/JSON code
```

### Run

The app uses per-environment entry points (flavors):

```bash
flutter run                                 # dev (default)
flutter run -t lib/main_staging.dart        # staging
flutter run -t lib/main_prod.dart           # prod
```

### Test & build

```bash
flutter test --coverage                     # run the test suite
flutter build apk --release                 # Android release build
flutter build ios --release                 # iOS release build
```

## Testing & CI/CD

- **Test pyramid:** unit (`flutter_test` + `mocktail`, ≥ 80% on domain/data), widget tests for critical screens (Court View, forms, `AsyncValue` states), `integration_test` for E2E flows, and golden tests for visual regressions.
- **CI (GitHub Actions):** `dart analyze --fatal-infos` → `dart format --set-exit-if-changed` → `flutter test --coverage` (≥ 70% threshold) → release builds. Releases distribute via Firebase App Distribution / TestFlight + Play Console.
- **Conventions:** Conventional Commits and semantic versioning in `pubspec.yaml` (`X.Y.Z+build`).

See [Agent_Mobile.md](docs/agents/Agent_Mobile.md) §14–§15 for the full testing and CI/CD strategy.

## Implementation Roadmap

Implementation is broken into sequential, commit-sized tasks (`T-001` … `T-046`) across phases. Full detail per task lives in [Plan.md](docs/tasks/Plan.md).

| Phase | Focus |
|---|---|
| 0 | Project scaffolding, dependencies, environment flavors |
| 1 | Core infrastructure: theme, error handling, Dio, WebSocket manager, Drift, SyncService |
| 2 | Authentication (domain/data, login UI, router guards) |
| 3 | Home / main menu |
| 4 | Matches data model (models, domain, data layers) |
| 5 | Live match broadcast room |
| 6 | Court View annotation screen (layout, action panel, player selector, history) |
| 7 | Match list (annotate & spectate selection) |
| 8 | Admin panel — CRUD for clubs, teams, players, matches; settings |
| 9 | User registration and privilege management |
| 10 | Match lifecycle rules and quarter configuration |
| 11 | Observability & polish (Sentry, connection/sync indicators) |
| 12 | Testing & CI pipeline |
| 13 | State restoration and final polish |

## Documentation

- [Agent_Mobile.md](docs/agents/Agent_Mobile.md) — Full architecture spec and coding rules
- [Plan.md](docs/tasks/Plan.md) — Implementation task breakdown (phases 0–13, tasks T-001…T-046)
- [API Reference](docs/agents/api/Agent_api.md) — Backend API spec (source of truth)

## Backend

This app consumes the HoopAnalytics NestJS API (PostgreSQL/Supabase). The API is the single source of truth for all data.
