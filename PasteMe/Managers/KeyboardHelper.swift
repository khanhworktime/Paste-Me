//
//  KeyboardHelper.swift
//  PasteMe
//
//  Created by Krist Dev on 20/1/26.
//


import Cocoa
import Carbon

class KeyboardHelper {
    static func pasteToActiveApp() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        
        // Phím V (code 0x09)
        let keyV: CGKeyCode = 0x09
        let commandFlag = CGEventFlags.maskCommand
        
        guard let eventDown = CGEvent(keyboardEventSource: source, virtualKey: keyV, keyDown: true),
              let eventUp = CGEvent(keyboardEventSource: source, virtualKey: keyV, keyDown: false) else { return }
        
        eventDown.flags = commandFlag
        eventUp.flags = commandFlag
        
        // Gửi lệnh
        eventDown.post(tap: .cghidEventTap)
        usleep(2000) // Nghỉ cực ngắn
        eventUp.post(tap: .cghidEventTap)
    }
}
