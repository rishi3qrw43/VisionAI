<!-- refreshed: 2026-07-15 -->
# Architecture

**Analysis Date:** 2026-07-15

## System Overview

```text
┌──────────────────────────────────────────────────────────────────┐
│                    User Interface Layer                           │
│  (SwiftUI Views: Home, Language, History, Video, Recording, etc) │
│                   `ASSIST/ContentView.swift`                     │
└────────────────────┬─────────────────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────────────────┐
│                    Application State                              │
│  AppState (ObservableObject) — Central source of truth            │
│  Routes screens, stores user data, manages AI results             │
│                   `ASSIST/ContentView.swift`                     │
└────────────────────┬─────────────────────────────────────────────┘
         │                    │                       │
         ▼                    ▼                       ▼
┌─────────────────┐  ┌──────────────────┐   ┌──────────────────┐
│ Camera Manager  │  │   AI Pipeline    │   │ Localization     │
│ AVCapture       │  │ (FoundationModels│   │ (Multi-language) │
│ Session         │  │  + Vision)       │   │ 5 languages      │
│ `ASSIST/        │  │ `ASSIST/         │   │ `ASSIST/         │
│ ContentView`    │  │ ContentView.swift│   │ ContentView.swift│
└─────────────────┘  └──────────────────┘   └──────────────────┘
         │                    │
         └────────┬───────────┘
                  ▼
         ┌─────────────────────┐
         │ System Frameworks   │
         │ • AVFoundation      │
         │ • Vision            │
         │ • FoundationModels  │
         │ • SwiftUI           │
         └─────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `ASSISTApp` | Application entry point; creates WindowGroup with ContentView | `ASSIST/ASSISTApp.swift` |
| `AppState` | Central observable state; manages screen routing, history, AI results, user settings | `ASSIST/ContentView.swift` (lines 160–366) |
| `CameraManager` | Manages AVCaptureSession; handles photo capture and video recording with delegate pattern | `ASSIST/ContentView.swift` (lines 383–599) |
| `ContentView` | Root SwiftUI container; instantiates AppState and CameraManager; switches between screen views | `ASSIST/ContentView.swift` (lines 623–655) |
| Screen Views | Individual view implementations (LoginView, HomeView, LanguageView, etc.) | `ASSIST/ContentView.swift` |
| `LocalizedStrings` / `translations` | Multi-language string management for 5 languages (EN, ES, ZH, FR, AR) | `ASSIST/ContentView.swift` (lines 49–135) |

## Pattern Overview

**Overall:** State-driven MVC variant with centralized observable state.

**Key Characteristics:**
- Single-file monolithic architecture — all models, state, and views in `ContentView.swift`
- State-driven navigation via `AppScreen` enum — `ContentView.body` switches on `state.screen`
- Push-model reactivity — SwiftUI observes `@Published` properties in `AppState`
- On-device AI only — `FoundationModels` (text) + `Vision` (image classification) with no external API calls
- Delegate pattern for camera I/O — `AVCapturePhotoCaptureDelegate`, `AVCaptureFileOutputRecordingDelegate` manage async callbacks

## Layers

**Presentation Layer (Views):**
- Purpose: Render UI and collect user input
- Location: `ASSIST/ContentView.swift` (lines 658–1263)
- Contains: SwiftUI View structs (LoginView, HomeView, LanguageView, HistoryView, VideoView, RecordingView, MenuView, etc.)
- Depends on: `AppState` (data + behavior), `CameraManager` (capture)
- Used by: `ContentView` (root)
- Pattern: Each view is a SwiftUI struct that reads/writes to `@ObservedObject state`

**State Layer:**
- Purpose: Centralized application state and business logic
- Location: `ASSIST/ContentView.swift` (lines 160–366)
- Contains: `AppState` ObservableObject with `@Published` properties for screen, user, history, AI results, settings
- Depends on: `FoundationModels`, `Vision`, `AppLanguage`, `LocalizedStrings`
- Used by: All presentation views
- Key responsibilities:
  - Screen routing via `@Published var screen: AppScreen`
  - Scan analysis pipeline: `analyzeScan(imageURL:)` calls Vision classifier, then FoundationModels for description
  - Video chat session management: `sendMessage()`, `generateVideoResponse()`
  - History management: `deleteItem()`, `restoreItem()`, `permanentlyDelete()`

**Infrastructure Layer:**
- Purpose: Manage low-level hardware I/O (camera, file storage)
- Location: `ASSIST/ContentView.swift` (lines 383–599)
- Contains: `CameraManager` class wrapping `AVCaptureSession`, photo/video delegates
- Depends on: `AVFoundation`, file system (Documents directory)
- Used by: `HomeView`, `RecordingView`
- Pattern: Reference-type `class` to maintain AVFoundation delegate lifecycle

**AI/ML Layer:**
- Purpose: On-device image classification and text generation
- Frameworks: `Vision`, `FoundationModels`
- Entry points:
  - Image classification: `ClassifyImageRequest()` in `analyzeScan()`
  - Text generation: `LanguageModelSession` in `generateVideoResponse()` and `startVideoConversation()`
- No external dependencies — all processing happens on-device

**Localization Layer:**
- Purpose: Multi-language support (5 languages: EN, ES, ZH, FR, AR)
- Location: `ASSIST/ContentView.swift` (lines 9–135)
- Enum `AppLanguage` with `isRTL` property for Arabic RTL layout
- `LocalizedStrings` struct + `translations` dictionary for all UI text
- Views access strings via `state.text.<property>` (e.g., `state.text.scanHint`)

## Data Flow

### Primary Scan-to-AI Flow

1. **User taps camera button** → `capturePhoto()` in `HomeView` (line 1118)
2. **Photo captured** → `CameraManager.capturePhoto(completion:)` triggers `PhotoCaptureDelegate.photoOutput(_:didFinishProcessingPhoto:error:)` (line 551), writes JPEG to temp directory
3. **Photo saved to history** → `HomeView` inserts `HistoryItem` into `AppState.historyItems` with "Analyzing…" status (line 1125)
4. **Vision classification** → `AppState.analyzeScan(imageURL:)` calls `ClassifyImageRequest().perform(on:imageURL)` to extract labels (line 240)
5. **LLM description** → `LanguageModelSession(instructions:)` generates multilingual description with Vision context (line 266)
6. **UI updates** → `AppState` updates `@Published` properties: `lastScanTitle`, `lastScanDescription`, `lastScanQuestion` (lines 285–286)
7. **UI redraws** → SwiftUI observes state change; `HomeView` displays new AI result in card (lines 1022–1068)

**State Management:**
```
Photo captured
    ↓
AppState.lastCapturedImageURL ← CameraManager.lastCapturedImageURL
    ↓
AppState.isAnalyzing = true
    ↓
Vision.ClassifyImageRequest → topLabels
    ↓
FoundationModels.LanguageModelSession → response.content
    ↓
AppState.lastScanTitle = title
AppState.lastScanDescription = description
AppState.isAnalyzing = false
    ↓
SwiftUI re-renders HomeView with new state
```

### Video Recording & Chat Flow

1. **User long-presses capture button** → `HomeView.onLongPressGesture()` (line 1090)
2. **Recording starts** → `state.screen = .recording` triggers `RecordingView`
3. **Video recorded** → `CameraManager.startRecording(maxDuration:)` writes .mov to Documents directory (line 458)
4. **Recording stops** → `stopRecordingAndSend()` (line 332) calls `startVideoConversation()`
5. **Initial AI greeting** → `LanguageModelSession.respond()` generates greeting about recorded video (line 348)
6. **User sends chat message** → `AppState.sendMessage()` appends message to `@Published var messages` (line 310)
7. **LLM responds** → `generateVideoResponse(for:)` calls `videoChatSession!.respond(to:)` (line 325)
8. **Chat updates** → Messages array mutates; `VideoView` re-renders chat list

**State Management:**
```
Long press → state.isRecording = true, screen = .recording
    ↓
Video saved to Documents
    ↓
state.screen = .video
    ↓
FoundationModels.LanguageModelSession.respond() → greeting
    ↓
state.messages.append(ChatMessage(role: "ai", text: greeting))
    ↓
User types → state.chatInput mutated
    ↓
sendMessage() → append(ChatMessage(role: "user", text: ...))
    ↓
generateVideoResponse() → LanguageModelSession continues conversation
    ↓
state.messages.append(ChatMessage(role: "ai", text: ...))
```

### Screen Navigation

All navigation is state-driven via `AppScreen` enum:
- `ContentView.body` switches on `state.screen` (line 630)
- Views update `state.screen` to navigate:
  - Login → Home: `state.screen = .home` (line 742)
  - Home → Language: `state.screen = .language` (line 964)
  - Home → Recording: `state.screen = .recording` (line 1094)
  - Any → Home: `state.screen = .home` (line 1172)
  - Any → Menu: `state.screen = .menu` (line 826)

## Key Abstractions

**AppScreen Enum:**
- Purpose: Single source of truth for navigation state
- Values: `.login`, `.home`, `.language`, `.history`, `.video`, `.menu`, `.recording`, `.historyDetail(Int)`, `.accessibility`, `.notifications`, `.about`, `.videoSettings`
- Pattern: ContentView switches on this value; each case displays a different screen
- Example: `case .historyDetail(let id): HistoryDetailView(state: state, itemId: id)` (line 638)

**AppLanguage Enum:**
- Purpose: Represent supported languages and metadata
- Cases: `.english`, `.spanish`, `.chinese`, `.french`, `.arabic`
- Key property: `isRTL` — returns `true` for Arabic to signal RTL layout
- Used by: Views that need language metadata; `LocalizedStrings` lookup in `translations` dict

**HistoryItem Struct:**
- Purpose: Represent a saved scan or video in the history
- Fields: `id`, `type` ("scan" or "video"), `imageURL`, `desc`, `time`, `date`, `deleted`, `previewURL`
- Stored in: `AppState.historyItems` array
- Behavior: Marked deleted (soft delete) or permanently deleted; UI filters by `deleted` status

**CameraManager Class:**
- Purpose: Wrap `AVCaptureSession` with photo + video recording
- Pattern: Reference type for delegate management; delegate instances held in `photoCaptureDelegates`, `movieRecordingDelegates` arrays
- Lifecycle: `setup()` is called by `ContentView.onAppear` (line 654) to configure session and request camera permissions
- Key methods: `capturePhoto(completion:)`, `startRecording()`, `stopRecording(completion:)`, `setVideoQuality(_:)`

## Entry Points

**Application Entry Point:**
- Location: `ASSIST/ASSISTApp.swift`
- Structure: `@main` struct `SMFR2App` (name mismatch — old name not updated)
- Responsibility: Creates `WindowGroup { ContentView() }` to launch the app

**View Entry Point:**
- Location: `ASSIST/ContentView.swift` line 623
- Structure: `struct ContentView: View` instantiates `@StateObject private var state = AppState()` and `@StateObject private var camera = CameraManager()`
- Responsibility: Root SwiftUI container; calls `camera.setup()` on appear; renders current screen based on `state.screen`

**Functional Entry Points:**
- **Photo scan pipeline**: `HomeView.capturePhoto()` → `CameraManager.capturePhoto(completion:)` → `AppState.analyzeScan(imageURL:)`
- **Video recording**: Long press in `HomeView` → `RecordingView` → `CameraManager.startRecording()` → `AppState.stopRecordingAndSend()`
- **Video chat**: `AppState.sendMessage()` → `generateVideoResponse(for:)` → `LanguageModelSession.respond(to:)`

## Architectural Constraints

- **Single-file constraint:** All code in `ASSIST/ContentView.swift` (1266 lines) — no separation into multiple modules. This limits testability and code organization but keeps the codebase simple and visible.

- **On-device AI only:** Framework imports are restricted to Apple-provided SDKs: `SwiftUI`, `AVFoundation`, `AVKit`, `Vision`, `FoundationModels`, `Combine`, `UIKit`. No third-party dependencies allowed. This ensures privacy and reduces app size, but limits LLM capabilities to on-device models.

- **Reference semantics for CameraManager:** Must remain a `class` to maintain AVFoundation delegate lifecycle. The delegate callbacks (e.g., `photoOutput(_:didFinishProcessingPhoto:error:)`) require stable references that structs cannot provide.

- **Observable state pattern:** `AppState` is the only `ObservableObject`; all views read from it via `@ObservedObject`. This creates a single point of mutation — any state change triggers observation and view redraws. This is simple but can cause over-rendering.

- **RTL support for Arabic:** Views that render text or layout dynamically must check `state.currentLanguage.isRTL` or use SwiftUI's automatic RTL support. Example: Language picker buttons, menu items, and text-heavy cards.

- **Synchronous file I/O:** Photo and video files are written to Documents directory directly via `FileManager`. No queuing or async file operations — thumbnail generation blocks on `DispatchSemaphore.wait()` (line 524).

- **No external networking:** The Vision and FoundationModels frameworks are offline-first. If either fails, the app gracefully degrades with fallback text.

## Anti-Patterns

### Monolithic View File

**What happens:** All 1266 lines of code (models, state, views, infrastructure) are in a single `ContentView.swift` file.

**Why it's wrong:** 
- Difficult to navigate and edit — single file bloats quickly
- No clear separation of concerns — business logic mixed with UI
- Hard to test — views and state are tightly coupled and cannot be unit tested independently
- Reusability suffers — components cannot be extracted and reused elsewhere

**Do this instead:** Split into multiple files:
- `ASSIST/Models/AppState.swift` — `AppState` class
- `ASSIST/Models/CameraManager.swift` — `CameraManager` class
- `ASSIST/Localization/LocalizedStrings.swift` — `LocalizedStrings` + `translations` dict
- `ASSIST/Views/ContentView.swift` — Root view container only
- `ASSIST/Views/HomeView.swift` — Home screen
- `ASSIST/Views/LoginView.swift` — Login screen
- etc.

### Soft Deletes Without Cleanup

**What happens:** History items are marked `deleted = true` but remain in `historyItems` array indefinitely (line 217). Users never see them, but they take memory and persist across sessions.

**Why it's wrong:**
- Array grows unbounded with deleted items
- No way to permanently clean up without manual deletion
- Soft deletes only make sense if there's a "trash" recovery feature, but deleted items aren't backed up or recoverable

**Do this instead:** 
- Implement proper trash management: recover deleted items for 30 days, then auto-purge
- Or: Make `permanentlyDelete()` the only delete operation; update UI to confirm destruction
- Or: Add a "Clear Trash" button in settings that purges items marked deleted after N days

### Unbound State Mutations in Views

**What happens:** Views directly mutate `@ObservedObject state` properties:
```swift
state.screen = .language  // Direct mutation
state.historyItems[idx].desc = title  // Array mutation
chatInput = ""  // Local state
```

**Why it's wrong:**
- No transaction boundary — mutations can happen in any order, leaving inconsistent state
- Hard to debug — unclear which view caused a state change
- No undo/redo possible — each mutation is immediate and permanent

**Do this instead:**
- Add action methods to `AppState` that encapsulate mutations:
  ```swift
  func navigateTo(_ screen: AppScreen) { self.screen = screen }
  func updateHistoryItem(_ id: Int, desc: String) { ... }
  ```
- Views call these methods instead of mutating directly: `state.navigateTo(.language)`
- This creates a clear audit trail and makes testing easier

### Blocking Semaphore in Main Thread

**What happens:** Thumbnail generation uses `DispatchSemaphore.wait()` on the main thread (line 524):
```swift
semaphore.wait()  // Blocks until image generation completes
```
This is inside `handleRecordingFinished()` which runs on `DispatchQueue.main.async` (line 494).

**Why it's wrong:**
- Blocks the main thread while waiting for async image generation
- Can cause UI freezes if image is large
- Poor UX during video recording finish

**Do this instead:**
- Use async/await to wait for thumbnail generation without blocking:
  ```swift
  let thumbURL = await generateThumbnailAsync(for: url)
  ```
- Or: Post thumbnail generation as a background task and update UI when done via callback

### Unused View Stubs

**What happens:** Many screens are defined as empty stub views (lines 1216–1263):
```swift
struct HistoryView: View {
    @ObservedObject var state: AppState
    var body: some View { Text("HistoryView") }
}
```

**Why it's wrong:**
- Dead code clutters the file
- Unclear which screens are implemented vs. planned
- No clear path to implement missing functionality

**Do this instead:**
- Move stubs to a separate `Stubs.swift` file
- Document which screens are TODO and prioritize them
- Or: Remove completely and add back only when needed

## Error Handling

**Strategy:** Graceful degradation with silent fallbacks.

**Patterns:**
- Vision classification failure → Continue with generic "an object" context (line 251)
- LLM description generation failure → Show Vision-only results (lines 292–302)
- Video chat error → Show user-friendly message "I couldn't process that. Please try again." (line 328)
- Recording failure → Delegate's error handler logs and calls `parent?.handleRecordingFinished(nil)` (line 585)

**No custom error types or propagation** — errors are caught and handled at the point of failure with fallback behavior.

## Cross-Cutting Concerns

**Logging:** None — no logging framework. Debug messages would use `print()` but don't appear in current code.

**Validation:** Minimal — chat input validated for empty string (line 309); email/password validation in LoginView is client-side only (line 739).

**Authentication:** Mockable in LoginView (lines 735–766) — no real auth backend. User email stored in `state.userEmail`; no session token or credential management.

**Accessibility:** 
- `fontSizeMultiplier` property in AppState (line 195) — not currently used in UI
- `highContrast` property (line 196) — not implemented
- `voiceSpeed` property (line 197) — used in speech synthesis (line 1155)
- Screen reader support not implemented — all Text views should have accessibility labels

**Permissions:** Camera and microphone are requested at runtime via `AVCaptureDevice.requestAccess()` (line 402). No granular permission checks beyond initial setup.

---

*Architecture analysis: 2026-07-15*
