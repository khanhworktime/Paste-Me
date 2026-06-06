import SwiftUI

struct TestView: View {
    @State private var selectedTab: String? = "General"
    let tabs = ["General", "Hotkeys"]

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                ForEach(tabs, id: \.self) { tab in
                    Label(tab, systemImage: "gear")
                        .tag(tab)
                }
            }
            .listStyle(.sidebar)
        } detail: {
            Text("Content for \(selectedTab ?? "none")")
                .navigationTitle("Settings")
        }
    }
}
