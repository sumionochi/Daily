// Features/Tasks/Views/FilterChip.swift

import SwiftUI

struct FilterChip: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundColor(isSelected ? 
                (themeManager.accentColor == .mono ? 
                    Color(light: .white, dark: .black) : .white) : 
                themeManager.textPrimaryColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? themeManager.accent : themeManager.cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    HStack {
        FilterChip(title: "All", icon: "list.bullet", isSelected: true) {}
        FilterChip(title: "Today", icon: "calendar", isSelected: false) {}
        FilterChip(title: "Upcoming", icon: "arrow.right", isSelected: false) {}
    }
    .padding()
    .environmentObject(ThemeManager())
}
