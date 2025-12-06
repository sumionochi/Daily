import SwiftUI

@main
struct DailyApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(themeManager)
        }
    }
}
