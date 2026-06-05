//
//  PasteMeApp.swift
//  PasteMe
//
//  Created by Krist Dev on 20/1/26.
//
import SwiftUI

@main
struct PasteMeApp: App {
    // Kết nối bộ não AppDelegate vào đây
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
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
