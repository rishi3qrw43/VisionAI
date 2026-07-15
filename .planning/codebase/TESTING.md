# Testing Patterns

**Analysis Date:** 2026-07-15

## Current State: No Test Infrastructure

**No test runner configured:**
- XCTest target does not exist in `ASSIST.xcodeproj`
- Zero test files in repository (`grep -r "import XCTest"` returns empty)
- No test configuration: no `.xctest` bundle, no `XCTestCase` subclasses

**Result:** This is a production app with zero automated test coverage. Any validation currently relies on manual testing and runtime observation.

## How to Add Tests

### Step 1: Create XCTest Target

```bash
# In Xcode: File → New → Target → iOS Unit Testing Bundle
# Name it: ASSISTTests
# Add to scheme: ASSIST
```

Or via CLI (Swift Package Manager projects):
```bash
# For Xcode projects, use Xcode's UI (above) — xctest cannot be added via swift package init
```

### Step 2: Test Candidate Areas (by testability)

#### Testable Without Refactoring (Pure Logic)

**History Management** (`ContentView.swift:216-230`):
```swift
import XCTest
@testable import ASSIST

final class HistoryManagementTests: XCTestCase {
    var appState: AppState!
    
    override func setUp() {
        super.setUp()
        appState = AppState()
    }
    
    func testDeleteItem_marksItemDeleted() {
        let itemId = 1
        appState.deleteItem(itemId)
        let item = appState.historyItems.first { $0.id == itemId }
        XCTAssertTrue(item?.deleted ?? false)
    }
    
    func testRestoreItem_clearsDeletedFlag() {
        let itemId = 1
        appState.deleteItem(itemId)
        appState.restoreItem(itemId)
        let item = appState.historyItems.first { $0.id == itemId }
        XCTAssertFalse(item?.deleted ?? true)
    }
    
    func testPermanentlyDelete_removesItem() {
        let initialCount = appState.historyItems.count
        appState.permanentlyDelete(1)
        XCTAssertEqual(appState.historyItems.count, initialCount - 1)
    }
}
```

**Language Selection** (`ContentView.swift:357-365`):
```swift
func testQuestionForLanguage_returnsCorrectLanguageString() {
    let enQuestion = appState.questionForLanguage(.english)
    XCTAssertEqual(enQuestion, "What is this?")
    
    let esQuestion = appState.questionForLanguage(.spanish)
    XCTAssertEqual(esQuestion, "¿Qué es esto?")
    
    let arQuestion = appState.questionForLanguage(.arabic)
    XCTAssertEqual(arQuestion, "ما هذا؟")
}
```

**Localization Access** (`ContentView.swift:203-205`):
```swift
func testCurrentLanguageTranslations_returnsCorrectDict() {
    appState.currentLanguage = .english
    let strings = appState.text
    XCTAssertEqual(strings.langTitle, "Select Language")
    
    appState.currentLanguage = .spanish
    let spanishStrings = appState.text
    XCTAssertEqual(spanishStrings.langTitle, "Seleccionar idioma")
}
```

#### Requires Protocol Extraction Before Testing

**Camera Operations** (`ContentView.swift:383-599`):
- `CameraManager` tightly couples AVFoundation (AVCaptureSession, delegates)
- To test: extract `CameraSessionProtocol`, mock AVCaptureSession behavior
- Testable methods: photo/video capture, session setup, quality settings (lines 396-546)

**Example protocol for testability:**
```swift
protocol CameraSessionProtocol {
    func setup()
    func stop()
    func capturePhoto(completion: @escaping (URL?) -> Void)
    func startRecording(maxDuration: Int?)
    func stopRecording(completion: ((URL?) -> Void)?)
}

// Then CameraManager implements CameraSessionProtocol
// And mocks can inject a FakeCameraSession for tests
```

**AI Functions** (`ContentView.swift:234-356`):
- `analyzeScan()` and `generateVideoResponse()` call `LanguageModelSession` directly
- To test: extract `LanguageModelSessionProtocol`, inject mock responses
- Can test prompts, error handling, state updates independently

**Example:**
```swift
protocol LanguageModelSessionProtocol {
    func respond(to prompt: String) async throws -> (content: String)
}

// Mock for testing:
class MockLanguageModelSession: LanguageModelSessionProtocol {
    var responseOverride: String?
    var shouldThrow: Bool = false
    
    func respond(to prompt: String) async throws -> (content: String) {
        if shouldThrow {
            throw URLError(.unknown)
        }
        return (content: responseOverride ?? "Test response")
    }
}
```

## Test Organization

**File Structure (once added):**
```
ASSIST.xcodeproj/
├── ASSIST/
│   ├── ASSISTApp.swift
│   ├── ContentView.swift
│   └── Assets.xcassets/
└── ASSISTTests/
    ├── HistoryManagementTests.swift
    ├── LanguageTests.swift
    ├── CameraManagerTests.swift
    ├── AIFunctionsTests.swift
    └── Mocks/
        ├── MockCameraSession.swift
        ├── MockLanguageModelSession.swift
        └── TestFixtures.swift
```

**Naming:** `[FeatureName]Tests.swift` — one test file per area being tested

## Run Commands (once configured)

```bash
# Run all tests
xcodebuild test -project ASSIST.xcodeproj -scheme ASSIST

# Watch mode (requires xcodebuild plugin or Xcode UI)
xcodebuild test -project ASSIST.xcodeproj -scheme ASSIST -resultBundlePath /tmp/results

# Coverage (Xcode 15+)
xcodebuild test -project ASSIST.xcodeproj -scheme ASSIST -enableCodeCoverage YES
```

## Test Structure Pattern

**Recommended approach:**
```swift
final class FeatureTests: XCTestCase {
    var sut: ClassUnderTest!  // sut = "system under test"
    
    override func setUp() {
        super.setUp()
        // Initialize dependencies
        sut = ClassUnderTest()
    }
    
    override func tearDown() {
        super.tearDown()
        // Cleanup if needed (file handles, temp dirs)
        sut = nil
    }
    
    func testBehavior_givenInput_producesOutput() {
        // Arrange
        let input = SampleInput()
        
        // Act
        let result = sut.process(input)
        
        // Assert
        XCTAssertEqual(result, expectedOutput)
    }
}
```

## Mocking Strategy (for async code)

**AsyncExpectation pattern for testing async functions:**
```swift
func testAnalyzeScan_updatesStateOnSuccess() async throws {
    let mockSession = MockLanguageModelSession()
    mockSession.responseOverride = "Vegetable → Broccoli\nA green cruciferous vegetable."
    
    await appState.analyzeScan(imageURL: testImageURL)
    
    XCTAssertEqual(appState.lastScanTitle, "Vegetable → Broccoli")
    XCTAssertTrue(appState.lastScanTitle.contains("Vegetable"))
}

// XCTest supports async test methods (iOS 13+):
func testAsyncFunction() async throws {
    // await is available in test methods
}
```

## Test Data & Fixtures

**Sample fixture location:** `ASSISTTests/Fixtures/`

```swift
struct TestFixtures {
    static let sampleHistoryItem = HistoryItem(
        id: 999,
        type: "scan",
        imageURL: "https://example.com/test.jpg",
        desc: "Test item",
        time: "3:42 PM",
        date: "Jul 15, 2026",
        deleted: false,
        previewURL: nil
    )
    
    static let sampleChatMessage = ChatMessage(
        role: "user",
        text: "What is this?"
    )
}
```

## Coverage Goals (Once Tests Exist)

**Immediate targets:**
- Pure logic: History management, localization → aim for 100% coverage
- State management: `AppState` property setters and computed properties → 80%+
- Error paths: catch blocks in Vision/LLM → all error cases

**Defer to integration testing:**
- Full Vision pipeline (requires real image)
- FoundationModels responses (requires on-device AI)
- AVCaptureSession camera operations (simulator-limited)
- SwiftUI view rendering

## Key Testing Constraints

**On-Device AI (CLAUDE.md constraint):**
- Cannot mock `LanguageModelSession` to external API calls — tests must use device models only
- Test error cases with mock implementations; avoid production LLM calls in unit tests

**Camera Manager Must Stay a Class:**
- Tests can verify delegation patterns, but cannot fully mock AVCaptureSession in XCTest without significant refactoring
- Recommend protocol extraction first (see "Requires Protocol Extraction" section above)

**No External Test Dependencies:**
- Do not add third-party testing frameworks (Quick, Nimble, OHHTTPStubs, etc.)
- Use only XCTest (built-in to Xcode)

---

*Testing analysis: 2026-07-15*

**Status:** No test infrastructure. See "How to Add Tests" section for phased approach starting with pure logic (history, localization) before attempting async/camera code.
