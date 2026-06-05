//
//  HotKeyManager.swift
//  PasteMe
//
//  Created by Krist Dev on 20/1/26.
//


import Cocoa
import Carbon

class HotKeyManager {
    private var toggleHotKeyRef: EventHotKeyRef?
    private var clearHistoryHotKeyRef: EventHotKeyRef?
    
    var onHotKeyPushed: (() -> Void)?
    var onClearHistoryPushed: (() -> Void)?
    private var handlerInstalled = false
    
    init() {
        registerHotKeys()
    }
    
    func updateHotKey() {
        registerHotKeys()
    }
    
    private func registerHotKeys() {
        if let ref = toggleHotKeyRef { UnregisterEventHotKey(ref); toggleHotKeyRef = nil }
        if let ref = clearHistoryHotKeyRef { UnregisterEventHotKey(ref); clearHistoryHotKeyRef = nil }
        
        let toggleIndex = UserDefaults.standard.integer(forKey: "toggleHotkeyIndex")
        let clearIndex = UserDefaults.standard.integer(forKey: "clearHistoryHotkeyIndex")
        
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        if !handlerInstalled {
            InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                GetEventParameter(theEvent, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
                
                let mySelf = Unmanaged<HotKeyManager>.fromOpaque(userData!).takeUnretainedValue()
                DispatchQueue.main.async {
                    if hotKeyID.id == 1 {
                        mySelf.onHotKeyPushed?()
                    } else if hotKeyID.id == 2 {
                        mySelf.onClearHistoryPushed?()
                    }
                }
                return noErr
            }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)
            handlerInstalled = true
        }
        
        // 1. Register Toggle Panel Hotkey
        var toggleModifiers: UInt32 = UInt32(cmdKey | shiftKey)
        switch toggleIndex {
        case 1: toggleModifiers = UInt32(optionKey)
        case 2: toggleModifiers = UInt32(cmdKey | optionKey)
        case 3: toggleModifiers = UInt32(cmdKey | controlKey)
        default: toggleModifiers = UInt32(cmdKey | shiftKey)
        }
        var toggleID = EventHotKeyID()
        toggleID.signature = OSType(1196647243) // 'MYHK'
        toggleID.id = 1
        RegisterEventHotKey(0x09, toggleModifiers, toggleID, GetApplicationEventTarget(), 0, &toggleHotKeyRef) // 0x09 = 'V'
        
        // 2. Register Clear History Hotkey
        if clearIndex > 0 {
            var clearModifiers: UInt32 = 0
            var clearKeyCode: UInt32 = 0x33 // 0x33 = 'Delete'
            switch clearIndex {
            case 1: clearModifiers = UInt32(cmdKey | shiftKey)
            case 2: clearModifiers = UInt32(cmdKey | optionKey)
            case 3: clearModifiers = UInt32(cmdKey | controlKey)
            default: break
            }
            
            var clearID = EventHotKeyID()
            clearID.signature = OSType(1196647243) // 'MYHK'
            clearID.id = 2
            RegisterEventHotKey(clearKeyCode, clearModifiers, clearID, GetApplicationEventTarget(), 0, &clearHistoryHotKeyRef)
        }
    }
    
    deinit {
        if let ref = toggleHotKeyRef { UnregisterEventHotKey(ref) }
        if let ref = clearHistoryHotKeyRef { UnregisterEventHotKey(ref) }
    }
}