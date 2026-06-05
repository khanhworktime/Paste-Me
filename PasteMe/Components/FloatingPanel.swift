//
//  FloatingPanel.swift
//  PasteMe
//
//  Created by Krist Dev on 20/1/26.
//


import Cocoa

class FloatingPanel: NSPanel {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        // 1. Khởi tạo với Style "Không viền" (Borderless) nhưng vẫn xử lý sự kiện
        super.init(contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel], backing: backing, defer: flag)
        
        // 2. Cấu hình quan trọng để tránh lỗi "Window Frame Failed"
        self.isFloatingPanel = true
        self.level = .floating // Luôn nổi trên cùng
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // 3. Tắt tính năng tự động lưu vị trí (Nguyên nhân gây lỗi cũ)
        self.isRestorable = false 
        self.setFrameAutosaveName("") 
        
        // 4. Giao diện trong suốt
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false 
    }
    
    // 5. Cho phép nhận phím bấm (để sau này gõ tìm kiếm) dù không có viền
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
}