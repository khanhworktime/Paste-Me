//
//  HotKeyManager.swift
//  PasteMe
//
//  Created by Krist Dev on 20/1/26.
//


import Cocoa
import Carbon

class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    var onHotKeyPushed: (() -> Void)?
    
    init() {
        registerHotKey()
    }
    
    func registerHotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(1196647243) // 'MYHK'
        hotKeyID.id = 1
        
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        // Cài đặt Handler
        InstallEventHandler(GetApplicationEventTarget(), { (_, _, userData) -> OSStatus in
            let mySelf = Unmanaged<HotKeyManager>.fromOpaque(userData!).takeUnretainedValue()
            DispatchQueue.main.async {
                mySelf.onHotKeyPushed?()
            }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)
        
        // Đăng ký phím: V (0x09) + Shift + Cmd
        let keyCode: UInt32 = 0x09
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
    
    deinit {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
    }
}