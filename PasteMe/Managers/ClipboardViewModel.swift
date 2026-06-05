import SwiftUI
import SwiftData
import Combine

@MainActor
class ClipboardViewModel: ObservableObject {
    // --- STATE (Trạng thái) ---
    @Published var searchText: String = ""
    @Published var debouncedSearchText: String = ""
    @Published var selectedItemId: ClipItem.ID?
    @Published var isSearchFocused: Bool = false
    
    // --- DEPENDENCIES ---
    private var modelContext: ModelContext?
    
    // Hàm này được gọi trong .onAppear của View để lấy context
    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // --- LOGIC FILTER ---
    // Lọc danh sách dựa trên từ khoá đã debounce
    func getFilteredItems(from items: [ClipItem]) -> [ClipItem] {
        if debouncedSearchText.isEmpty { return items }
        return items.filter { item in
            let contentMatch = item.content?.localizedCaseInsensitiveContains(debouncedSearchText) ?? false
            let appMatch = item.sourceApp?.localizedCaseInsensitiveContains(debouncedSearchText) ?? false
            return contentMatch || appMatch
        }
    }
    
    // --- ACTIONS (Hành động) ---
    
    // Xử lý Debounce: Chỉ search khi user dừng gõ 0.3s
    func runSearchDebounce() async {
        do {
            // Nếu có ký tự mới gõ vào, task cũ sẽ bị huỷ, task mới chờ 0.3s
            try await Task.sleep(nanoseconds: 300_000_000)
            debouncedSearchText = searchText
            
            // Khi search thay đổi, reset selection để tránh lỗi UI
            selectedItemId = nil
        } catch {
            // Task bị huỷ (do người dùng gõ tiếp), không làm gì cả
        }
    }
    
    func deleteItem(_ item: ClipItem) {
        modelContext?.delete(item)
        try? modelContext?.save()
    }
    
    func clearAllItems() {
        do {
            try modelContext?.delete(model: ClipItem.self)
            try? modelContext?.save()
        } catch {
            print("Failed to clear all items: \(error)")
        }
    }
    
    func pasteAndHide(_ item: ClipItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        
        if item.typeRaw == "file", let paths = item.fileURLs {
            // Write file URLs back to pasteboard
            let urls = paths.compactMap { URL(fileURLWithPath: $0) as NSURL }
            pb.writeObjects(urls)
        } else if let imgData = item.imageData, item.typeRaw == "image" {
            let pbItem = NSPasteboardItem()
            pbItem.setData(imgData, forType: .png)
            pb.writeObjects([pbItem])
        } else if let content = item.content {
            pb.setString(content, forType: .string)
        }
        
        NSApp.hide(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            KeyboardHelper.pasteToActiveApp()
        }
    }
    
    // Logic di chuyển vùng chọn bằng phím mũi tên
    func moveSelection(direction: Int, in items: [ClipItem]) {
        guard !items.isEmpty else { return }
        
        // Tìm vị trí hiện tại
        let currentIndex = items.firstIndex(where: { $0.id == selectedItemId }) ?? 0
        var newIndex = currentIndex + direction
        
        // Giới hạn không cho vượt quá danh sách
        if newIndex < 0 { newIndex = 0 }
        if newIndex >= items.count { newIndex = items.count - 1 }
        
        selectedItemId = items[newIndex].id
    }
}
