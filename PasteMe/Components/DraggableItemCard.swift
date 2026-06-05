import SwiftUI

struct DraggableItemCard: View {
    let item: ClipItem
    @Binding var selectedItemId: UUID?
    let searchQuery: String
    
    // Callbacks
    var onSelect: () -> Void
    var onPaste: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        ItemCard(
            item: item,
            isSelected: item.id == selectedItemId,
            searchQuery: searchQuery
        )
        .id(item.id)
        .onTapGesture {
            // Click interactions
            if item.id == selectedItemId {
                // If already selected, paste
                onPaste()
            } else {
                // Otherwise, select
                onSelect()
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Remove from Clipboard", systemImage: "trash")
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 12)) 
        .onDrag {
            // Handle files
            if item.typeRaw == "file", let paths = item.fileURLs, let firstPath = paths.first {
                let url = URL(fileURLWithPath: firstPath)
                return NSItemProvider(contentsOf: url) ?? NSItemProvider()
            }
            // Handle images
            else if let imgData = item.imageData {
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "PasteMe_\(UUID().uuidString).png"
                let fileURL = tempDir.appendingPathComponent(fileName)
                try? imgData.write(to: fileURL)
                return NSItemProvider(contentsOf: fileURL) ?? NSItemProvider()
            }
            // Handle text
            else if let text = item.content {
                return NSItemProvider(object: text as NSString)
            }
            return NSItemProvider()
        } preview: {
            // LIGHTWEIGHT PREVIEW
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .shadow(radius: 5)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Header
                    HStack {
                        if let iconData = item.fileIcon, 
                           let nsImage = NSImage(data: iconData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                        } else if let iconData = item.urlFavicon,
                                  let nsImage = NSImage(data: iconData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: item.typeRaw == "url" ? "link.circle.fill" : "doc.text")
                                .foregroundColor(.secondary)
                        }
                        
                        Text(item.urlTitle ?? item.fileName ?? item.sourceApp ?? "Item")
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                    }
                    
                    // Content Preview
                    if let imageData = item.urlPreviewImage, let nsImage = NSImage(data: imageData) {
                         Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 80)
                            .frame(maxWidth: .infinity)
                            .clipped()
                    } else if let content = item.content {
                        Text(content)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(6)
                    } else if item.imageData != nil {
                         Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(12)
            }
            .frame(width: 200, height: 140)
        }
    }
}
