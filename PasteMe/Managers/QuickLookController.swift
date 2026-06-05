import Cocoa
import QuickLookUI

class QuickLookController: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = QuickLookController()
    
    private var panel: QLPreviewPanel?
    private var currentPreviewItem: NSURL?
    
    // Callback báo đóng
    var onPanelClosed: (() -> Void)?
    
    private var mainWindow: NSWindow? {
        return NSApp.windows.first { $0.isVisible && String(describing: type(of: $0)).contains("NSPanel") }
    }
    
    // 👇 HÀM KIỂM TRA TRẠNG THÁI CHUẨN XÁC
    func isPreviewOpen() -> Bool {
        return panel != nil && panel!.isVisible
    }

    func togglePreview(for item: ClipItem) {
        guard let fileURL = prepareTempFile(for: item) else { return }
        self.currentPreviewItem = fileURL as NSURL
        
        if let panel = QLPreviewPanel.shared() {
            self.panel = panel
            panel.dataSource = self
            panel.delegate = self
            
            // Khoá ẩn App chính
            if let mainWin = mainWindow {
                mainWin.hidesOnDeactivate = false
            }
            
            if !panel.isVisible {
                panel.makeKeyAndOrderFront(nil)
            }
            panel.reloadData()
        }
    }
    
    func closePreview() {
        if let panel = QLPreviewPanel.shared(), panel.isVisible {
            panel.close()
            // Logic focus lại sẽ chạy trong windowWillClose
        }
    }
    
    // Delegate xử lý khi đóng
    func windowWillClose(_ notification: Notification) {
        onPanelClosed?()
        
        // Trả lại trạng thái bình thường cho App chính
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            if let mainWin = self.mainWindow {
                mainWin.makeKeyAndOrderFront(nil)
                mainWin.hidesOnDeactivate = true // 👈 Quan trọng: Cho phép ẩn lại khi click ra ngoài
            }
        }
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(windowWillClose(_:)) { return true }
        return super.responds(to: aSelector)
    }
    
    // --- Helper & Data Source ---
    private func prepareTempFile(for item: ClipItem) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Preview.\(item.imageData != nil ? "png" : "txt")"
        let fileURL = tempDir.appendingPathComponent(fileName)
        do {
            if let imgData = item.imageData { try imgData.write(to: fileURL) }
            else if let text = item.content { try text.data(using: .utf8)?.write(to: fileURL) }
            return fileURL
        } catch { return nil }
    }
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int { return currentPreviewItem != nil ? 1 : 0 }
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! { return currentPreviewItem }
    func previewPanel(_ panel: QLPreviewPanel!, sourceFrameOnScreenFor item: QLPreviewItem!) -> NSRect { return .zero }
}
