//
//  VisualEffectView.swift
//  PasteMe
//
//  Created by Krist Dev on 26/1/26.
//


import SwiftUI

// Component kính mờ chuẩn macOS
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material; view.blendingMode = blendingMode; view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material; nsView.blendingMode = blendingMode
    }
}

// Xử lý ngày tháng tương đối (vd: 2 min ago)
extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// Xử lý highlight text (Fix lỗi cú pháp AttributedString)
extension String {
    func highlight(_ query: String) -> AttributedString {
        var attributedString = AttributedString(self)
        
        guard !query.isEmpty else { return attributedString }
        
        // Tìm và tô màu tất cả các từ khớp
        var searchRange = attributedString.startIndex..<attributedString.endIndex
        while let range = attributedString[searchRange].range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) {
            attributedString[range].backgroundColor = .yellow
            attributedString[range].foregroundColor = .black
            attributedString[range].font = .system(size: 13, weight: .bold)
            
            searchRange = range.upperBound..<attributedString.endIndex
        }
        
        return attributedString
    }
}


// MARK: - Extensions Helper
extension Bundle {
    var appVersionLong: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var appBuild: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
