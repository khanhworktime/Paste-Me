import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    
    // 👇 FIX LỖI: Cú pháp chuẩn của SwiftData cho việc sort
    @Query(sort: [SortDescriptor(\ClipItem.createdAt, order: .reverse)]) private var items: [ClipItem]
    
    // Sử dụng ViewModel để tách biệt logic (Bạn cần đảm bảo đã tạo file ClipboardViewModel.swift)
    @StateObject private var vm = ClipboardViewModel()
    
    // Quản lý focus của ô tìm kiếm
    @FocusState private var isSearchFocused: Bool
    
    // 👇 THÊM: Biến trạng thái để kiểm soát việc Preview có được phép hiện hay không
    @State private var isQuickLookActive = false
    
    // Lấy danh sách đã lọc từ ViewModel
    var filteredItems: [ClipItem] {
        vm.getFilteredItems(from: items)
    }
    
    var body: some View {
        ZStack {
            // Nền kính mờ
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .edgesIgnoringSafeArea(.all)
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .onTapGesture { isSearchFocused = false } // Click nền tắt search
            
            VStack(spacing: 0) {
                // 1. HEADER (Tách ra struct con cho gọn)
                // 1. HEADER (Tách ra struct con cho gọn)
                HeaderView(
                    itemCount: filteredItems.count,
                    searchText: $vm.searchText,
                    isSearchFocused: _isSearchFocused,
                    onClearClipboard: { vm.clearAllItems() }
                )
                
                // 2. LIST
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(filteredItems) { item in
                                // Extracted subview to fix drag preview identity issues
                                DraggableItemCard(
                                    item: item,
                                    selectedItemId: $vm.selectedItemId,
                                    searchQuery: vm.debouncedSearchText,
                                    onSelect: {
                                        vm.selectedItemId = item.id
                                        isSearchFocused = false
                                    },
                                    onPaste: {
                                        vm.pasteAndHide(item)
                                    },
                                    onDelete: {
                                        vm.deleteItem(item)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24) // Increased padding
                        .frame(minWidth: 800, alignment: .leading)
                    }
                    // Tự động cuộn khi selectedItem thay đổi
                    .onChange(of: vm.selectedItemId) { _, newId in
                        if let newId = newId {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                proxy.scrollTo(newId, anchor: .center)
                            }
                            
                            // 👇 FIX BUG: Chỉ tự động mở/cập nhật Preview NẾU trạng thái đang Active
                            if isQuickLookActive,
                               let item = filteredItems.first(where: { $0.id == newId }) {
                                QuickLookController.shared.togglePreview(for: item)
                            }
                        }
                    }
                    // --- TÍNH NĂNG MỚI: Focus Index 0 & Ctrl+Left ---
                    .background(
                        // Nút ẩn để bắt phím tắt Ctrl + Mũi tên trái
                        Button("") {
                            selectFirstItem(proxy: proxy)
                        }
                            .keyboardShortcut(.leftArrow, modifiers: .control)
                            .opacity(0)
                    )
                    .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
                        // Khi App Active -> Tự focus vào item đầu tiên
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            selectFirstItem(proxy: proxy)
                        }
                    }
                }
                
                // 3. EMPTY STATE
                if filteredItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 64))
                            .foregroundColor(.white.opacity(0.1))
                        
                        Text(vm.searchText.isEmpty ? "Clipboard is empty" : "No items found")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.3))
                        
                        if !vm.searchText.isEmpty {
                            Text("Try searching for something else")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.2))
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .transition(.opacity)
                }
                
                Spacer()
            }
        }
        // 👇 FIX LỖI "Invalid frame dimension": Đổi width -> maxWidth
        .frame(maxWidth: .infinity)
        .onAppear {
            vm.setContext(context)
            // Chọn item đầu tiên khi vừa mở app (logic cũ vẫn giữ để đảm bảo state)
            if vm.selectedItemId == nil {
                vm.selectedItemId = filteredItems.first?.id
            }
            
            setupKeyboardMonitor()
            
            // 👇 FIX BUG: Đồng bộ trạng thái khi Panel đóng (bằng nút X hoặc Esc)
            QuickLookController.shared.onPanelClosed = {
                isQuickLookActive = false
            }
        }
        // Logic Debounce Search
        .task(id: vm.searchText) {
            await vm.runSearchDebounce()
            // Khi search xong, tự chọn item đầu tiên nếu danh sách thay đổi
            if let first = filteredItems.first {
                vm.selectedItemId = first.id
            }
        }
    }
    
    // --- HELPER FUNCTION: Chọn item đầu tiên ---
    private func selectFirstItem(proxy: ScrollViewProxy) {
        if let first = filteredItems.first {
            vm.selectedItemId = first.id
            withAnimation {
                proxy.scrollTo(first.id, anchor: .center) // Hoặc .leading tuỳ sở thích
            }
        }
    }
    
    // --- HEADER VIEW ---
    struct HeaderView: View {
        let itemCount: Int
        @Binding var searchText: String
        @FocusState var isSearchFocused: Bool
        var onClearClipboard: () -> Void // Callback for clear action
        
        var body: some View {
            ZStack {
                // Tiêu đề & Thông tin (Ẩn khi đang search)
                if !isSearchFocused{
                    HStack {
                        Text("Clipboard History")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                            .lineLimit(1) // Chống tràn dòng
                            .layoutPriority(1) // Ưu tiên hiển thị
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Text("\(itemCount) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Menu {
                                Button("Clear Clipboard") { onClearClipboard() } // Use callback
                                Divider()
                                Button("Settings") { AppDelegate.shared?.openSettings()  }
                                Button("Quit") { NSApp.terminate(nil) }
                            } label: {
                                Image(systemName: "ellipsis").font(.title3).foregroundStyle(.secondary)
                                    .contentShape(Rectangle())
                            }
                            .menuStyle(.button)
                            .menuIndicator(.hidden)
                            .fixedSize()
                            .focusable(false)
                        }
                        .layoutPriority(1)
                    }
                    .transition(.opacity)
                }
                
                // Search Bar (Nằm giữa)
                HStack {
                    Spacer()
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Type to search...", text: $searchText)
                            .textFieldStyle(.plain)
                            .focused($isSearchFocused)
                        
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(isSearchFocused ? 0.3 : 0.1), lineWidth: 1)
                    )
                    .frame(width: isSearchFocused ? 650 : 250) // Hiệu ứng co giãn
                    .animation(.spring, value: isSearchFocused)
                    
                    Spacer()
                }
            }
            .padding(20)
            .frame(minWidth: 800)
        }
    }
    
    // --- KEYBOARD LOGIC ---
    func setupKeyboardMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Nếu đang search: Chỉ bắt Enter, Esc, Xuống
            if isSearchFocused {
                if event.keyCode == 125 { isSearchFocused = false; return nil } // Xuống -> Focus list
                if event.keyCode == 36, let first = filteredItems.first { // Enter -> Paste cái đầu tiên
                    vm.pasteAndHide(first)
                    return nil
                }
                // ESC khi đang search -> Xử lý thông minh
                if event.keyCode == 53 {
                    if !vm.searchText.isEmpty {
                        vm.searchText = "" // Có chữ -> Xóa chữ
                    } else {
                        // Hết chữ -> Đóng App luôn
                        isSearchFocused = false
                        DispatchQueue.main.async {
                            (NSApp.delegate as? AppDelegate)?.closeWindow()
                        }
                    }
                    return nil
                }
                
                return event
            }
            
            // Nếu đang duyệt list
            switch event.keyCode {
            case 123: vm.moveSelection(direction: -1, in: filteredItems); return nil // Trái
            case 124: vm.moveSelection(direction: 1, in: filteredItems); return nil  // Phải
            case 36: // Enter
                if let item = filteredItems.first(where: { $0.id == vm.selectedItemId }) {
                    vm.pasteAndHide(item)
                }
                return nil
            case 49: // Space (Quick Look)
                if let item = filteredItems.first(where: { $0.id == vm.selectedItemId }) {
                    // 👇 FIX BUG: Logic bật/tắt Preview tường minh
                    if isQuickLookActive {
                        QuickLookController.shared.closePreview()
                        NSApp.activate(ignoringOtherApps: true)
                    } else {
                        QuickLookController.shared.togglePreview(for: item)
                        isQuickLookActive = true
                    }
                }
                return nil
            case 53: // ESC (Mã 53)
                // Ưu tiên 1: Đóng QuickLook nếu đang mở
                if QuickLookController.shared.isPreviewOpen() {
                    QuickLookController.shared.closePreview()
                    return nil
                }
                
                // Ưu tiên 2: Đóng App chính
                // Gọi hàm closeWindow của AppDelegate
                DispatchQueue.main.async {
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.closeWindow()
                    } else {
                        // Fallback: Ẩn app nếu không gọi được delegate
                        NSApp.hide(nil)
                    }
                }
                return nil
            default:
                // Gõ chữ bất kỳ -> Focus Search
                if let chars = event.characters, chars.count == 1,
                   chars.rangeOfCharacter(from: .letters) !=  nil || chars.rangeOfCharacter(from: .decimalDigits) != nil {
                    isSearchFocused = true
                    return event
                }
            }
            return event
        }
    }
}
