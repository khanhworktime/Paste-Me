import SwiftUI
import ServiceManagement

struct SettingsView: View {
    // Quản lý việc khởi động cùng Windows
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    // Quản lý cập nhật
    @StateObject private var updater = Updater()
    
    var body: some View {
        TabView {
            // TAB 1: GENERAL (Đã gộp Info & Update vào đây)
            GeneralSettingsView(launchAtLogin: $launchAtLogin, updater: updater)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            // TAB 2: SUPPORT
            SupportSettingsView()
                .tabItem {
                    Label("Support", systemImage: "questionmark.circle")
                }
        }
        .frame(width: 450, height: 380) // Tăng chiều cao xíu để chứa đủ nội dung
        .padding()
        // Logic thực tế cho Launch at Login
        .onChange(of: launchAtLogin) { _, newValue in
            setLaunchAtLogin(enabled: newValue)
        }
    }
    
    // Helper function để đăng ký Login Item
    private func setLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to change launch at login: \(error)")
        }
    }
}

// MARK: - 1. General Tab (Combined Layout)
struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    @ObservedObject var updater: Updater
    
    var body: some View {
        VStack(spacing: 0) {
            // --- PHẦN 1: APP INFO & UPDATE ---
            VStack(spacing: 16) {
                // App Icon
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .shadow(radius: 4)
                
                // Tên & Version
                VStack(spacing: 4) {
                    Text("PasteMe")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Version \(Bundle.main.appVersionLong) (\(Bundle.main.appBuild))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Nút Check Update
                Button(action: {
                    updater.checkForUpdates()
                }) {
                    Text("Check for Updates...")
                        .frame(minWidth: 140)
                }
                .controlSize(.regular)
            }
            .padding(.top, 20)
            .padding(.bottom, 24)
            
            Divider()
            
            // --- PHẦN 2: SETTINGS FORM ---
            Form {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Launch at login")
                                .fontWeight(.medium)
                            Text("Automatically start PasteMe when you log in.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $launchAtLogin)
                            .toggleStyle(.switch)
                    }
                    .padding(.vertical, 4)
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true) // Tắt scroll vì nội dung ít
        }
    }
}

// MARK: - 2. Support Tab
struct SupportSettingsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "envelope.fill")
                .font(.system(size: 50))
                .foregroundStyle(.blue)
            
            VStack(spacing: 8) {
                Text("Need help?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("If you encounter any issues or have suggestions, please feel free to contact us via email.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            
            // Email Button
            Link(destination: URL(string: "mailto:krist.dev.vn@gmail.com")!) {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("krist.dev.vn@gmail.com")
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: 250)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text("© 2026 PasteMe App. All rights reserved.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 10)
        }
    }
}

