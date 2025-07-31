# Swift Crash Prevention and Debugging Guide

This guide provides comprehensive strategies for preventing, debugging, and fixing crashes in the MagSafe Guard Swift application.

## Table of Contents

1. [Common Crash Causes](#common-crash-causes)
2. [UI Update Crashes](#ui-update-crashes)
3. [Memory Management](#memory-management)
4. [Concurrency and Threading](#concurrency-and-threading)
5. [Optional Handling](#optional-handling)
6. [CloudKit and Async Operations](#cloudkit-and-async-operations)
7. [Debugging Techniques](#debugging-techniques)
8. [Performance Optimization](#performance-optimization)
9. [Best Practices](#best-practices)

## Common Crash Causes

### 1. Force Unwrapping Optionals

**Problem:**

```swift
// ❌ Dangerous
let window = settingsWindow!
window.makeKeyAndOrderFront(nil)
```

**Solution:**

```swift
// ✅ Safe
guard let window = settingsWindow else {
    Log.warning("Settings window not available")
    return
}
window.makeKeyAndOrderFront(nil)
```

### 2. Retain Cycles

**Problem:**

```swift
// ❌ Creates retain cycle
class ViewController {
    var timer: Timer?
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateUI()  // Strong reference to self
        }
    }
}
```

**Solution:**

```swift
// ✅ Prevents retain cycle
class ViewController {
    var timer: Timer?
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateUI()
        }
    }
}
```

### 3. Array Index Out of Bounds

**Problem:**

```swift
// ❌ Can crash
let item = array[index]
```

**Solution:**

```swift
// ✅ Safe
guard index < array.count else { return }
let item = array[index]

// Or use safe subscript extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
```

## UI Update Crashes

### Main Thread Violations

**Problem:**

```swift
// ❌ Updates UI from background thread
Task {
    let data = await fetchData()
    statusLabel.text = data  // CRASH!
}
```

**Solution:**

```swift
// ✅ Ensures UI updates on main thread
Task {
    let data = await fetchData()
    await MainActor.run {
        statusLabel.text = data
    }
}

// Or use @MainActor
@MainActor
func updateUI(with data: String) {
    statusLabel.text = data
}
```

### SwiftUI State Updates

**Problem:**

```swift
// ❌ Modifying state during view update
struct ContentView: View {
    @State private var counter = 0
    
    var body: some View {
        Text("Count: \(counter)")
            .onAppear {
                counter += 1  // Can cause crash
            }
    }
}
```

**Solution:**

```swift
// ✅ Defer state updates
struct ContentView: View {
    @State private var counter = 0
    
    var body: some View {
        Text("Count: \(counter)")
            .onAppear {
                DispatchQueue.main.async {
                    counter += 1
                }
            }
    }
}
```

### Window Management in macOS

**Problem:**

```swift
// ❌ Force unwrapping window references
func showSettings() {
    settingsWindow!.makeKeyAndOrderFront(nil)
}
```

**Solution:**

```swift
// ✅ Safe window management
private weak var settingsWindow: NSWindow?
private var settingsHostingController: NSHostingController<SettingsView>?

func showSettings() {
    if let window = settingsWindow {
        window.makeKeyAndOrderFront(nil)
    } else {
        createAndShowSettingsWindow()
    }
}

func createAndShowSettingsWindow() {
    let settingsView = SettingsView()
        .environmentObject(userDefaultsManager)
    
    let hostingController = NSHostingController(rootView: settingsView)
    settingsHostingController = hostingController  // Retain controller
    
    let window = NSWindow(contentViewController: hostingController)
    window.delegate = self
    settingsWindow = window  // Weak reference
    
    window.makeKeyAndOrderFront(nil)
}
```

## Memory Management

### Avoiding Memory Leaks

1. **Use Weak References for Delegates**

```swift
// ✅ Correct
weak var delegate: MyDelegate?

// ❌ Incorrect - creates retain cycle
var delegate: MyDelegate?
```

1. **Break Retain Cycles in Closures**

```swift
// ✅ Using capture list
someAsyncOperation { [weak self] result in
    guard let self = self else { return }
    self.handleResult(result)
}
```

1. **Clean Up Resources**

```swift
deinit {
    timer?.invalidate()
    notificationObserver?.invalidate()
    cancellables.removeAll()
}
```

### Debugging Memory Issues

```swift
// Add memory leak detection
#if DEBUG
class MemoryLeakDetector {
    static func detectLeaks(for object: AnyObject) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak object] in
            if object != nil {
                Log.warning("Potential memory leak detected for \(type(of: object!))")
            }
        }
    }
}
#endif
```

## Concurrency and Threading

### Actor Isolation

```swift
// ✅ Use actors for thread-safe state management
actor DataManager {
    private var cache: [String: Data] = [:]
    
    func getData(for key: String) -> Data? {
        return cache[key]
    }
    
    func setData(_ data: Data, for key: String) {
        cache[key] = data
    }
}
```

### Avoiding Data Races

```swift
// ❌ Data race
class Counter {
    var value = 0
    
    func increment() {
        value += 1  // Not thread-safe
    }
}

// ✅ Thread-safe
class Counter {
    private let queue = DispatchQueue(label: "counter.queue")
    private var _value = 0
    
    var value: Int {
        queue.sync { _value }
    }
    
    func increment() {
        queue.async { [weak self] in
            self?._value += 1
        }
    }
}
```

### Async/Await Best Practices

```swift
// ✅ Proper error handling with async/await
func performNetworkRequest() async throws -> Data {
    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        return data
    } catch {
        Log.error("Network request failed", error: error)
        throw error
    }
}

// ✅ Cancellation support
func performLongOperation() async throws {
    for i in 0..<1000 {
        try Task.checkCancellation()
        // Do work
    }
}
```

## Optional Handling

### Safe Unwrapping Patterns

```swift
// 1. Guard Let
guard let value = optionalValue else {
    Log.warning("Optional value is nil")
    return
}

// 2. If Let
if let value = optionalValue {
    useValue(value)
}

// 3. Nil Coalescing
let value = optionalValue ?? defaultValue

// 4. Optional Chaining
let count = array?.count ?? 0

// 5. Compactmap for Collections
let validItems = items.compactMap { $0 }
```

### Optional Protocol Methods

```swift
// ✅ Safe optional protocol method call
@objc protocol MyDelegate: AnyObject {
    @objc optional func didUpdateValue(_ value: Int)
}

// Usage
delegate?.didUpdateValue?(42)
```

## CloudKit and Async Operations

### Safe CloudKit Initialization

```swift
public override init() {
    super.init()
    
    // Check for test environment
    let isTestEnvironment = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    
    if isTestEnvironment {
        syncStatus = .unknown
        isAvailable = false
        return
    }
    
    // Defer initialization to avoid circular dependencies
    syncStatus = .unknown
    isAvailable = false
}

public func enableSync() {
    guard !isCloudKitInitialized else { return }
    
    // Safe initialization
    do {
        container = CKContainer.default()
        privateDatabase = container?.privateCloudDatabase
        isCloudKitInitialized = true
        
        setupCloudKit()
        checkiCloudAvailability()
    } catch {
        Log.error("Failed to initialize CloudKit", error: error)
        syncStatus = .error
    }
}
```

### Handling CloudKit Errors

```swift
private func handleCloudKitError(_ error: CKError) {
    switch error.code {
    case .networkUnavailable, .networkFailure:
        syncStatus = .temporarilyUnavailable
        scheduleRetry()
    case .quotaExceeded:
        syncStatus = .error
        notifyUserAboutQuota()
    case .notAuthenticated:
        syncStatus = .noAccount
        notifyUserAboutiCloudAccount()
    default:
        syncStatus = .error
        Log.error("CloudKit error", error: error)
    }
}
```

## Debugging Techniques

### 1. Enable Zombie Objects

In Xcode:

- Edit Scheme → Run → Diagnostics
- Check "Zombie Objects"

### 2. Address Sanitizer

```swift
// Enable in Build Settings
// ENABLE_ADDRESS_SANITIZER = YES
```

### 3. Thread Sanitizer

```swift
// Enable in Build Settings
// ENABLE_THREAD_SANITIZER = YES
```

### 4. Symbolic Breakpoints

Set breakpoints for:

- `swift_willThrow`
- `NSException`
- `malloc_error_break`

### 5. Crash Logging

```swift
// Custom crash reporter
enum CrashReporter {
    static func configureCrashReporting() {
        NSSetUncaughtExceptionHandler { exception in
            Log.critical("Uncaught exception: \(exception)")
            Log.critical("Stack trace: \(exception.callStackSymbols)")
            
            // Save crash info to disk
            saveCrashReport(exception: exception)
        }
    }
    
    private static func saveCrashReport(exception: NSException) {
        let crashInfo = [
            "exception": exception.name.rawValue,
            "reason": exception.reason ?? "Unknown",
            "stackTrace": exception.callStackSymbols,
            "timestamp": Date().iso8601String
        ]
        
        // Save to persistent storage
        UserDefaults.standard.set(crashInfo, forKey: "lastCrashInfo")
    }
}
```

## Performance Optimization

### 1. Lazy Loading

```swift
// ✅ Load resources only when needed
lazy var expensiveResource: ExpensiveClass = {
    return ExpensiveClass()
}()
```

### 2. Avoid Blocking Main Thread

```swift
// ❌ Blocks main thread
let data = try Data(contentsOf: largeFileURL)

// ✅ Non-blocking
Task {
    let data = try await loadDataAsync(from: largeFileURL)
}
```

### 3. Efficient Collection Operations

```swift
// ❌ Inefficient
let filtered = array.filter { $0.isValid }.map { $0.value }

// ✅ More efficient
let filtered = array.compactMap { $0.isValid ? $0.value : nil }
```

### 4. Memory-Efficient Image Loading

```swift
// ✅ Downsample large images
func downsample(imageAt url: URL, to pointSize: CGSize) -> NSImage? {
    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else {
        return nil
    }
    
    let maxDimensionInPixels = max(pointSize.width, pointSize.height) * NSScreen.main?.backingScaleFactor ?? 2.0
    let downsampleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
    ] as CFDictionary
    
    guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
        return nil
    }
    
    return NSImage(cgImage: downsampledImage, size: pointSize)
}
```

## Best Practices

### 1. Defensive Programming

```swift
// Always validate inputs
func processData(_ data: Data?) {
    guard let data = data, !data.isEmpty else {
        Log.warning("Invalid data provided")
        return
    }
    // Process data
}
```

### 2. Error Handling

```swift
enum AppError: LocalizedError {
    case invalidInput
    case networkFailure
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input provided"
        case .networkFailure:
            return "Network connection failed"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

// Use Result type for explicit error handling
func performOperation() -> Result<Data, AppError> {
    // Implementation
}
```

### 3. Testing for Crashes

```swift
// Unit test for crash scenarios
func testForceUnwrapCrash() {
    let expectation = XCTestExpectation(description: "Should not crash")
    
    // Test optional handling
    let optional: String? = nil
    let value = optional ?? "default"
    XCTAssertEqual(value, "default")
    
    expectation.fulfill()
    wait(for: [expectation], timeout: 1.0)
}
```

### 4. Documentation

```swift
/// Safely shows the settings window.
/// - Important: This method handles nil window references gracefully
/// - Note: Creates a new window if none exists
func showSettings() {
    // Implementation
}
```

## Crash Prevention Checklist

- [ ] No force unwrapping (`!`) in production code
- [ ] All UI updates on main thread
- [ ] Weak references for delegates
- [ ] Capture lists in closures
- [ ] Array bounds checking
- [ ] Error handling for all async operations
- [ ] Resource cleanup in deinit
- [ ] Thread-safe property access
- [ ] Proper CloudKit initialization
- [ ] Memory leak testing
- [ ] Crash reporting configured
- [ ] Symbolic breakpoints set
- [ ] Address/Thread sanitizer enabled in debug

## References

- [Apple's Diagnosing Memory, Thread, and Crash Issues Early](https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [CloudKit Best Practices](https://developer.apple.com/documentation/cloudkit/improving_cloudkit_record_fetch_performance)
