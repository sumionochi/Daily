import SwiftUI

struct PrimaryButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(themeManager.buttonFont)
            .foregroundColor(themeManager.textOnAccentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(themeManager.accent)
            .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadiusMedium))
        }
    }
}

struct SecondaryButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let icon: String?
    let action: () -> Void

    // Same pattern as PrimaryButton
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(themeManager.buttonFont)
            .foregroundColor(themeManager.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: themeManager.cornerRadiusMedium)
                    .stroke(themeManager.accent, lineWidth: 2)
            )
        }
    }
}

struct IconButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(themeManager.textPrimaryColor)
                .frame(width: 44, height: 44)
                .background(themeManager.cardBackgroundColor)
                .clipShape(Circle())
        }
    }
}

#Preview {
    ZStack {
        AppBackgroundView()
        
        VStack(spacing: 16) {
            PrimaryButton("Primary Action", icon: "plus") {
                print("Primary")
            }
            
            SecondaryButton(title: "Secondary Action", icon: "arrow.right") {
                print("Secondary")
            }
            
            HStack {
                IconButton(icon: "chevron.left") {
                    print("Left")
                }
                IconButton(icon: "chevron.right") {
                    print("Right")
                }
            }
        }
        .padding()
    }
    .environmentObject(ThemeManager())
}
