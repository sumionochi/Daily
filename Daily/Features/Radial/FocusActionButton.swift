// Features/Radial/Views/FocusActionButton.swift

import SwiftUI

struct FocusActionButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let action: () -> Void
    let isDisabled: Bool
    
    init(action: @escaping () -> Void, isDisabled: Bool = false) {
        self.action = action
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 16))
                
                Text("Start Focus")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isDisabled ? themeManager.textTertiaryColor : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isDisabled ? 
                        themeManager.cardBackgroundColor : 
                        themeManager.accent
                    )
            )
            .shadow(
                color: isDisabled ? .clear : themeManager.accent.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

#Preview {
    VStack(spacing: 20) {
        FocusActionButton(action: {}, isDisabled: false)
        FocusActionButton(action: {}, isDisabled: true)
    }
    .padding()
    .background(Color.black)
    .environmentObject(ThemeManager())
}
