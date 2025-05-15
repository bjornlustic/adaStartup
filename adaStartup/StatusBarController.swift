import SwiftUI
import AppKit

class StatusBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover?
    private var onStatusItemClicked: () -> Void
    
    init(onStatusItemClicked: @escaping () -> Void) {
        self.onStatusItemClicked = onStatusItemClicked
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(named: "MenuBarIcon")
            
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(handleStatusItemClick(_:))
            button.target = self
        }
    }
    
    @objc private func handleStatusItemClick(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            constructMenu().popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        } else if event.type == .leftMouseUp {
            onStatusItemClicked()
        }
    }
    
    private func constructMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }
    
    // The closePopover method is no longer needed as there's no popover.
    // We can remove it or leave it if it might be repurposed later, but for now, it's unused.
    // func closePopover() { }
} 
