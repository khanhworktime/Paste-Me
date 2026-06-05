//
//  ClipboardManager.swift
//  PasteMe
//
//  Created by Krist Dev on 20/1/26.
//

import SwiftUI
import Combine

class ClipboardManager: ObservableObject {
    private var timer: AnyCancellable?
    private var lastChangeCount: Int
    
    // Cache to prevent duplicates
    private var lastCapturedContent: String?
    private var lastCapturedImage: Data?
    private var lastCapturedFiles: [String]?
    
    // Callback to AppDelegate when new item detected
    // Updated signature to include file data
    var onNewItemDetected: ((
        _ content: String?,
        _ image: Data?,
        _ type: String,
        _ appName: String?,
        _ bundleID: String?,
        _ fileURLs: [String]?,
        _ fileName: String?,
        _ fileIcon: Data?,
        _ urlTitle: String?,
        _ urlFavicon: Data?,
        _ urlPreviewImage: Data?
    ) -> Void)?
    
    init() {
        self.lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
    }
    
    func startMonitoring() {
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if NSPasteboard.general.changeCount != self.lastChangeCount {
                    self.lastChangeCount = NSPasteboard.general.changeCount
                    self.checkClipboard()
                }
            }
    }
    
    private func checkClipboard() {
        let pb = NSPasteboard.general
        
        // Get frontmost app info
        let frontApp = NSWorkspace.shared.frontmostApplication
        let appName = frontApp?.localizedName
        let bundleID = frontApp?.bundleIdentifier
        
        // 0. Check Ignored Apps
        let ignoredAppsString = UserDefaults.standard.string(forKey: "ignoredApps") ?? "1Password,Keychain Access,Bitwarden"
        let ignoredApps = ignoredAppsString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        
        if let name = appName, ignoredApps.contains(name) {
            return
        }
        
        // 1. Check Files first (highest priority)
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
           !urls.isEmpty {
            let paths = urls.map { $0.path }
            
            // Prevent duplicate
            if paths == lastCapturedFiles {
                return
            }
            
            lastCapturedFiles = paths
            lastCapturedContent = nil
            lastCapturedImage = nil
            
            // Generate display name
            let fileName: String
            if urls.count == 1 {
                fileName = urls[0].lastPathComponent
            } else {
                fileName = "\(urls.count) files"
            }
            
            // Get file icon (use first file's icon)
            var iconData: Data? = nil
            let icon = NSWorkspace.shared.icon(forFile: paths[0])
            if let tiff = icon.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let png = bitmap.representation(using: .png, properties: [:]) {
                iconData = png
            }
            
            
            onNewItemDetected?(nil, nil, "file", appName, bundleID, paths, fileName, iconData, nil, nil, nil)
            playSoundIfNeeded()
            return
        }
        
        // 2. Check Images
        if pb.canReadItem(withDataConformingToTypes: ["public.image"]),
           let img = NSImage(pasteboard: pb),
           let tiff = img.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let png = bitmap.representation(using: .png, properties: [:]) {
            
            if let lastImg = lastCapturedImage, lastImg == png {
                return
            }
            
            lastCapturedImage = png
            lastCapturedContent = nil
            lastCapturedFiles = nil
            
            onNewItemDetected?(nil, png, "image", appName, bundleID, nil, nil, nil, nil, nil, nil)
            playSoundIfNeeded()
            return
        }
        
        // 3. Check Text & URLs
        if let text = pb.string(forType: .string), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            
            if text == self.lastCapturedContent {
                return
            }
            
            lastCapturedContent = text
            lastCapturedImage = nil
            lastCapturedFiles = nil
            
            // Detect URL
            // Simple check: starts with http/https and can be initialized as URL
            let isURL = (text.hasPrefix("http://") || text.hasPrefix("https://")) && URL(string: text) != nil
            
            // We only set type = "url" here. Metadata fetching happens in AppDelegate/Model layer
            // to prevent blocking the detection loop.
            let type = isURL ? "url" : "text"
            
            onNewItemDetected?(
                text,       // content
                nil,        // image
                type,       // type
                appName,    // appName
                bundleID,   // bundleID
                nil,        // fileURLs
                nil,        // fileName
                nil,        // fileIcon
                nil,        // urlTitle (fetched later)
                nil,        // urlFavicon (fetched later)
                nil         // urlOther (fetched later)
            )
            playSoundIfNeeded()
        }
    }
    
    private func playSoundIfNeeded() {
        if UserDefaults.standard.bool(forKey: "playSoundOnCopy") {
            NSSound(named: "Glass")?.play()
        }
    }
}

