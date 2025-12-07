// Features/Tasks/Views/FolderChip.swift

import SwiftUI

struct FolderChip: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? 
                            (themeManager.accentColor == .mono ? 
                                Color(light: .black, dark: .white) : themeManager.accent) : 
                            themeManager.textSecondaryColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? 
                            (themeManager.accentColor == .mono ? 
                                Color(light: .white, dark: .black) : Color.white.opacity(0.3)) : 
                            themeManager.backgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
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
        FolderChip(title: "Inbox", icon: "tray", count: 5, isSelected: true) {}
        FolderChip(title: "Work", icon: "briefcase", count: 3, isSelected: false) {}
        FolderChip(title: "Personal", icon: "person", count: 0, isSelected: false) {}
    }
    .padding()
    .environmentObject(ThemeManager())
}
