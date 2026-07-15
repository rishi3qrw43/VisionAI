# Codebase Structure

**Analysis Date:** 2026-07-15

## Directory Layout

```
/Users/rishivora/Desktop/ASSIST/
├── ASSIST/                               # Main iOS app source code
│   ├── ASSISTApp.swift                  # @main app entry point
│   ├── ContentView.swift                # ALL models, state, views (1266 lines)
│   ├── CLAUDE.md                        # Project documentation
│   └── Assets.xcassets/                 # Image/icon assets
│       ├── AppIcon.appiconset/          # App icon set (iOS app icon)
│       ├── AccentColor.colorset/        # Brand accent color definitions
│       └── Contents.json                # Asset catalog metadata
├── ASSIST.xcodeproj/                    # Xcode project configuration
│   ├── project.pbxproj                  # Build configuration (Xcode 16 file-system sync)
│   ├── project.xcworkspace/             # Workspace settings
│   └── xcuserdata/                      # User-specific Xcode settings (not committed)
├── .planning/                            # GSD work tracking
│   └── codebase/                        # Codebase analysis documents
│       ├── ARCHITECTURE.md               # (This file)
│       └── STRUCTURE.md                 # (This file)
├── .claude/                              # Claude Code harness config
│   └── settings.local.json              # Local Claude Code settings
├── .mcp.json                             # MCP server configuration
└── my-project/                          # Unrelated React/TypeScript projects (ignore)
```

## Directory Purposes

**`ASSIST/`:**
- Purpose: Source code for the iOS app
- Contains: All Swift source files, asset catalog, project documentation
- Key files: `ASSISTApp.swift`, `ContentView.swift`, `CLAUDE.md`

**`ASSIST/Assets.xcassets/`:**
- Purpose: Image and color assets managed by Xcode's asset catalog
- Contains: App icon set, accent color definitions, asset metadata
- Format: `.xcassets` directory with nested `.imageset` and `.colorset` folders
- Committed: Yes — assets are version-controlled
- Generated: No — manually curated by developers

**`ASSIST.xcodeproj/`:**
- Purpose: Xcode project configuration (build settings, schemes, targets)
- Contains: `project.pbxproj` (main config), workspace settings, user data
- Committed: Yes — `project.pbxproj` and workspace settings are committed
- Generated: No — manually edited by Xcode; not auto-generated

**`.planning/codebase/`:**
- Purpose: GSD codebase analysis documents (ARCHITECTURE.md, STRUCTURE.md, etc.)
- Committed: Yes — reference documents for future phases
- Generated: During `/gsd-map-codebase` runs

**`.claude/`:**
- Purpose: Claude Code harness configuration
- Contains: `settings.local.json` (local dev settings, git-ignored)
- Not committed: User-specific settings

**`.mcp.json`:**
- Purpose: MCP (Model Context Protocol) server configuration for Claude Code
- Contains: MCP server connection details
- Example: `{ "mcpServers": { "xcodebuildmcp": { ... } } }`

## Key File Locations

**Entry Points:**
- `ASSIST/ASSISTApp.swift`: Application entry point — `@main` struct `SMFR2App` (note: name not updated from original project name)
- `ASSIST/ContentView.swift` line 623: Root SwiftUI view — `struct ContentView: View`

**Configuration:**
- `ASSIST.xcodeproj/project.pbxproj`: Build settings, target, schemes
- `ASSIST/CLAUDE.md`: Project documentation (stack, constraints, how to build)

**Core Logic:**
- `ASSIST/ContentView.swift` line 160: `AppState` — Central app state and business logic
- `ASSIST/ContentView.swift` line 383: `CameraManager` — Camera I/O and video recording
- `ASSIST/ContentView.swift` line 49: Localization strings and language support

**Testing:**
- None — No tests present in repository

## Naming Conventions

**Files:**
- PascalCase for Swift source files: `ASSISTApp.swift`, `ContentView.swift`
- Camel case for asset names: `AppIcon`, `AccentColor`
- Asset folders use `.xcassets`, `.appiconset`, `.colorset` conventions per Xcode

**Swift Identifiers:**
- Classes: PascalCase — `AppState`, `CameraManager`, `PhotoCaptureDelegate`
- Structs: PascalCase — `LocalizedStrings`, `HistoryItem`, `ChatMessage`, `HomeView`, `LoginView`
- Enums: PascalCase — `AppLanguage`, `AppScreen`, `HistoryTab`
- Functions: camelCase — `capturePhoto()`, `analyzeScan(imageURL:)`, `deleteItem(_:)`
- Properties: camelCase — `isLoggedIn`, `lastScanTitle`, `currentLanguage`
- Private/internal: camelCase with leading underscore for some local state — `_email`, `_password` (in login form)

**View Structs:**
- Suffix pattern: `View` — `LoginView`, `HomeView`, `LanguageView`, `HistoryView`, `VideoView`, `RecordingView`, `MenuView`, `HistoryDetailView`, `AccessibilityView`, `NotificationsView`, `AboutView`, `VideoSettingsView`
- Root: `ContentView` — contains screen routing logic
- Delegates: Suffix `Delegate` — `PhotoCaptureDelegate`, `MovieRecordingDelegate`

## Where to Add New Code

**New Feature (Screen/Functionality):**
- Primary code: Add new View struct at end of `ASSIST/ContentView.swift`
- State: Add new `@Published` properties to `AppState` class (lines 160–366)
- Navigation: Add new case to `AppScreen` enum (lines 44–47)
- Example:
  ```swift
  // 1. Add to AppScreen enum
  enum AppScreen {
      case login, home, ...
      case newFeature  // ← Add here
  }
  
  // 2. Add state to AppState
  class AppState: ObservableObject {
      @Published var newFeatureData: String = ""
      func newFeatureAction() { ... }
  }
  
  // 3. Add view struct
  struct NewFeatureView: View {
      @ObservedObject var state: AppState
      var body: some View { ... }
  }
  
  // 4. Add to ContentView switch
  case .newFeature: NewFeatureView(state: state)
  ```

**New Component/Module:**
- Small utility function/struct: Add to `ContentView.swift` near related code
- Medium reusable component: Consider creating `ASSIST/ComponentName.swift` and importing in `ContentView.swift`
- Large refactor: Split `ContentView.swift` by domain (see ARCHITECTURE.md anti-patterns section)

**Localized String:**
- Add to `LocalizedStrings` struct (lines 49–62)
- Add translations for all 5 languages to `translations` dictionary (lines 64–135)
- Access in views via `state.text.<property>`

**Camera/Video Feature:**
- Add methods to `CameraManager` class (lines 383–599)
- Use `@ObservedObject var camera: CameraManager` in view (e.g., `HomeView` line 929)
- Call camera methods from view actions

**AI/ML Integration:**
- Image classification: Use `Vision.ClassifyImageRequest()` in `analyzeScan()` pattern (line 240)
- Text generation: Create `LanguageModelSession(instructions:)` and call `.respond(to:)` pattern (lines 266–275)
- Keep async/await pattern for Main thread safety

**Settings/Configuration:**
- Add `@Published` property to `AppState` (e.g., `videoQuality: String` at line 192)
- Add input control to settings view (e.g., `VideoSettingsView` at line 1260)
- Apply setting to system (e.g., `CameraManager.setVideoQuality(_:)` at line 533)

## Special Directories

**`ASSIST/Assets.xcassets/`:**
- Purpose: Asset catalog for images and colors
- Generated: No — manually maintained
- Committed: Yes — version-controlled assets
- Management: Use Xcode's asset catalog editor or drag-and-drop to add images
- Naming: Use camelCase identifiers; asset files themselves use descriptive names

**`.planning/codebase/`:**
- Purpose: GSD work planning documents (auto-generated during codebase analysis)
- Generated: Yes — by `/gsd-map-codebase` skill
- Committed: Yes — documents are source-controlled
- Contents: `ARCHITECTURE.md`, `STRUCTURE.md`, `CONVENTIONS.md`, `TESTING.md`, `CONCERNS.md`, etc.

**`.claude/`:**
- Purpose: Claude Code harness configuration (local to developer)
- Generated: No — user-configured
- Committed: No — `.local.json` files are git-ignored
- Contents: `settings.local.json` for local overrides

## File Organization Summary

| Layer | Files | Location |
|-------|-------|----------|
| **App Entry** | `ASSISTApp.swift` | `ASSIST/` |
| **Root View** | `ContentView.swift` (line 623–655) | `ASSIST/` |
| **State** | `AppState` class (line 160–366) | `ASSIST/ContentView.swift` |
| **Models** | `AppScreen`, `AppLanguage`, `HistoryItem`, `ChatMessage` | `ASSIST/ContentView.swift` |
| **Localization** | `LocalizedStrings`, `translations` dict | `ASSIST/ContentView.swift` (line 49–135) |
| **Views** | All SwiftUI View structs | `ASSIST/ContentView.swift` (line 658–1263) |
| **Infrastructure** | `CameraManager`, delegates | `ASSIST/ContentView.swift` (line 383–599) |
| **Assets** | Icons, colors | `ASSIST/Assets.xcassets/` |
| **Config** | Build settings, target definition | `ASSIST.xcodeproj/project.pbxproj` |

## Current Limitations & Refactoring Opportunities

**Monolithic File:** All code in single `ContentView.swift` (1266 lines) makes it hard to navigate. Consider splitting into:
- `ASSIST/Models/AppState.swift`
- `ASSIST/Models/CameraManager.swift`
- `ASSIST/Localization/Strings.swift`
- `ASSIST/Views/ContentView.swift` (routing only)
- `ASSIST/Views/HomeView.swift`, etc. (individual screens)

**No Test Structure:** Tests should live in `ASSSISTTests/` directory parallel to main target, with:
- `AppStateTests.swift`
- `CameraManagerTests.swift`
- etc.

**No Separate Model Layer:** Data models (`HistoryItem`, `ChatMessage`) are in the same file as views. Consider:
- `ASSIST/Models/HistoryItem.swift`
- `ASSIST/Models/ChatMessage.swift`

**Asset Organization:** `Assets.xcassets/` is minimal. As app grows, organize into subsets:
- `Colors/` — color sets
- `Icons/` — icon sets
- `Images/` — generic images
- `LaunchScreen/` — launch screen assets

---

*Structure analysis: 2026-07-15*
