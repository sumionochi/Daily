// Core/Navigation/RootView.swift

import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad: Navigation Split View
                iPadLayout
            } else {
                // iPhone: Tab View
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
            
            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(1)
            
            RoutinesView()
                .tabItem {
                    Label("Routines", systemImage: "repeat")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .tint(themeManager.accent)
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
                    Label("Tasks", systemImage: "checklist")
                        .foregroundColor(selectedTab == 1 ? themeManager.accent : themeManager.textPrimaryColor)
                }
                
                Button {
                    selectedTab = 2
                } label: {
                    Label("Routines", systemImage: "repeat")
                        .foregroundColor(selectedTab == 2 ? themeManager.accent : themeManager.textPrimaryColor)
                }
                
                Button {
                    selectedTab = 3
                } label: {
                    Label("Settings", systemImage: "gear")
                        .foregroundColor(selectedTab == 3 ? themeManager.accent : themeManager.textPrimaryColor)
                }
            }
            .navigationTitle("Daily")
            .listStyle(.sidebar)
        } detail: {
            Group {
                switch selectedTab {
                case 0:
                    TodayViewiPad()
                case 1:
                    TasksView()
                case 2:
                    RoutinesView()
                case 3:
                    SettingsView()
                default:
                    TodayViewiPad()
                }
            }
        }
        .tint(themeManager.accent)
    }
}

#Preview {
    RootView()
        .environmentObject(ThemeManager())
        .environmentObject({
            let container = ModelContainer.createPreview()
            return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
        }())
}
