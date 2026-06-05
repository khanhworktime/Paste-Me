import Foundation
import SwiftData

@Model
final class ClipItem {
    var id: UUID
    var createdAt: Date
    var content: String?
    @Attribute(.externalStorage) var imageData: Data?
    var typeRaw: String
    
    // Source app info
    var sourceApp: String?      // Display name (e.g., "Safari")
    var sourceBundleID: String? // Bundle ID (e.g., "com.apple.Safari")
    
    // File support
    var fileURLs: [String]?     // Array of file path strings
    var fileName: String?       // Display name ("Document.pdf" or "3 files")
    @Attribute(.externalStorage) var fileIcon: Data?         // Cached file icon as PNG data
    
    // URL support
    var urlTitle: String?       // Page title
    @Attribute(.externalStorage) var urlFavicon: Data?       // Favicon data
    @Attribute(.externalStorage) var urlPreviewImage: Data?  // OpenGraph image data
    
    init(
        content: String? = nil,
        imageData: Data? = nil,
        type: String,
        sourceApp: String? = nil,
        sourceBundleID: String? = nil,
        fileURLs: [String]? = nil,
        fileName: String? = nil,
        fileIcon: Data? = nil,
        urlTitle: String? = nil,
        urlFavicon: Data? = nil,
        urlPreviewImage: Data? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.content = content
        self.imageData = imageData
        self.typeRaw = type
        self.sourceApp = sourceApp
        self.sourceBundleID = sourceBundleID
        self.fileURLs = fileURLs
        self.fileName = fileName
        self.fileIcon = fileIcon
        self.urlTitle = urlTitle
        self.urlFavicon = urlFavicon
        self.urlPreviewImage = urlPreviewImage
    }
}
