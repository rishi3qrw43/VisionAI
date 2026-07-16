# ASSIST — Visual AI

## Why this exists
An iOS accessibility and translation tool. Users point their camera at objects to get AI descriptions in their language, and can record videos to ask follow-up questions via an on-device AI chat.

## Stack
- Swift + SwiftUI, iOS 17+ (requires `FoundationModels` and `Vision`)
- On-device AI only: `FoundationModels` (text generation) + `Vision` (`ClassifyImageRequest`) — no network LLM calls
- `AVFoundation` / `AVKit` for camera, photo capture, and video recording with audio
- No external SPM dependencies

## Codebase map
All code is in `ASSIST/ContentView.swift` — one file containing all models, state, and views:

| Symbol | Role |
|---|---|
| `AppState` | Central `ObservableObject`; owns screen routing, history, AI results, and settings |
| `CameraManager` | `AVCaptureSession` wrapper for photo capture and video recording |
| `AppScreen` | Enum driving all navigation — `ContentView.body` switches on it |
| `LocalizedStrings` / `translations` | 5-language localization: EN, ES, ZH, FR, AR |
| `AppLanguage.isRTL` | Arabic requires RTL layout — check this when adding UI for new screens |

## How to build and validate
Uses the `xcodebuildmcp` MCP server (project + scheme + simulator set via `session_set_defaults`).
- **Build only**: `build_sim` (compile-only, no launch)
- **Build + install + launch**: `build_run_sim`
- **Inspect build settings**: `show_build_settings`
- **Schemes**: `list_schemes`

## Hard constraints
- Never introduce network-based LLM calls — `FoundationModels` is on-device by design
- `CameraManager` must remain a `class` — AVFoundation delegate pattern requires reference semantics
- Arabic is RTL; any new UI touching text layout must respect `AppLanguage.isRTL`
