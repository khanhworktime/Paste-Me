//
//  PasteMeApp.swift
//  PasteMe
//
//  Created by Krist Dev on 20/1/26.
//
import SwiftUI
import SwiftData

@main
struct PasteMeApp: App {
    // Kết nối bộ não AppDelegate vào đây
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Since this is a menu bar extra app, we do not use native Settings scene,
        // we use a custom NSWindow in AppDelegate.
        MenuBarExtra("PasteMe", systemImage: "paperclip") {
            // Note: MenuBar is manually constructed in AppDelegate,
            // so we can leave this mostly empty or define it in AppDelegate.
        }
        .commands {
            // Thêm menu vào thanh hệ thống
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    // Gọi update từ Menu Bar
                    // (Cần truy cập Updater trong Settings hoặc tạo instance riêng)
                }
                Button("Preferences...") {
                    AppDelegate.shared?.openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
