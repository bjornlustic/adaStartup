import SwiftUI
import AppKit

class StatusBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    
    init<Content: View>(@ViewBuilder content: @escaping () -> Content) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 260)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: content())
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Startup Sounds")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                // Show popover relative to the button
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.becomeKey()
            }
        }
    }
} 