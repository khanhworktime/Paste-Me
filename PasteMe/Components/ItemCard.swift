import SwiftUI
import ImageIO

struct ItemCard: View {
    let item: ClipItem
    var isSelected: Bool = false
    var searchQuery: String = ""
    
    // Cấu hình UI
    private let cardSize: CGFloat = 235
    private let cardCornerRadius: CGFloat = 32
    private let contentTopPadding: CGFloat = 60
    
    // Logic màu thương hiệu (Brand Color)
    private var brandColor: Color {
        guard let bundleID = item.sourceBundleID?.lowercased() else { return Color(white: 0.3) }
        if bundleID.contains("xcode") { return Color(red: 0.0, green: 0.48, blue: 1.0) }
        if bundleID.contains("safari") { return Color(red: 0.0, green: 0.65, blue: 0.95) }
        if bundleID.contains("chrome") { return Color(red: 0.85, green: 0.25, blue: 0.2) }
        if bundleID.contains("code") { return Color(red: 0.2, green: 0.2, blue: 0.6) } // VS Code
        if bundleID.contains("figma") { return Color.purple }
        return Color(white: 0.3)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // --- LAYER 1: BACKGROUND AND CONTENT ---
            ZStack(alignment: .topLeading) {
                // Frosted glass effect
                VisualEffectView(material: .hudWindow, blendingMode: .withinWindow).opacity(0.4)
                Color.black.opacity(0.5)
                
                // Content based on type
                if item.typeRaw == "file" {
                    fileContent
                } else if item.typeRaw == "url" {
                    urlContent
                } else if let imgData = item.imageData {
                    AsyncThumbnailView(imageData: imgData)
                } else {
                    textContent
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
            
            // --- LAYER 2: HEADER PILL ---
            headerPill
        }
        .frame(width: cardSize, height: cardSize)
        // Selection border
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(isSelected ? Color.white : Color.white.opacity(0.1), lineWidth: isSelected ? 3 : 1)
        )
        // Subtle zoom when selected
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .animation(.spring(duration: 0.25), value: isSelected)
    }
    
    // View: File content display
    private var fileContent: some View {
        VStack(spacing: 12) {
            Spacer()
            
            // File icon
            if let iconData = item.fileIcon, let icon = NSImage(data: iconData) {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            } else {
                Image(systemName: "doc.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // File name
            Text(item.fileName ?? "File")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // File count badge (for multiple files)
            if let paths = item.fileURLs, paths.count > 1 {
                Text("\(paths.count) files")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(14)
        .padding(.top, contentTopPadding - 14)
    }
    
    // View: URL content display
    private var urlContent: some View {
        GeometryReader { geo in
            // 1. Full-size Background Image
            if let imageData = item.urlPreviewImage, let nsImg = NSImage(data: imageData) {
                Image(nsImage: nsImg)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .overlay(LinearGradient(colors: [.black.opacity(0.3), .clear], startPoint: .top, endPoint: .center))
            } else {
                // Placeholder
                ZStack {
                    Color.white.opacity(0.05)
                    Image(systemName: "link")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.1))
                }
            }
        }
        // 2. Metadata Badge (Like Image Card)
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 6) {
                // Favicon
                if let favData = item.urlFavicon, let nsFav = NSImage(data: favData) {
                    Image(nsImage: nsFav)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                        .clipShape(Circle())
                }
                
                // Title (max 20 chars for space)
                if let title = item.urlTitle {
                     Text(title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                // Short Link
                if let urlStr = item.content {
                    Text(shortenLink(urlStr))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Capsule().fill(Color.black.opacity(0.75)))
            .padding(10) // Margin from edge
        }
    }

    private func shortenLink(_ url: String) -> String {
        var clean = url.replacingOccurrences(of: "https://", with: "")
                      .replacingOccurrences(of: "http://", with: "")
                      .replacingOccurrences(of: "www.", with: "")
        if clean.count > 12 {
            clean = String(clean.prefix(12)) + "..."
        }
        return clean
    }
    
    // (Old imageContent removed, handled by AsyncThumbnailView below)
    
    // View con: Hiển thị Text
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Text highlight từ khoá tìm kiếm
            Text(item.content?.highlight(searchQuery) ?? "")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(7)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            Spacer()
            // Đếm ký tự
            
            if let count = item.content?.count {
                Text("\(count) characters")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(4)
            }
        
            
        }
        .padding(14)
        .padding(.top, contentTopPadding - 14)
    }
    
    // View con: Header Pill
    private var headerPill: some View {
        HStack(spacing: 8) {
            Image(nsImage: AppTheme.getIcon(for: item.sourceBundleID))
                .resizable().aspectRatio(contentMode: .fit).frame(width: 20, height: 20)
            VStack(alignment: .leading, spacing: 0) {
                Text(item.sourceApp ?? "Unknown").font(.system(size: 12, weight: .bold)).foregroundColor(.white).lineLimit(1)
                Text(item.createdAt.timeAgoDisplay()).font(.system(size: 9)).foregroundColor(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding(.vertical, 8).padding(.horizontal, 12)
        .background(Capsule().fill(brandColor).shadow(color: .black.opacity(0.4), radius: 4, y: 2))
        .padding(10)
    }
}

struct AsyncThumbnailView: View {
    let imageData: Data
    @State private var thumbnail: NSImage?
    @State private var originalSize: CGSize?
    
    var body: some View {
        GeometryReader { geo in
            Group {
                if let thumbnail = thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .overlay(LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .center))
                        .overlay(alignment: .bottomTrailing) {
                            if let size = originalSize {
                                HStack(spacing: 4) {
                                    Image(systemName: "photo")
                                    Text("\(Int(size.width)) × \(Int(size.height))")
                                }
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(6)
                                .background(Capsule().fill(Color.black.opacity(0.6)))
                                .padding(10)
                            }
                        }
                } else {
                    // Placeholder while loading
                    ZStack {
                        Color.black.opacity(0.3)
                        ProgressView()
                            .controlSize(.small)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
        .task(id: imageData) {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        // Chạy trên background thread
        let result = await Task.detached { () -> (NSImage?, CGSize?) in
            guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else { return (nil, nil) }
            
            // Lấy kích thước gốc mà không cần load toàn bộ ảnh
            var size: CGSize? = nil
            if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] {
                let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue ?? 0
                let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue ?? 0
                if width > 0 && height > 0 {
                    size = CGSize(width: width, height: height)
                }
            }
            
            // Tạo thumbnail siêu nhẹ (max 300px)
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 300
            ]
            
            guard let thumbnailRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else { return (nil, size) }
            
            let nsImg = NSImage(cgImage: thumbnailRef, size: NSSize(width: thumbnailRef.width, height: thumbnailRef.height))
            return (nsImg, size)
        }.value
        
        await MainActor.run {
            self.thumbnail = result.0
            self.originalSize = result.1
        }
    }
}
