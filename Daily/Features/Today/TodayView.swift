// Features/Today/Views/TodayView.swift

import SwiftUI

struct TodayView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            AppBackgroundView()
            
            VStack {
                Text("Today View")
                    .font(themeManager.titleFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Text("Radial planner will appear here")
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(ThemeManager())
}
