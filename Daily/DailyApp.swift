// App/DailyApp.swift

import SwiftUI
import SwiftData

@main
struct DailyApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    let modelContainer: ModelContainer
    let storeContainer: StoreContainer
    
    init() {
        // Initialize ModelContainer
        self.modelContainer = ModelContainer.create()
        
        // Initialize StoreContainer with main context
        self.storeContainer = StoreContainer(
            modelContext: modelContainer.mainContext,
            shouldSeed: true
        )
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(themeManager)
                .environmentObject(storeContainer)
                .modelContainer(modelContainer)
        }
    }
}
