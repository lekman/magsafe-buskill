//
//  ResourcePreloader.swift
//  MagSafe Guard
//
//  Preloads critical resources for faster startup
//

import AppKit

/// Preloads critical resources during app initialization
public class ResourcePreloader {
    public static let shared = ResourcePreloader()

    private var preloadedIcons: [String: NSImage] = [:]
    private let iconNames = [
        "shield.fill",
        "shield",
        "shield.slash.fill",
        "exclamationmark.shield.fill",
        "lock.shield",
        "lock.shield.fill"
    ]

    private init() {}

    /// Preload all critical resources
    public func preloadResources() {
        preloadMenuBarIcons()
    }

    /// Preload menu bar icons
    private func preloadMenuBarIcons() {
        for iconName in iconNames {
            if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "MagSafe Guard") {
                // Create a copy and set as template
                if let templateImage = image.copy() as? NSImage {
                    templateImage.isTemplate = true
                    templateImage.size = NSSize(width: 18, height: 18)
                    preloadedIcons[iconName] = templateImage
                }
            }
        }

        Log.debug("Preloaded \(preloadedIcons.count) icons", category: .general)
    }

    /// Get a preloaded icon by name
    public func getIcon(named name: String) -> NSImage? {
        return preloadedIcons[name]
    }

    /// Get the default shield icon
    public func getDefaultIcon() -> NSImage? {
        return getIcon(named: "shield.fill") ?? getIcon(named: "shield")
    }
}
