import Cocoa
import SwiftUI
import SwiftData
import LinkPresentation

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    static var shared: AppDelegate?

    var panel: FloatingPanel!
    var hotKeyManager: HotKeyManager?
    var clipboardManager: ClipboardManager?
    var modelContainer: ModelContainer?
    
    // Quản lý cửa sổ con
    var settingsWindow: NSWindow?
    var previewPanel: NSPanel?
    var statusItem: NSStatusItem!
    var lastTheme: String = ""

    override init() {
           super.init()
           Self.shared = self
       }

    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Check quyền
        checkAccessibility()
        
        // 2. Setup Database
        let schema = Schema([ClipItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("ModelContainer initialization failed (likely schema change), wiping database: \(error)")
            let url = config.url
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(atPath: url.path + "-shm")
            try? FileManager.default.removeItem(atPath: url.path + "-wal")
            modelContainer = try! ModelContainer(for: schema, configurations: [config])
        }
        
        // 3. Setup Clipboard Manager
        clipboardManager = ClipboardManager()
        clipboardManager?.onNewItemDetected = { [weak self] content, image, type, appName, bundleID, fileURLs, fileName, fileIcon, urlTitle, urlFavicon, urlPreviewImage in
            self?.saveItem(
                content: content, 
                image: image, 
                type: type, 
                appName: appName, 
                bundleID: bundleID, 
                fileURLs: fileURLs, 
                fileName: fileName, 
                fileIcon: fileIcon,
                urlTitle: urlTitle,
                urlFavicon: urlFavicon,
                urlPreviewImage: urlPreviewImage
            )
        }

        // 4. Setup Panel
        // Khởi tạo với frame an toàn ban đầu (tránh lỗi 0x0 hoặc invalid)
        panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 350),
            backing: .buffered,
            defer: false
        )
        panel.delegate = self
        
        let contentView = ContentView()
            .modelContainer(modelContainer!)
            
        panel.contentView = NSHostingView(rootView: contentView)
        
        // 5. Setup khác
        setupStatusBar()
        centerWindow()
        setupHotKey()
    }
    
    // --- CÁC HÀM QUẢN LÝ CỬA SỔ (ĐÃ FIX LỖI FRAME) ---
    
    func showWindowWithAnimation() {
        // 1. Lấy màn hình tại vị trí chuột
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main ?? NSScreen.screens.first!
        
        let screenRect = targetScreen.visibleFrame
        
        // 2. TÍNH TOÁN AN TOÀN (FIX LỖI INVALID FRAME)
        // Đảm bảo chiều rộng > 0 (Lấy width màn hình - 60px, tối thiểu 200px)
        let panelWidth = max(200, screenRect.width - 60)
        let panelHeight: CGFloat = 350
        
        // Tính toạ độ
        let targetX = screenRect.origin.x + (screenRect.width - panelWidth) / 2
        let targetY = screenRect.origin.y + 20 // Đích (cách đáy 20px)
        let startY = targetY - 50              // Xuất phát (thấp hơn)
        
        // Tạo Rect
        let startRect = NSRect(x: targetX, y: startY, width: panelWidth, height: panelHeight)
        let targetRect = NSRect(x: targetX, y: targetY, width: panelWidth, height: panelHeight)
        
        // 3. APPLY FRAME (Chỉ khi frame hợp lệ)
        if startRect.width > 0 && startRect.height > 0 {
            panel.setFrame(startRect, display: true)
        } else {
            // Fallback nếu tính toán sai: Đặt về giữa màn hình chính
            panel.center()
        }
        
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        
        // Reset Focus để tránh search bar tự focus
        panel.makeFirstResponder(nil)
        
        NSApp.activate(ignoringOtherApps: true)
        
        // 4. ANIMATION
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1)
            
            panel.animator().setFrame(targetRect, display: true)
            panel.animator().alphaValue = 1
        }
    }
    
    func toggleWindow() {
        // Logic chuyển màn hình
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main!
        
        if panel.isVisible {
            if panel.screen == targetScreen {
                closeWindow()
            } else {
                panel.alphaValue = 0
                showWindowWithAnimation()
            }
        } else {
            showWindowWithAnimation()
        }
    }
    
    func closeWindow() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 0
        } completionHandler: {
            self.panel.orderOut(nil)
        }
    }
    
    
    // --- STATUS BAR & MENU ---
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let icon = NSImage(named: "MenuBarIcon") {
                icon.isTemplate = true
                button.image = icon
            } else {
                button.image = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "PasteMe")
            }
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open History", action: #selector(openAppFromMenu), keyEquivalent: "v"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
        
        // Register defaults
        UserDefaults.standard.register(defaults: [
            "historyLimit": 100,
            "autoClearDays": 30,
            "showMenuBarIcon": true,
            "playSoundOnCopy": false,
            "appTheme": "system",
            "pasteAsPlainText": false
        ])
        
        statusItem.isVisible = UserDefaults.standard.bool(forKey: "showMenuBarIcon")
        
        // Observe explicit notifications from SettingsView
        NotificationCenter.default.addObserver(forName: NSNotification.Name("MenuBarIconChanged"), object: nil, queue: .main) { [weak self] _ in
            self?.statusItem.isVisible = UserDefaults.standard.bool(forKey: "showMenuBarIcon")
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("AppThemeChanged"), object: nil, queue: .main) { [weak self] _ in
            self?.applyTheme()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("HotkeyChanged"), object: nil, queue: .main) { [weak self] _ in
            self?.hotKeyManager?.updateHotKey()
        }
        applyTheme()
    }
    
    func applyTheme() {
        let theme = UserDefaults.standard.string(forKey: "appTheme") ?? "system"
        let appearance: NSAppearance?
        switch theme {
        case "light": appearance = NSAppearance(named: .aqua)
        case "dark": appearance = NSAppearance(named: .darkAqua)
        default: appearance = nil // System default
        }
        
        panel.appearance = appearance
        settingsWindow?.appearance = appearance
    }
    
    @MainActor
    @objc func openAppFromMenu() {
        // Khi mở từ menu, ta muốn nó hiện ở màn hình chính hoặc màn hình có chuột
        toggleWindow()
    }
    
    @MainActor
    @objc func openSettings() {
        // 1. Nếu cửa sổ đã tồn tại -> Focus vào nó luôn và return
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // 2. Nếu chưa -> Tạo mới
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 450),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // 3. Cấu hình
        window.center()
        window.setFrameAutosaveName("Settings")
        window.title = "Settings"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        
        window.delegate = self
        
        // Apply current theme
        let theme = UserDefaults.standard.string(forKey: "appTheme") ?? "system"
        switch theme {
        case "light": window.appearance = NSAppearance(named: .aqua)
        case "dark": window.appearance = NSAppearance(named: .darkAqua)
        default: window.appearance = nil
        }
        
        let hostingView: NSHostingView<AnyView>
        if let mainContext = self.modelContainer?.mainContext {
            hostingView = NSHostingView(rootView: AnyView(SettingsView().modelContext(mainContext)))
        } else {
            hostingView = NSHostingView(rootView: AnyView(SettingsView()))
        }
        
        window.contentView = hostingView
        
        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
        
        
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    // --- HELPER LOGIC ---
    func saveItem(
        content: String?, 
        image: Data?, 
        type: String, 
        appName: String?, 
        bundleID: String?, 
        fileURLs: [String]? = nil, 
        fileName: String? = nil, 
        fileIcon: Data? = nil,
        urlTitle: String? = nil,
        urlFavicon: Data? = nil,
        urlPreviewImage: Data? = nil
    ) {
        Task { @MainActor in
            guard let container = modelContainer else { return }
            let context = container.mainContext
            let newItem = ClipItem(
                content: content,
                imageData: image,
                type: type,
                sourceApp: appName,
                sourceBundleID: bundleID,
                fileURLs: fileURLs,
                fileName: fileName,
                fileIcon: fileIcon,
                urlTitle: urlTitle,
                urlFavicon: urlFavicon,
                urlPreviewImage: urlPreviewImage
            )
            context.insert(newItem)
            
            do {
                let descriptor = FetchDescriptor<ClipItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
                let allItems = try context.fetch(descriptor)
                
                // Enforce History Limit
                let historyLimit = UserDefaults.standard.integer(forKey: "historyLimit")
                let limit = historyLimit == 0 ? Int.max : historyLimit // 0 means Unlimited
                if allItems.count > limit {
                    for item in allItems.suffix(from: limit) { context.delete(item) }
                }
                
                // Enforce Auto-Clear
                let autoClearDays = UserDefaults.standard.integer(forKey: "autoClearDays")
                if autoClearDays > 0, let cutoffDate = Calendar.current.date(byAdding: .day, value: -autoClearDays, to: Date()) {
                    for item in allItems where item.createdAt < cutoffDate {
                        context.delete(item)
                    }
                }
                
                try context.save()
            } catch { print("DB Error: \(error)") }
            
            // Async Metadata Fetching for URLs
            if type == "url", let urlString = content, let url = URL(string: urlString) {
                // Fetch metadata in background
                Task.detached {
                    let provider = LPMetadataProvider()
                    do {
                        let metadata = try await provider.startFetchingMetadata(for: url)
                        
                        // Process metadata
                        let title = metadata.title
                        var iconData: Data?
                        var previewImage: Data?
                        
                        // Get Icon (Favicon equivalent)
                        if let iconProvider = metadata.iconProvider {
                            iconData = await self.loadData(from: iconProvider)
                        }
                        
                        // Get Image (OG Image)
                        if let imageProvider = metadata.imageProvider {
                            previewImage = await self.loadData(from: imageProvider)
                        }
                        
                        // Update Item on MainActor
                        await self.updateItemMetadata(itemID: newItem.id, title: title, icon: iconData, image: previewImage)
                        
                    } catch {
                        print("Failed to fetch metadata for \(url): \(error)")
                    }
                }
            }
        }
    }
    
    // Helper to load data from NSItemProvider
    func loadData(from provider: NSItemProvider) async -> Data? {
        return await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, _ in
                continuation.resume(returning: data)
            }
        }
    }
    
    // Helper to update item
    @MainActor
    func updateItemMetadata(itemID: UUID, title: String?, icon: Data?, image: Data?) {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        let descriptor = FetchDescriptor<ClipItem>(predicate: #Predicate { $0.id == itemID })
        
        do {
            if let item = try context.fetch(descriptor).first {
                item.urlTitle = title
                item.urlFavicon = icon
                item.urlPreviewImage = image
                try context.save()
            }
        } catch {
            print("Failed to update item metadata: \(error)")
        }
    }
    
    func centerWindow() {
        // Hàm này chỉ để set vị trí ban đầu an toàn
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - 400
            let y = screenRect.minY + 20
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    func setupHotKey() {
        hotKeyManager = HotKeyManager()
        hotKeyManager?.onHotKeyPushed = { [weak self] in
            DispatchQueue.main.async {
                self?.toggleWindow()
            }
        }
        
        hotKeyManager?.onClearHistoryPushed = { [weak self] in
            Task { @MainActor in
                guard let context = self?.modelContainer?.mainContext else { return }
                do {
                    try context.delete(model: ClipItem.self)
                    try context.save()
                } catch {
                    print("Failed to clear history via hotkey: \(error)")
                }
            }
        }
    }
    
    func checkAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // --- DELEGATE HANDLERS ---
    func windowDidResignKey(_ notification: Notification) {
        // Kiểm tra xem sự kiện này có phải từ Panel chính của mình không
        if let window = notification.object as? FloatingPanel, window == self.panel {
            
            // QUAN TRỌNG: Nếu QuickLook đang mở thì ĐỪNG đóng Panel (vì focus chuyển sang QuickLook)
            if QuickLookController.shared.isPreviewOpen() { return }
            
            // Nếu không phải do QuickLook, thì ẩn cửa sổ đi
            if panel.isVisible {
                closeWindow()
            }
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        // Reset biến về nil để lần sau mở lại sẽ tạo cửa sổ mới (hoặc load lại state)
        if let window = notification.object as? NSWindow, window == settingsWindow {
            self.settingsWindow = nil
        }
    }
}
