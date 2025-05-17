import SwiftUI
import AppKit

class StatusBarController {
    private var statusItem: NSStatusItem
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
        
        let quitMenuItem = NSMenuItem(title: "Quit adaStartup", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitMenuItem)
        
        return menu
    }
} 
