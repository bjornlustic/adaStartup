//
//  adaStartupApp.swift
//  adaStartup
//
//  Created by Bjorn Lustic on 5/9/25.
//

import SwiftUI

@main
struct adaStartupApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            // By providing an EmptyView, we ensure that if the Settings
            // window is ever explicitly opened, it will be blank.
            // Combined with LSUIElement=true in Info.plist and
            // NSApp.setActivationPolicy(.accessory) in AppDelegate,
            // a settings window should not appear automatically.
            EmptyView()
        }
    }
}
