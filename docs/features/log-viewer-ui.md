# Log Viewer UI Design Document

## Overview

The Log Viewer provides a graphical interface for viewing, searching, and analyzing MagSafe Guard's event log history. Built with SwiftUI following the MVVM-C pattern, it integrates seamlessly with the existing menu bar application architecture while providing powerful log analysis capabilities.

## Architecture

### MVVM-C Pattern Implementation

The Log Viewer follows the project's established MVVM-C (Model-View-ViewModel-Coordinator) pattern for consistency and maintainability:

```swift
// View
struct EventLogView: View { }

// ViewModel
class EventLogViewModel: ObservableObject { }

// Coordinator (Window Management)
class EventLogWindowController: NSWindowController { }

// Model (Existing)
struct EventLogEntry { }
```

### Component Structure

```ini
MagSafeGuard/
├── Views/
│   └── EventLog/
│       ├── EventLogView.swift           # Main SwiftUI view
│       ├── EventLogViewModel.swift      # Business logic and state
│       ├── EventLogRowView.swift        # Individual log entry view
│       └── EventLogFilterView.swift     # Filter/search controls
├── Controllers/
│   └── EventLogWindowController.swift   # Window lifecycle management
└── Extensions/
    └── EventLogEntry+UI.swift           # UI-specific extensions
```

## UI Design

### Window Specifications

- **Default Size**: 800x600 pixels
- **Minimum Size**: 600x400 pixels
- **Style Mask**: `.titled, .closable, .miniaturizable, .resizable`
- **Title**: "MagSafe Guard - Event Log"
- **Restorable**: Yes (saves window position/size)

### Layout Structure

```text
┌─────────────────────────────────────────────────────┐
│ Event Log                                       [-][+][x]│
├─────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────┐ │
│ │ [Search...] [All Events ▼] [Today ▼] [Export]  │ │
│ └─────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────┐ │
│ │ Time     Event              Details      State  │ │
│ ├─────────────────────────────────────────────────┤ │
│ │ 14:32:01 Armed              User auth    Armed  │ │
│ │ 14:30:15 Power Disconnected While armed  Armed  │ │
│ │ 14:25:00 Disarmed           Manual       Disarm │ │
│ │ ...                                              │ │
│ └─────────────────────────────────────────────────┘ │
│ [Clear Log] [Refresh]          Showing 50 of 127    │
└─────────────────────────────────────────────────────┘
```

### View Components

#### 1. Filter Bar

```swift
struct EventLogFilterView: View {
    @Binding var searchText: String
    @Binding var selectedEventType: AppEvent?
    @Binding var selectedDateRange: DateRange

    var body: some View {
        HStack {
            // Search field
            TextField("Search...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)

            // Event type filter
            Picker("Event Type", selection: $selectedEventType) {
                Text("All Events").tag(nil as AppEvent?)
                Divider()
                ForEach(AppEvent.allCases, id: \.self) { event in
                    Text(event.displayName).tag(event as AppEvent?)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)

            // Date range picker
            Picker("Date Range", selection: $selectedDateRange) {
                Text("Today").tag(DateRange.today)
                Text("Last 7 Days").tag(DateRange.week)
                Text("Last 30 Days").tag(DateRange.month)
                Text("All Time").tag(DateRange.all)
            }
            .pickerStyle(.menu)
            .frame(width: 120)

            Spacer()

            // Export button
            Button("Export") {
                // Export action
            }
            .help("Export log entries to CSV")
        }
        .padding()
    }
}
```

#### 2. Log Table

```swift
struct EventLogTableView: View {
    @ObservedObject var viewModel: EventLogViewModel

    var body: some View {
        Table(viewModel.filteredEvents) {
            TableColumn("Time", value: \.timestamp) { entry in
                Text(entry.timestamp, formatter: timeFormatter)
                    .font(.system(.body, design: .monospaced))
            }
            .width(min: 80, ideal: 100, max: 120)

            TableColumn("Event") { entry in
                HStack {
                    Image(systemName: entry.event.symbolName)
                        .foregroundColor(entry.event.color)
                    Text(entry.event.displayName)
                }
            }
            .width(min: 150, ideal: 200, max: 250)

            TableColumn("Details", value: \.details) { entry in
                Text(entry.details ?? "—")
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(entry.details ?? "")
            }

            TableColumn("State") { entry in
                StateBadge(state: entry.state)
            }
            .width(80)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
    }
}
```

#### 3. Individual Row View

```swift
struct EventLogRowView: View {
    let entry: EventLogEntry

    var body: some View {
        HStack {
            // Timestamp
            Text(entry.timestamp, formatter: timeFormatter)
                .font(.system(.caption, design: .monospaced))
                .frame(width: 100, alignment: .leading)

            // Event icon and name
            HStack(spacing: 4) {
                Image(systemName: entry.event.symbolName)
                    .foregroundColor(entry.event.color)
                Text(entry.event.displayName)
            }
            .frame(width: 200, alignment: .leading)

            // Details
            Text(entry.details ?? "—")
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // State badge
            StateBadge(state: entry.state)
                .frame(width: 80)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }
}
```

#### 4. State Badge Component

```swift
struct StateBadge: View {
    let state: AppState

    var body: some View {
        Text(state.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(state.color.opacity(0.2))
            .foregroundColor(state.color)
            .clipShape(Capsule())
    }
}
```

## View Model Implementation

### EventLogViewModel

```swift
@MainActor
class EventLogViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var events: [EventLogEntry] = []
    @Published var searchText: String = ""
    @Published var selectedEventType: AppEvent?
    @Published var selectedDateRange: DateRange = .today
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Computed Properties
    var filteredEvents: [EventLogEntry] {
        events
            .filter(searchFilter)
            .filter(eventTypeFilter)
            .filter(dateRangeFilter)
            .sorted { $0.timestamp > $1.timestamp }
    }

    var eventCountText: String {
        let filtered = filteredEvents.count
        let total = events.count
        return filtered == total ?
            "Showing \(total) events" :
            "Showing \(filtered) of \(total) events"
    }

    // MARK: - Dependencies
    private let appController: AppController
    private var refreshTimer: Timer?

    // MARK: - Initialization
    init(appController: AppController = AppController.shared) {
        self.appController = appController
        loadEvents()
        startAutoRefresh()
    }

    // MARK: - Public Methods
    func refresh() {
        loadEvents()
    }

    func clearLog() {
        appController.clearEventLog()
        events.removeAll()
    }

    func exportToCSV() async throws -> URL {
        let csvContent = generateCSV(from: filteredEvents)
        let fileName = "magsafe-guard-log-\(Date().ISO8601Format()).csv"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)

        try csvContent.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Private Methods
    private func loadEvents() {
        isLoading = true
        events = appController.getEventLog(limit: 1000)
        isLoading = false
    }

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.loadEvents()
        }
    }

    // MARK: - Filters
    private func searchFilter(_ entry: EventLogEntry) -> Bool {
        guard !searchText.isEmpty else { return true }
        let searchLower = searchText.lowercased()

        return entry.event.rawValue.lowercased().contains(searchLower) ||
               entry.details?.lowercased().contains(searchLower) ?? false ||
               entry.state.rawValue.lowercased().contains(searchLower)
    }

    private func eventTypeFilter(_ entry: EventLogEntry) -> Bool {
        guard let selectedType = selectedEventType else { return true }
        return entry.event == selectedType
    }

    private func dateRangeFilter(_ entry: EventLogEntry) -> Bool {
        selectedDateRange.contains(entry.timestamp)
    }

    deinit {
        refreshTimer?.invalidate()
    }
}
```

## Window Management

### EventLogWindowController

```swift
class EventLogWindowController: NSWindowController {
    static var shared: EventLogWindowController?

    convenience init() {
        let eventLogView = EventLogView()
        let hostingView = NSHostingView(rootView: eventLogView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "MagSafe Guard - Event Log"
        window.contentView = hostingView
        window.center()
        window.setFrameAutosaveName("EventLogWindow")
        window.minSize = NSSize(width: 600, height: 400)

        self.init(window: window)
        EventLogWindowController.shared = self
    }

    static func showEventLog() {
        if let existingController = shared {
            existingController.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            let controller = EventLogWindowController()
            controller.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    override func windowWillClose(_ notification: Notification) {
        EventLogWindowController.shared = nil
    }
}
```

## Integration Points

### Menu Bar Integration

Update the menu construction in `AppDelegateCore.swift`:

```swift
// Replace the TODO in showEventLog()
@objc func showEventLog() {
    EventLogWindowController.showEventLog()
}
```

### Keyboard Shortcut

The existing `Cmd+L` shortcut in the menu bar will open the log viewer window.

## Data Models

### Extensions for UI

```swift
// EventLogEntry+UI.swift
extension AppEvent {
    var displayName: String {
        switch self {
        case .armed: return "Armed"
        case .disarmed: return "Disarmed"
        case .powerDisconnected: return "Power Disconnected"
        case .powerConnected: return "Power Connected"
        case .gracePeriodStarted: return "Grace Period Started"
        case .gracePeriodCancelled: return "Grace Period Cancelled"
        case .securityActionExecuted: return "Security Action"
        case .authenticationFailed: return "Auth Failed"
        case .authenticationSucceeded: return "Auth Success"
        case .applicationTerminating: return "App Terminating"
        case .autoArmTriggered: return "Auto-Arm"
        }
    }

    var symbolName: String {
        switch self {
        case .armed: return "lock.fill"
        case .disarmed: return "lock.open.fill"
        case .powerDisconnected: return "bolt.slash"
        case .powerConnected: return "bolt.fill"
        case .gracePeriodStarted: return "timer"
        case .gracePeriodCancelled: return "xmark.circle"
        case .securityActionExecuted: return "exclamationmark.shield.fill"
        case .authenticationFailed: return "xmark.shield"
        case .authenticationSucceeded: return "checkmark.shield"
        case .applicationTerminating: return "power"
        case .autoArmTriggered: return "location.fill"
        }
    }

    var color: Color {
        switch self {
        case .armed, .authenticationSucceeded: return .green
        case .disarmed: return .blue
        case .powerDisconnected, .authenticationFailed: return .red
        case .powerConnected: return .green
        case .gracePeriodStarted: return .orange
        case .gracePeriodCancelled: return .gray
        case .securityActionExecuted: return .purple
        case .applicationTerminating: return .gray
        case .autoArmTriggered: return .teal
        }
    }
}

extension AppState {
    var displayName: String {
        switch self {
        case .disarmed: return "Disarmed"
        case .armed: return "Armed"
        case .gracePeriod: return "Grace"
        case .triggered: return "Triggered"
        }
    }

    var color: Color {
        switch self {
        case .disarmed: return .blue
        case .armed: return .green
        case .gracePeriod: return .orange
        case .triggered: return .red
        }
    }
}
```

### DateRange Helper

```swift
enum DateRange: String, CaseIterable {
    case today = "Today"
    case week = "Last 7 Days"
    case month = "Last 30 Days"
    case all = "All Time"

    func contains(_ date: Date) -> Bool {
        switch self {
        case .today:
            return Calendar.current.isDateInToday(date)
        case .week:
            return date > Date().addingTimeInterval(-7 * 24 * 60 * 60)
        case .month:
            return date > Date().addingTimeInterval(-30 * 24 * 60 * 60)
        case .all:
            return true
        }
    }
}
```

## Features

### Core Features

1. **Real-time Updates**: Auto-refresh every 2 seconds while window is open
2. **Search**: Full-text search across event types, details, and states
3. **Filtering**: Filter by event type and date range
4. **Export**: Export filtered results to CSV format
5. **Clear Log**: Remove all log entries with confirmation dialog

### Accessibility

Following the project's accessibility standards:

1. **VoiceOver Support**:

   - All interactive elements have proper labels
   - Table navigation is fully accessible
   - Status updates are announced

2. **Keyboard Navigation**:

   - Tab through all controls
   - Arrow keys navigate table rows
   - Standard shortcuts (Cmd+F for search focus)

3. **High Contrast**:
   - Uses system colors that adapt to appearance
   - Sufficient contrast ratios for all text

### Performance Considerations

1. **Efficient Filtering**: Computed properties for reactive filtering
2. **Pagination**: Initial limit of 1000 entries (configurable)
3. **Lazy Loading**: Table renders only visible rows
4. **Memory Management**: Auto-cleanup on window close

## Implementation Steps

1. **Create View Components**:

   - EventLogView.swift
   - EventLogViewModel.swift
   - EventLogRowView.swift
   - EventLogFilterView.swift

2. **Add Window Controller**:

   - EventLogWindowController.swift

3. **Create Extensions**:

   - EventLogEntry+UI.swift

4. **Update Integration Points**:

   - Modify AppDelegateCore.showEventLog()

5. **Add Tests**:
   - EventLogViewModelTests.swift
   - EventLogFilterTests.swift

## Testing Strategy

### Unit Tests

```swift
// EventLogViewModelTests.swift
@Test("Filter by search text")
func testSearchFilter() {
    let viewModel = EventLogViewModel()
    viewModel.events = createMockEvents()
    viewModel.searchText = "armed"

    #expect(viewModel.filteredEvents.count == 2)
    #expect(viewModel.filteredEvents.allSatisfy {
        $0.event == .armed || $0.event == .disarmed
    })
}
```

### UI Tests

- Test window opening/closing
- Verify table data population
- Test export functionality
- Validate keyboard navigation

## Future Enhancements

1. **Advanced Filtering**:

   - Multiple event type selection
   - Custom date ranges
   - Regex support for search

2. **Analytics View**:

   - Event frequency charts
   - Pattern detection
   - Security action success rates

3. **Log Management**:

   - Log rotation settings
   - Archive old logs
   - Import/export full backups

4. **Notifications**:
   - Alert on specific event patterns
   - Real-time event streaming
   - Integration with system notifications

## Security Considerations

1. **Data Privacy**: No sensitive data in logs (already implemented)
2. **Export Security**: Warn user about sharing exported logs
3. **Memory Safety**: Prevent excessive memory usage with large logs
4. **Access Control**: Logs only accessible to authenticated user

## Conclusion

The Log Viewer provides a powerful yet intuitive interface for monitoring MagSafe Guard's security events. By following the established MVVM-C pattern and SwiftUI best practices, it integrates seamlessly with the existing application while providing room for future enhancements.
