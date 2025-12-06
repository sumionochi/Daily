// Features/Inbox/Views/InboxView.swift

import SwiftUI

struct InboxView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            AppBackgroundView()
            
            VStack {
                Text("Inbox")
                    .font(themeManager.titleFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Text("Task list will appear here")
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
        }
    }
}

#Preview {
    InboxView()
        .environmentObject(ThemeManager())
}
