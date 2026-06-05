//
//  Updater.swift
//  PasteMe
//
//  Created by Krist Dev on 26/1/26.
//


import SwiftUI
import Sparkle
import Combine

// ViewModel để quản lý việc update
final class Updater: ObservableObject {
    private let controller: SPUStandardUpdaterController
    @Published var canCheckForUpdates: Bool = true
    init() {
        // Khởi tạo Standard Updater của Sparkle
        // startingUpdater: true nghĩa là nó sẽ tự chạy ngầm để check định kỳ
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    // Hàm này sẽ được gọi khi bấm nút
    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
    
    // Hàm này để bật/tắt tự động check (nếu bạn muốn làm toggle trong settings)
    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }
}
