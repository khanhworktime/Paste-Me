import SwiftUI
import ServiceManagement
import SwiftData
internal import UniformTypeIdentifiers

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case hotkeys = "Hotkeys"
    case history = "History"
    case advanced = "Advanced"
    case support = "Support"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .hotkeys: return "keyboard"
        case .history: return "clock.arrow.circlepath"
        case .advanced: return "slider.horizontal.3"
        case .support: return "questionmark.circle"
        }
    }
}

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @StateObject private var updater = Updater()
    @State private var selectedTab: SettingsTab? = .general
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 180, max: 200)
        } detail: {
            ZStack {
                
                Group {
                    if let selectedTab = selectedTab {
                        switch selectedTab {
                        case .general:
                            GeneralSettingsView(launchAtLogin: $launchAtLogin, updater: updater)
                        case .hotkeys:
                            HotkeysSettingsView()
                        case .history:
                            HistorySettingsView()
                        case .advanced:
                            AdvancedSettingsView()
                        case .support:
                            SupportSettingsView()
                        }
                    } else {
                        Text("Select a category")
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                .id(selectedTab)
            }
            .navigationTitle("Settings")
        }
        .frame(width: 600, height: 450)
        .onChange(of: launchAtLogin) { _, newValue in
            setLaunchAtLogin(enabled: newValue)
        }
    }
    
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


// MARK: - General Tab
struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    @ObservedObject var updater: Updater
    
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("playSoundOnCopy") private var playSoundOnCopy = false
    
    var body: some View {
        Form {
            // App Info Section
            HStack(spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .shadow(radius: 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("PasteMe")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Version \(Bundle.main.appVersionLong) (\(Bundle.main.appBuild))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button(action: {
                        updater.checkForUpdates()
                    }) {
                        Text("Check for Updates...")
                    }
                    .controlSize(.small)
                    .padding(.top, 4)
                }
                Spacer()
            }
            .padding(.bottom, 10)
            
            Section(header: Text("Appearance")) {
                Picker("App Theme", selection: $appTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                .onChange(of: appTheme) { _ in
                    NotificationCenter.default.post(name: NSNotification.Name("AppThemeChanged"), object: nil)
                }
                
                Toggle("Show Menu Bar Icon", isOn: $showMenuBarIcon)
                .onChange(of: showMenuBarIcon) { _ in
                    NotificationCenter.default.post(name: NSNotification.Name("MenuBarIconChanged"), object: nil)
                }
            }
            
            Section(header: Text("Startup & Behavior")) {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Play sound on copy", isOn: $playSoundOnCopy)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Hotkeys Tab
struct HotkeysSettingsView: View {
    @AppStorage("toggleHotkeyIndex") private var toggleHotkeyIndex = 0
    @AppStorage("clearHistoryHotkeyIndex") private var clearHistoryHotkeyIndex = 0
    
    var body: some View {
        Form {
            Section(header: Text("Global Shortcuts")) {
                Picker("Toggle PasteMe Panel", selection: $toggleHotkeyIndex) {
                    Text("⌘ ⇧ V").tag(0)
                    Text("⌥ V").tag(1)
                    Text("⌘ ⌥ V").tag(2)
                    Text("⌘ ⌃ V").tag(3)
                }
                .onChange(of: toggleHotkeyIndex) { _ in
                    NotificationCenter.default.post(name: NSNotification.Name("HotkeyChanged"), object: nil)
                }
                
                Picker("Clear History", selection: $clearHistoryHotkeyIndex) {
                    Text("Unassigned").tag(0)
                    Text("⌘ ⇧ ⌫").tag(1)
                    Text("⌘ ⌥ ⌫").tag(2)
                    Text("⌘ ⌃ ⌫").tag(3)
                }
                .onChange(of: clearHistoryHotkeyIndex) { _ in
                    NotificationCenter.default.post(name: NSNotification.Name("HotkeyChanged"), object: nil)
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - History Tab
struct HistorySettingsView: View {
    @Environment(\.modelContext) private var context
    
    @AppStorage("historyLimit") private var historyLimit = 100
    @AppStorage("autoClearDays") private var autoClearDays = 30
    
    var body: some View {
        Form {
            Section(header: Text("Storage")) {
                Picker("Keep history capacity", selection: $historyLimit) {
                    Text("50 items").tag(50)
                    Text("100 items").tag(100)
                    Text("500 items").tag(500)
                    Text("Unlimited").tag(0)
                }
                
                Picker("Auto-clear older than", selection: $autoClearDays) {
                    Text("7 Days").tag(7)
                    Text("30 Days").tag(30)
                    Text("90 Days").tag(90)
                    Text("Never").tag(0)
                }
            }
            
            Section {
                Button(role: .destructive, action: {
                    do {
                        try context.delete(model: ClipItem.self)
                        try context.save()
                    } catch {
                        print("Failed to clear all history: \(error)")
                    }
                }) {
                    Text("Clear All History Now")
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Advanced Tab
struct AdvancedSettingsView: View {
    @AppStorage("pasteAsPlainText") private var pasteAsPlainText = false
    @AppStorage("ignoredApps") private var ignoredAppsString = "1Password,Keychain Access,Bitwarden"
    
    @State private var selection: String?
    
    var ignoredAppsList: [String] {
        ignoredAppsString.isEmpty ? [] : ignoredAppsString.components(separatedBy: ",")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Pasting")) {
                Toggle("Paste as Plain Text by default", isOn: $pasteAsPlainText)
                Text("Strips all formatting when pasting text.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section(header: Text("Ignored Applications")) {
                List(selection: $selection) {
                    ForEach(ignoredAppsList, id: \.self) { app in
                        Text(app)
                    }
                }
                .frame(height: 100)
                
                HStack {
                    Spacer()
                    ControlGroup {
                        Button(action: {
                            addApp()
                        }) {
                            Image(systemName: "plus")
                        }
                        Button(action: {
                            if let sel = selection {
                                var apps = ignoredAppsList
                                apps.removeAll { $0 == sel }
                                ignoredAppsString = apps.joined(separator: ",")
                                selection = nil
                            }
                        }) {
                            Image(systemName: "minus")
                        }
                        .disabled(selection == nil)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
    
    func addApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        
        if panel.runModal() == .OK {
            var currentApps = ignoredAppsList
            for url in panel.urls {
                let name = url.deletingPathExtension().lastPathComponent
                if !currentApps.contains(name) {
                    currentApps.append(name)
                }
            }
            ignoredAppsString = currentApps.joined(separator: ",")
        }
    }
}

// MARK: - Support Tab
struct SupportSettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .shadow(color: .blue.opacity(0.4), radius: 30, x: 0, y: 0) // Glow effect
                .padding(.bottom, 8)
            
            // App Name & Version
            VStack(spacing: 4) {
                Text("PasteMe")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Version \(Bundle.main.appVersionLong)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 16)
            
            // Developed with ❤️
            Text("Designed and developed with ❤️")
                .font(.headline)
            
            // Links
            HStack(spacing: 24) {
                Link(destination: URL(string: "https://github.com/kristdev/PasteMe")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                        Text("GitHub")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                }
                
                Link(destination: URL(string: "mailto:krist.dev.vn@gmail.com")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill")
                        Text("Email")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
            
            // Ko-Fi Button
            Link(destination: URL(string: "https://ko-fi.com/O4O61T9M1O")!) {
                AsyncImage(url: URL(string: "https://storage.ko-fi.com/cdn/brandasset/v2/support_me_on_kofi_beige.png")) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 40)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

