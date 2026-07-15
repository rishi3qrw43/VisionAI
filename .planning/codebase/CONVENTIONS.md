# Coding Conventions

**Analysis Date:** 2026-07-15

## Naming Patterns

**Files:**
- `ContentView.swift` — single monolithic file (1265 lines) containing all models, state, views, and supporting types
- PascalCase for struct/class/enum names (`AppState`, `CameraManager`, `LoginView`, `HistoryItem`)

**Functions:**
- camelCase: `analyzeScan()`, `sendMessage()`, `deleteItem()`, `capturePhoto()` (`ContentView.swift:216-365`)
- Async methods use `async` keyword and `await` at call sites (`analyzeScan(imageURL:)` at line 234)
- Private helper functions prefixed with `private func`: `generateVideoResponse()`, `startVideoConversation()`, `configureSession()` (lines 317-429)

**Variables:**
- camelCase for local state and computed properties: `isAnalyzing`, `lastScanTitle`, `currentLanguage`, `historyItems` (lines 161-200)
- `@Published` properties declared at class level for observable state in `AppState` (lines 160-199)
- `@State` properties in View structs for local view state: `email`, `password`, `isLoading`, `showError` (lines 662-665)
- Prefix underscore for private state properties: `_state`, `_camera` (line 624)

**Types:**
- PascalCase enums: `AppLanguage`, `AppScreen`, `HistoryTab` (lines 10-47)
- PascalCase for structs: `LocalizedStrings`, `HistoryItem`, `ChatMessage` (lines 49-156)
- Identifiable protocol implemented with `var id` property for list rendering (line 141)

## Code Style

**Formatting:**
- No external formatter configured (no .swiftformat, .prettierrc)
- Spacing: 4-space indentation (inferred from code)
- MARK comments for section organization: `// MARK: - Localization System`, `// MARK: - App State`, `// MARK: - Camera` (lines 9, 158, 381)
- Comments use two slashes with space: `// Comment` (throughout)
- Inline comments explain complex logic: "// Vision: classify what's in the photo" (line 237), "// Save directly to Documents so recordings persist" (line 457)

**Linting:**
- No linter configured (.swiftlint.yml does not exist)
- Xcode 26.6 build settings apply default Swift compiler rules

## Import Organization

**Order:**
1. Framework imports (first): `import SwiftUI`, `import AVFoundation`, `import AVKit`, `import Vision`, `import FoundationModels`, `import Combine`, `import UIKit` (lines 1-6)
2. No external SPM dependencies (CLAUDE.md constraint — on-device only, no third-party network libraries)

**No path aliases:**
- All code in single file, no module restructuring

## Error Handling

**Patterns:**
- do-catch with graceful fallback: When Vision classification fails, continue with LLM description only (lines 239-253: "// Vision failed — continue with LLM only")
- Catch errors in LLM generation and return fallback responses (lines 292-302: when `LanguageModelSession` fails, use Vision labels or generic "Scan complete")
- Video chat errors show user-friendly message: "I couldn't process that. Please try again." (line 328)
- File operations wrapped in `do-catch`: photo write to temp directory (lines 555-560), video thumbnail generation (lines 513-523)
- Delegate pattern error handling: `MovieRecordingDelegate.fileOutput()` checks error param and logs with `print()` (lines 573-592)
- No exception throwing — all errors caught and handled with state updates

## Logging

**Framework:** `print()` only
- Used minimally: "Movie recording error: \(err)" in MovieRecordingDelegate (line 584)
- No structured logging or third-party log framework

## Comments

**When to Comment:**
- Section headers using MARK comments (65+ instances throughout file)
- Explain intent when logic is non-obvious: "// Vision: classify..." (line 237), "// FoundationModels: generate..." (line 259)
- Mark temporary behaviors: "// Demo: Autofill for testing" (line 777)
- Document AVCaptureSession setup requirements: "// Add audio input so recorded movies include microphone audio" (line 418)

**JSDoc/TSDoc:**
- Not used in codebase — Swift structs/classes have no doc comments

## Function Design

**Size:**
- Moderate functions: `analyzeScan()` is 69 lines (234-302), handles Vision classification + LLM generation + state update
- Async functions use `defer` for cleanup: `MovieRecordingDelegate.fileOutput()` uses `defer` to remove self from parent list (line 574)
- Small helper functions: `questionForLanguage()` is 8 lines (357-365)

**Parameters:**
- Completion handlers: `capturePhoto(completion:)` takes `@escaping (URL?) -> Void` (line 437)
- Async/await preferred over callbacks where possible: `analyzeScan(imageURL:)` is async (line 234)
- Weak self in closures to avoid capture cycles: `[weak self]` in async blocks (lines 402, 425, 432)

**Return Values:**
- Void for side-effect functions that update @Published state
- Optional returns for operations that may fail: `URL?` for photo/video capture (line 437)
- Single value returns from pure helper functions: `String` from `questionForLanguage()` (line 357)

## Module Design

**Exports:**
- Single entry point: `@main` struct `SMFR2App` (note: file header still says SMFR2, renamed to ASSIST; see line 2)
- Main content view: `struct ContentView: View` (line 623)
- No public/private access control annotations (all top-level types implicitly internal)

**Barrel Files:**
- Not applicable — single file contains all code

## Hard Constraints (from CLAUDE.md)

**On-Device Only:**
- Never introduce network-based LLM calls — `FoundationModels` is on-device by design (CLAUDE.md constraint)
- All AI runs locally via `LanguageModelSession` without external API calls

**CameraManager Class:**
- Must remain a `class` (not struct) — AVFoundation delegate pattern requires reference semantics (line 383, CLAUDE.md constraint)
- Delegates stored in arrays: `photoCaptureDelegates`, `movieRecordingDelegates` (lines 392-393)

**RTL Support:**
- Check `AppLanguage.isRTL` (line 40) when adding UI for new screens
- Arabic layout requires special handling — any new screen touching text layout must respect this constraint

---

*Convention analysis: 2026-07-15*
