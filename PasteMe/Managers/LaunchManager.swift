//
//  LaunchManager.swift
//  PasteMe
//
//  Created by Krist Dev on 26/1/26.
//


import Foundation
import ServiceManagement
import Combine

class LaunchManager: ObservableObject {
    @Published var isLaunchAtLoginEnabled: Bool {
        didSet {
            // Khi biến thay đổi -> Gọi lệnh đăng ký/huỷ đăng ký với hệ thống
            if isLaunchAtLoginEnabled {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
    }

    init() {
        // Kiểm tra trạng thái hiện tại của App
        self.isLaunchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }
}
