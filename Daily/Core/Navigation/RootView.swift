import SwiftUI

struct RootView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad layout
                iPadLayout
            } else {
                // iPhone layout
                iPhoneLayout
            }
        }
        .preferredColorScheme(themeManager.colorSchemePreference.colorScheme)
    }
    
    // MARK: - iPhone Layout
    
    private var iPhoneLayout: some View {
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
    }
    
    // MARK: - iPad Layout
    
    private var iPadLayout: some View {
        NavigationSplitView {
            List {
                Button {
                    selectedTab = 0
                } label: {
                    Label("Today", systemImage: "circle.circle")
                        .foregroundColor(selectedTab == 0 ? themeManager.accent : themeManager.textPrimaryColor)
                }
                
                Button {
                    selectedTab = 1
                } label: {
                    Label("Inbox", systemImage: "tray")
                        .foregroundColor(selectedTab == 1 ? themeManager.accent : themeManager.textPrimaryColor)
                }
                
                Button {
                    selectedTab = 2
                } label: {
                    Label("Settings", systemImage: "gearshape")
                        .foregroundColor(selectedTab == 2 ? themeManager.accent : themeManager.textPrimaryColor)
                }
            }
            .navigationTitle("Daily")
            .listStyle(.sidebar)
        } detail: {
            switch selectedTab {
            case 0:
                TodayViewiPad()
            case 1:
                InboxView()
            case 2:
                SettingsView()
            default:
                TodayViewiPad()
            }
        }
    }
}

#Preview("iPhone") {
    RootView()
        .environmentObject(ThemeManager())
}

#Preview("iPad") {
    RootView()
        .environmentObject(ThemeManager())
}
