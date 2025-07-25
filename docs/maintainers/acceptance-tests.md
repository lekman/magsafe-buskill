# Manual Acceptance Test Guide

This guide outlines manual tests that should be performed before releases to verify critical security functionality that cannot be safely automated.

## Prerequisites

- macOS device with MagSafe/USB-C power
- Test power adapter
- Admin privileges (for some security actions)
- Backup of important data (before testing destructive actions)

## Test Environment Setup

1. **Create a test user account** (recommended)

   - This isolates testing from your main account
   - Allows testing logout/shutdown without affecting work

2. **Disable automatic screen lock** temporarily

   - System Preferences → Lock Screen → Turn off "require password"
   - This prevents interference with manual testing

3. **Close important applications**
   - Save all work before testing

## Authentication Tests

### Test 1: Biometric Authentication Success

**Purpose**: Verify Touch ID/Face ID authentication works correctly

1. Build and run MagSafe Guard
2. Click "Arm Protection" in menu
3. Verify authentication prompt appears
4. Authenticate with Touch ID/Face ID
5. **Expected**: System arms successfully, menu shows "Disarm Protection"

### Test 2: Password Authentication Fallback

**Purpose**: Verify password authentication when biometrics fail

1. Arm the system (if not already armed)
2. Click "Disarm Protection"
3. When prompted, click "Enter Password" or cancel biometric prompt 3 times
4. Enter system password
5. **Expected**: System disarms successfully

### Test 3: Authentication Cancellation

**Purpose**: Verify cancellation is handled properly

1. Click "Arm Protection"
2. Cancel the authentication prompt
3. **Expected**: System remains disarmed, no crash

### Test 4: Rate Limiting

**Purpose**: Verify protection against brute force

1. Attempt to arm/disarm rapidly 5+ times
2. Cancel each authentication prompt
3. **Expected**: After 5 attempts, authentication is blocked temporarily

## Security Action Tests

### Test 5: Screen Lock Action

**Purpose**: Verify screen locks when power disconnected

1. Arm the system
2. Disconnect power adapter
3. **Expected**: Screen locks immediately (or after configured delay)
4. Reconnect power and unlock screen

### Test 6: Sound Alarm Action

**Purpose**: Verify alarm sounds on disconnect

1. Open Settings and enable "Sound Alarm" action
2. Set volume to 50%
3. Arm the system
4. Disconnect power adapter
5. **Expected**: Alarm sound plays
6. Reconnect power to stop alarm

### Test 7: Custom Script Action

**Purpose**: Verify custom scripts execute

1. Create test script: `~/test-security.sh`

   ```bash
   #!/bin/bash
   echo "Security triggered at $(date)" >> ~/security-test.log
   ```

2. Make executable: `chmod +x ~/test-security.sh`
3. Configure custom script path in Settings
4. Enable "Custom Script" action
5. Arm system and disconnect power
6. **Expected**: Check `~/security-test.log` contains new entry

### Test 8: Force Logout Action (Destructive)

**Purpose**: Verify force logout works

⚠️ **Warning**: Save all work before testing

1. Enable "Force Logout" action in Settings
2. Open a test document (to verify it closes)
3. Arm system and disconnect power
4. **Expected**: All apps close and return to login screen

### Test 9: System Shutdown Action (Destructive)

**Purpose**: Verify shutdown scheduling

⚠️ **Warning**: Save all work before testing

1. Enable "System Shutdown" action in Settings
2. Set shutdown delay to 30 seconds
3. Arm system and disconnect power
4. **Expected**: Shutdown warning appears, system shuts down after delay

## Integration Tests

### Test 10: Multiple Actions

**Purpose**: Verify multiple actions execute together

1. Enable both "Screen Lock" and "Sound Alarm"
2. Arm system and disconnect power
3. **Expected**: Both screen locks AND alarm sounds

### Test 11: Action Delay

**Purpose**: Verify delay configuration works

1. Set action delay to 5 seconds in Settings
2. Enable "Screen Lock" only
3. Arm system and disconnect power
4. Count 5 seconds
5. **Expected**: Screen locks after 5 second delay, not immediately

### Test 12: Quick Reconnect

**Purpose**: Verify reconnecting power stops actions

1. Enable "Sound Alarm" with 3 second delay
2. Arm system and disconnect power
3. Reconnect power within 2 seconds
4. **Expected**: No alarm sounds (action cancelled)

## Performance Tests

### Test 13: Battery Monitoring

**Purpose**: Verify no significant battery drain

1. Note battery percentage
2. Run MagSafe Guard armed for 1 hour
3. Check battery percentage
4. **Expected**: No unusual battery drain (<2% for idle monitoring)

### Test 14: Memory Usage

**Purpose**: Verify no memory leaks

1. Open Activity Monitor
2. Find MagSafe Guard process
3. Note memory usage
4. Arm/disarm 20 times
5. Disconnect/reconnect power 10 times
6. **Expected**: Memory usage remains stable (< 50MB)

## Error Handling Tests

### Test 15: Missing Resources

**Purpose**: Verify graceful handling of missing resources

1. Delete any custom alarm sound (if configured)
2. Enable "Sound Alarm"
3. Trigger security action
4. **Expected**: Falls back to system beep, no crash

### Test 16: Permission Denied

**Purpose**: Verify handling of permission errors

1. Create script without execute permission
2. Configure as custom script
3. Trigger security action
4. **Expected**: Error logged, other actions still execute

## Test Report Template

```ini
Date: ___________
Version: ___________
Tester: ___________
Device: ___________
macOS Version: ___________

Authentication Tests:
[ ] Test 1: Biometric Success - Pass/Fail
[ ] Test 2: Password Fallback - Pass/Fail
[ ] Test 3: Cancellation - Pass/Fail
[ ] Test 4: Rate Limiting - Pass/Fail

Security Action Tests:
[ ] Test 5: Screen Lock - Pass/Fail
[ ] Test 6: Sound Alarm - Pass/Fail
[ ] Test 7: Custom Script - Pass/Fail
[ ] Test 8: Force Logout - Pass/Fail
[ ] Test 9: System Shutdown - Pass/Fail

Integration Tests:
[ ] Test 10: Multiple Actions - Pass/Fail
[ ] Test 11: Action Delay - Pass/Fail
[ ] Test 12: Quick Reconnect - Pass/Fail

Performance Tests:
[ ] Test 13: Battery Usage - Pass/Fail
[ ] Test 14: Memory Usage - Pass/Fail

Error Handling:
[ ] Test 15: Missing Resources - Pass/Fail
[ ] Test 16: Permission Denied - Pass/Fail

Notes:
_________________________________
_________________________________
_________________________________
```

## Automated Test Coverage

The following functionality IS covered by automated tests:

- Configuration persistence
- Business logic for action coordination
- Power state change detection
- Menu creation and updates
- Error handling logic
- API contracts

The manual tests above focus on:

- System integration points
- Hardware interaction
- Destructive actions
- User experience flows
- Performance characteristics
