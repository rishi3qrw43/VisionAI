# Codebase Concerns

**Analysis Date:** 2026-07-15

## Tech Debt

**Monolithic File Architecture:**
- Issue: All application code (1,265 lines) is in a single file: `ASSIST/ContentView.swift`
- Scope: Models, state management, camera logic, and all 10+ view definitions in one file
- Impact: Difficult to maintain, test, and modify; violates separation of concerns; poor code reusability
- Fix approach: Extract into separate files: `Models/` (AppLanguage, AppScreen, HistoryItem, ChatMessage, LocalizedStrings), `State/AppState.swift`, `Camera/CameraManager.swift`, `Views/` (each view in its own file)

**View Stubs with Placeholder Text:**
- Issue: 8 out of 10 navigation screens are unimplemented placeholders (lines 1216-1263): `HistoryView`, `VideoView`, `RecordingView`, `MenuView`, `HistoryDetailView`, `AccessibilityView`, `NotificationsView`, `VideoSettingsView`
- Impact: App will crash or show "ViewName" text when users navigate to these screens
- Files: `ASSIST/ContentView.swift` (lines 1216-1263)
- Fix approach: Implement each view fully before release, or gate navigation to prevent access to unimplemented screens

**Hardcoded Demo Data:**
- Issue: AppState contains hardcoded demo history items (lines 165-171), demo chat messages (173-178), and demo login credentials in button (lines 777-786)
- Files: `ASSIST/ContentView.swift`
- Impact: Looks like real features in development screenshots; confuses users and testers; demo data will clutter actual user history
- Fix approach: Load demo data only in debug builds or behind a feature flag; implement proper persistent data storage with no hardcoded defaults

**Missing Data Persistence:**
- Issue: All state is in-memory via AppState ObservableObject; no database, UserDefaults, or file storage
- Files: `ASSIST/ContentView.swift` (lines 160-206)
- Impact: App closes = all scans, history, videos, and settings are lost; users cannot resume work
- Fix approach: Persist AppState to disk via Codable + UserDefaults or Core Data; save photos/videos to device storage with persistent references

**No File Cleanup Mechanism:**
- Issue: Photos saved to temp directory (line 554), videos to Documents (line 459), thumbnails to Documents (line 519) — no cleanup, no expiration, no quota
- Files: `ASSIST/ContentView.swift` (PhotoCaptureDelegate, generateThumbnail, startRecording)
- Impact: Disk space can fill up over time; old files accumulate; potential app crashes due to full disk
- Fix approach: Implement file pruning: delete files older than N days, or when device storage < threshold; add disk usage monitoring

---

## Known Bugs

**Invalid iOS Deployment Target:**
- Symptom: Build fails with "IPHONEOS_DEPLOYMENT_TARGET = 26.5" (invalid version)
- Files: `ASSIST.xcodeproj/project.pbxproj`
- Trigger: Run `xcode build` or `build_run_sim` from xcodebuildmcp
- Impact: Project will not build on any simulator or device
- Workaround: Manually edit project.pbxproj and set IPHONEOS_DEPLOYMENT_TARGET to a valid version (e.g., 17.0)
- Fix approach: Update build settings to iOS 17.0 or later (as documented in CLAUDE.md)

**Silent Failures in Vision Classification:**
- Symptom: Image classification silently fails with no user feedback; falls through to LLM-only mode
- Files: `ASSIST/ContentView.swift` (lines 239-253)
- Trigger: Run `analyzeScan()` when Vision API fails (invalid image format, network error, etc.)
- Cause: Broad `catch { }` with no logging or error reporting
- Workaround: Check system logs; no user-facing error message
- Impact: Users don't know if scan is degraded; silent quality loss

**Silent Failures in FoundationModels:**
- Symptom: LLM response generation fails silently; generic fallback text shown instead
- Files: `ASSIST/ContentView.swift` (lines 259-302, 317-330, 342-355)
- Trigger: FoundationModels API error (quota, invalid prompt, model timeout)
- Cause: Broad `catch { }` blocks with fallback strings
- Impact: Users see "Scan complete" or generic text instead of actual AI results; no way to debug

**Blocking Thread in Thumbnail Generation:**
- Symptom: App may freeze briefly when generating video thumbnail
- Files: `ASSIST/ContentView.swift` (lines 504-527, specifically line 524: `semaphore.wait()`)
- Trigger: Video recording completes and thumbnail is generated
- Cause: `DispatchSemaphore.wait()` blocks the current thread until async image generation finishes
- Workaround: Only visible as brief UI stutter
- Fix approach: Use async/await pattern or move to background queue; avoid blocking semaphores

---

## Security Considerations

**No Input Validation for Chat Messages:**
- Risk: User can send arbitrary text to LLM without length limits, content filtering, or injection protection
- Files: `ASSIST/ContentView.swift` (lines 307-314)
- Current mitigation: None
- Recommendations: Add chat message length limit (e.g., 1000 chars), implement content filtering or abuse detection, sanitize prompts before sending to LLM

**Camera Permission Not Explicitly Requested:**
- Risk: App assumes camera access; no graceful handling if user denies
- Files: `ASSIST/ContentView.swift` (lines 396-410)
- Current mitigation: Check `AVCaptureDevice.authorizationStatus()` and request if not determined, but deny case does nothing
- Recommendations: Show user-facing alert if camera denied, guide to Settings; fallback to gallery picker or image upload

**Audio Permission Not Requested:**
- Risk: Video recording includes audio (line 419) but app never explicitly requests microphone permission
- Files: `ASSIST/ContentView.swift` (lines 418-421)
- Current mitigation: None; system will silently degrade recording to video-only if permission denied
- Recommendations: Request microphone permission before recording; warn user if permission denied

**No Network Certificate Pinning:**
- Risk: If Vision, FoundationModels, or other APIs use network calls, MITM attacks possible
- Current mitigation: On-device models used (per CLAUDE.md); no external API calls
- Recommendations: Maintain this design; never add network LLM calls without certificate pinning

---

## Performance Bottlenecks

**Synchronous Thumbnail Generation:**
- Problem: `generateThumbnail()` uses `DispatchSemaphore.wait()` which blocks the thread (line 524)
- Files: `ASSIST/ContentView.swift` (lines 504-527)
- Cause: Async image generation is wrapped in synchronous function; waits on semaphore
- Improvement path: Rewrite as pure async/await; avoid blocking semaphores in Swift

**No LLM Session Reuse:**
- Problem: New `LanguageModelSession` created for each scan analysis, video chat, and video greeting (lines 266-268, 320-324, 345-347)
- Files: `ASSIST/ContentView.swift`
- Cause: Sessions created inline within async functions; no caching or pooling
- Impact: Potential slowdown with repeated analyses; unnecessary initialization overhead
- Improvement path: Create reusable session instances in AppState; initialize once and reuse; only create new session if language changes

**Large Single-File Module:**
- Problem: 1,265 lines in one file; compiler must load and parse everything to compile any change
- Files: `ASSIST/ContentView.swift`
- Impact: Slow incremental compilation; long build times even for small changes
- Improvement path: Split into separate modules (Models, State, Views, Camera)

---

## Fragile Areas

**AppState LLM Session State:**
- Files: `ASSIST/ContentView.swift` (line 201: `videoChatSession: LanguageModelSession?`)
- Why fragile: Nullable reference that may be nil when accessed; reset manually in `stopRecordingAndSend()` (line 334); no guarantee of cleanup if recording interrupted
- Safe modification: Always nil-check before use; consider using optional chaining; or restructure so session lifecycle is tied to recording state
- Test coverage: No tests; manual testing only

**Camera Delegate Management:**
- Files: `ASSIST/ContentView.swift` (lines 392-393, 442, 465-466, 576-579)
- Why fragile: Delegates stored in arrays and manually removed via reference equality (`===`); if removal logic fails, memory leaks occur
- Safe modification: Add unit tests for delegate cleanup; consider using weak references or auto-cleanup via deinit
- Test coverage: None

**Hardcoded String Constants:**
- Files: `ASSIST/ContentView.swift` (scattered throughout: "Analyzing image…", "Video saved!", etc.)
- Why fragile: Same strings duplicated in multiple places; changes require hunting through file; no single source of truth
- Safe modification: Extract all UI strings to LocalizedStrings or a strings file; use constants for repeated values
- Test coverage: None

---

## Scaling Limits

**In-Memory History Storage:**
- Current capacity: AppState.historyItems is a simple Array; no limit
- Limit: Once list exceeds ~10,000 items, rendering and scrolling will degrade; memory pressure on device
- Scaling path: Implement pagination (load 50 at a time), or migrate to Core Data with fetch-limited queries

**Temp and Documents Directory Usage:**
- Current capacity: No quota enforced; photos in temp (auto-cleared), videos in Documents (permanent)
- Limit: Device storage fills up; app may crash when writing new files
- Scaling path: Implement file cleanup (delete old files), add storage quota, offer cloud backup option

---

## Dependencies at Risk

**FoundationModels Availability:**
- Risk: Requires iOS 17.4+ and access to Apple's on-device language models; may not be available on all devices or regions
- Impact: App requires iOS 17.4+; users on older iOS cannot run app
- Mitigation: Current design explicitly uses FoundationModels; no fallback
- Recommendation: Document minimum iOS version clearly; consider fallback to simpler text classification if FoundationModels unavailable

**Vision Framework Limitations:**
- Risk: `ClassifyImageRequest` is a preview API; may be removed or changed in future iOS versions
- Impact: Image identification could break in future iOS release
- Mitigation: Currently gracefully handles Vision failure (falls through to LLM only)
- Recommendation: Monitor Apple release notes; implement alternative via MLModel if Vision changes

---

## Missing Critical Features

**No Offline Fallback:**
- Problem: App relies on FoundationModels which may require model downloads or internet (unclear from current docs)
- Blocks: Users cannot use app without stable connection if models not cached
- Recommendation: Test offline behavior; cache models; provide clear status feedback if models unavailable

**No Multilingual Camera/OCR:**
- Problem: Vision.ClassifyImageRequest returns labels in English only; no language-aware object detection
- Blocks: Non-English users see English classification labels, only description is translated
- Recommendation: Post-process Vision labels through translation API; or use language-specific Vision models

---

## Test Coverage Gaps

**No Unit Tests:**
- What's not tested: AppState logic, AI prompt generation, image analysis pipeline, file I/O, delegate cleanup, error handling
- Files: `ASSIST/ContentView.swift` (entire file)
- Risk: Bugs in core logic (AppState.deleteItem, analyzeScan, generateVideoResponse) may go undetected
- Priority: High

**No Integration Tests:**
- What's not tested: Full flow: camera → capture → analyze → display results; video recording → chat
- Risk: UI may work in simulator but fail on real device with actual FoundationModels/Vision APIs
- Priority: High

**No UI Tests:**
- What's not tested: Navigation flows, button taps, form validation, error messages, RTL layout
- Risk: Stubbed views and navigation errors only discovered by manual testing
- Priority: Medium

**No Performance Tests:**
- What's not tested: Large history list scrolling, memory usage with repeated scans, concurrent AI requests
- Risk: Performance regressions discovered after release
- Priority: Medium

---

## Architectural Concerns

**No Error Boundary for LLM Failures:**
- Issue: When FoundationModels fails, app shows generic fallback text with no indication something went wrong
- Impact: Users cannot distinguish "AI is thinking" from "AI failed"
- Fix: Show explicit error UI; allow retry; log error for debugging

**RTL Layout Incomplete:**
- Issue: Only checks `AppLanguage.isRTL` for text direction; custom layouts (ScanCorners, custom paths) may not respect RTL
- Files: `ASSIST/ContentView.swift` (line 40, used minimally)
- Impact: Arabic UI may have text flowing correctly but buttons/borders in wrong positions
- Fix: Audit all custom layouts for RTL support; use `.environment(\.layoutDirection, .rightToLeft)` at root

**No Logging Framework:**
- Issue: No structured logging; errors caught and silently dropped; no way to debug failures in production
- Impact: Difficult to diagnose user-reported issues
- Fix: Add logging framework (e.g., OSLog or simple file logger); log Vision failures, LLM timeouts, file I/O errors

---

## Unfinished Implementation

**Login Screen Non-Functional:**
- Issue: Login always succeeds if both fields non-empty; no actual authentication
- Files: `ASSIST/ContentView.swift` (lines 735-748)
- Impact: No real user identity; security risk if history is ever backed up

**Demo Account Hardcoded:**
- Issue: "Demo Account" button autofills test credentials (lines 777-786)
- Impact: Bypasses login flow entirely; should only exist in debug builds

---

*Concerns audit: 2026-07-15*
