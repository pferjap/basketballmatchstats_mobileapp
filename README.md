# 🏀 HoopAnalytics Mobile

Flutter client for the HoopAnalytics SaaS platform — real-time basketball match annotation, live scoring, and statistical analysis.

## Overview

This app serves two primary user flows:

- **Statistician (Annotator):** Ultra-fast event recording during live matches (≤ 3 taps per event, < 100ms latency, haptic feedback).
- **Spectator/Coach:** Real-time play-by-play feed, live scoreboard, and box scores via WebSocket.

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

## Architecture

Clean Architecture by feature with 3 layers per module:

```
lib/
├── core/          # Network, theme, error handling, database, config
├── features/
│   ├── auth/      # JWT login + refresh token flow
│   ├── matches/   # Core engine: annotation + live score
│   ├── clubs/     # Club management
│   ├── teams/     # Team management
│   ├── players/   # Player roster
│   └── ...
├── app.dart
└── main.dart
```

Each feature follows: `data/ → domain/ → presentation/`

## Key Design Decisions

- **Offline-first annotation:** Events are always persisted locally (Drift) before sending to API. A SyncService processes the queue when connectivity returns.
- **Optimistic UI:** UI updates immediately on tap; rolls back on server rejection (4xx).
- **WebSocket is read-only:** All mutations go through REST; WS only broadcasts updates to spectators.
- **Reconnection with reconciliation:** On WS reconnect, fetch missed events via REST and sync state.
- **Multi-tenant isolation:** JWT contains clubId/roles; client enforces role-based UI visibility and route guards.

## Environments

| Env | Entry Point | Base URL |
|---|---|---|
| dev | `main_dev.dart` | `http://localhost:3000/api/v1` |
| staging | `main_staging.dart` | `https://staging-api.hoopanalytics.com/api/v1` |
| prod | `main_prod.dart` | `https://api.hoopanalytics.com/api/v1` |

## Getting Started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run                  # dev environment (default)
```

## Documentation

- [Agent_Mobile.md](docs/agents/Agent_Mobile.md) — Full architecture spec and coding rules
- [Plan.md](docs/tasks/Plan.md) — Implementation task breakdown (30 tasks / 11 phases)
- [API Reference](docs/agents/api/Agent_api.md) — Backend API spec (source of truth)

## Backend

This app consumes the HoopAnalytics NestJS API (PostgreSQL/Supabase). The API is the single source of truth for all data.
