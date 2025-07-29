//
//  AccessibilityExtensions.swift
//  MagSafe Guard
//
//  Created on 2025-07-27.
//

import AppKit
import SwiftUI

// MARK: - NSWorkspace Extensions

extension NSWorkspace {
    /// Whether VoiceOver is currently enabled.
    var isVoiceOverEnabled: Bool {
        return NSApplication.shared.isVoiceOverEnabled
    }
}

extension NSApplication {
    /// Whether VoiceOver is currently enabled.
    var isVoiceOverEnabled: Bool {
        return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast ||
               UserDefaults.standard.bool(forKey: "com.apple.VoiceOver.Enabled")
    }
}

// MARK: - NSMenuItem Extensions

extension NSMenuItem {
    /// Configures accessibility properties for the menu item.
    ///
    /// - Parameters:
    ///   - label: Accessibility label for screen readers
    ///   - hint: Additional context for the action
    ///   - shortcut: Keyboard shortcut description
    func configureAccessibility(label: String, hint: String? = nil, shortcut: String? = nil) {
        // Set accessibility properties directly on NSMenuItem
        setAccessibilityLabel(label)

        if let hint = hint {
            setAccessibilityHelp(hint)
        }

        // Combine shortcut with hint if available
        if let shortcut = shortcut {
            let fullHint = hint != nil ? "\(hint!). Keyboard shortcut: \(shortcut)" : "Keyboard shortcut: \(shortcut)"
            setAccessibilityHelp(fullHint)
        }

        // Make sure the element is accessible
        setAccessibilityRole(.menuItem)
    }

    /// Creates a menu item with proper accessibility configuration.
    ///
    /// - Parameters:
    ///   - title: The visible title of the menu item
    ///   - accessibilityLabel: Label for screen readers (defaults to title)
    ///   - hint: Additional context for the action
    ///   - keyEquivalent: Keyboard shortcut
    ///   - action: The action to perform
    ///   - target: The target for the action
    /// - Returns: Configured NSMenuItem
    static func accessibleMenuItem(
        title: String,
        accessibilityLabel: String? = nil,
        hint: String? = nil,
        keyEquivalent: String = "",
        action: Selector? = nil,
        target: AnyObject? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = target

        let label = accessibilityLabel ?? title
        let shortcutDescription = keyEquivalent.isEmpty ? nil : "Command+\(keyEquivalent.uppercased())"

        item.configureAccessibility(
            label: label,
            hint: hint,
            shortcut: shortcutDescription
        )

        return item
    }
}

// MARK: - NSMenu Extensions

extension NSMenu {
    /// Configures accessibility properties for the menu.
    ///
    /// - Parameters:
    ///   - title: Accessibility title for the menu
    ///   - description: Description of the menu's purpose
    func configureAccessibility(title: String, description: String? = nil) {
        // Set accessibility properties directly on NSMenu
        setAccessibilityLabel(title)

        if let description = description {
            setAccessibilityHelp(description)
        }

        setAccessibilityRole(.menu)
    }
}

// MARK: - NSWindow Extensions

extension NSWindow {
    /// Configures accessibility properties for the window.
    ///
    /// - Parameters:
    ///   - title: Accessibility title for the window
    ///   - description: Description of the window's purpose
    func configureAccessibility(title: String, description: String? = nil) {
        // Set window accessibility properties
        setAccessibilityLabel(title)

        if let description = description {
            setAccessibilityHelp(description)
        }

        setAccessibilityRole(.window)

        // Ensure proper focus management
        makeFirstResponder(contentView)
    }

    /// Sets up keyboard navigation for the window.
    func setupKeyboardNavigation() {
        // Enable full keyboard access
        if let contentView = contentView {
            contentView.nextKeyView = contentView.subviews.first
        }

        // Setup tab order for subviews
        setupTabOrder()
    }

    private func setupTabOrder() {
        guard let contentView = contentView else { return }

        let focusableViews = contentView.subviews.compactMap { view -> NSView? in
            // Check if view can become first responder or has focusable subviews
            if view.canBecomeKeyView || view.acceptsFirstResponder {
                return view
            }
            return nil
        }

        // Chain the views together for tab navigation
        for (index, view) in focusableViews.enumerated() {
            let nextIndex = (index + 1) % focusableViews.count
            view.nextKeyView = focusableViews[nextIndex]
        }
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Adds comprehensive accessibility support to a SwiftUI view.
    ///
    /// - Parameters:
    ///   - label: Accessibility label for screen readers
    ///   - hint: Additional context about the view's purpose
    ///   - value: Current value for controls (e.g., "Selected" for toggles)
    ///   - traits: Accessibility traits describing the view's behavior
    /// - Returns: Modified view with accessibility properties
    func accessibilityConfiguration(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
    }

    /// Configures the view for VoiceOver navigation.
    ///
    /// - Parameters:
    ///   - isImportant: Whether this view should be prioritized by VoiceOver
    ///   - sortPriority: Navigation order priority (higher values come first)
    /// - Returns: Modified view with VoiceOver configuration
    func voiceOverConfiguration(
        isImportant: Bool = true,
        sortPriority: Double = 0
    ) -> some View {
        self
            .accessibilityElement(children: .contain)
            .accessibilitySortPriority(sortPriority)
            .when(!isImportant) { view in
                view.accessibilityHidden(true)
            }
    }

    /// Configures keyboard navigation for the view.
    ///
    /// - Parameters:
    ///   - isKeyboardFocusable: Whether the view can receive keyboard focus
    /// - Returns: Modified view with keyboard navigation
    func keyboardNavigation(isKeyboardFocusable: Bool = true) -> some View {
        self.focusable(isKeyboardFocusable)
    }

    /// Applies high contrast styling when enabled.
    ///
    /// - Parameter highContrastContent: Alternative content for high contrast mode
    /// - Returns: Modified view with high contrast support
    func highContrastAdaptive<HighContrastContent: View>(
        @ViewBuilder highContrastContent: @escaping () -> HighContrastContent
    ) -> some View {
        Group {
            if AccessibilityManager.shared.isHighContrastEnabled {
                highContrastContent()
            } else {
                self
            }
        }
    }
}

// MARK: - Conditional View Modifier

extension View {
    /// Conditionally applies a view modifier.
    ///
    /// - Parameters:
    ///   - condition: Whether to apply the modifier
    ///   - transform: The modifier to apply
    /// - Returns: Modified view if condition is true, otherwise original view
    @ViewBuilder
    func when<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Accessibility Announcement Helper

/// Helper struct for posting VoiceOver announcements and accessibility notifications.
public struct AccessibilityAnnouncement {
    /// Posts an accessibility announcement that will be read by VoiceOver.
    ///
    /// - Parameters:
    ///   - message: The message to announce
    ///   - priority: The priority of the announcement
    public static func announce(_ message: String, priority: NSAccessibilityPriorityLevel = .medium) {
        guard AccessibilityManager.shared.isVoiceOverEnabled else { return }

        DispatchQueue.main.async {
            NSAccessibility.post(
                element: NSApplication.shared,
                notification: .announcementRequested,
                userInfo: [
                    .announcement: message,
                    .priority: priority.rawValue
                ]
            )
        }
    }

    /// Announces a state change in the application.
    ///
    /// - Parameters:
    ///   - component: The component that changed
    ///   - newState: The new state
    public static func announceStateChange(component: String, newState: String) {
        let message = "\(component) is now \(newState)"
        announce(message, priority: .high)
    }

    /// Announces an error or alert.
    ///
    /// - Parameter message: The error message to announce
    public static func announceAlert(_ message: String) {
        announce("Alert: \(message)", priority: .high)
    }
}
