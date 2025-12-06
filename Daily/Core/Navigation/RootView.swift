//  RootView.swift
import SwiftUI

struct RootView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "circle.circle")
                }
                .tag(0)
            
            InboxView()
                .tabItem {
                    Label("Inbox", systemImage: "tray")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
        .preferredColorScheme(themeManager.colorSchemePreference.colorScheme)
    }
}

#Preview {
    RootView()
        .environmentObject(ThemeManager())
}
