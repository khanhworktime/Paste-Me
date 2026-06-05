//
//  AppTheme.swift
//  PasteMe
//
//  Created by Krist Dev on 21/1/26.
//


import SwiftUI
internal import UniformTypeIdentifiers

struct AppTheme {
    static func color(for bundleID: String?) -> Color {
        guard let id = bundleID?.lowercased() else { return Color.gray }
        
        // Logic mapping màu
        if id.contains("safari") { return Color.blue } // Safari
        if id.contains("chrome") { return Color(red: 0.2, green: 0.6, blue: 0.3) } // Chrome (Xanh lá đậm)
        if id.contains("arc") { return Color(red: 1.0, green: 0.5, blue: 0.5) } // Arc Browser
        if id.contains("notes") || id.contains("bear") { return Color.yellow } // Notes, Bear
        if id.contains("code") || id.contains("xcode") || id.contains("terminal") || id.contains("iterm") { 
            return Color(red: 0.15, green: 0.15, blue: 0.2) // Màu đen tím (Coding)
        }
        if id.contains("slack") || id.contains("discord") || id.contains("telegram") || id.contains("zalo") {
            return Color.purple // Chat App
        }
        if id.contains("figma") || id.contains("photoshop") { return Color.orange } // Design
        
        // Mặc định cho App chưa biết
        return Color.gray.opacity(0.8)
    }
    
    // Hàm phụ trợ để chọn màu chữ trên Header (Nếu nền sáng quá thì chữ đen, nền tối chữ trắng)
    static func textColor(for bundleID: String?) -> Color {
        guard let id = bundleID?.lowercased() else { return .white }
        if id.contains("notes") || id.contains("yellow") { return .black.opacity(0.8) }
        return .white
    }
    
    static func getIcon(for bundleID: String?) -> NSImage {
            // 1. Nếu có Bundle ID, hỏi hệ thống lấy đường dẫn App
            if let id = bundleID,
               let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) {
                // 2. Lấy Icon từ đường dẫn đó
                return NSWorkspace.shared.icon(forFile: url.path)
            }
            
            // 3. Nếu không tìm thấy, trả về icon mặc định của hệ thống
            return NSWorkspace.shared.icon(for: .applicationBundle)
        }
}
