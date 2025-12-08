// Features/Radial/Views/RadialBlockWithFocus.swift

import SwiftUI

struct RadialBlockWithFocus: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let block: TimeBlock
    let category: Category?
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let isFocused: Bool
    let isDimmed: Bool
    let onTap: () -> Void
    
    var body: some View {
        RadialBlockView(
            block: block,
            innerRadius: innerRadius,
            outerRadius: outerRadius,
            category: category
        )
        .opacity(opacity)
        .shadow(
            color: isFocused ? glowColor : .clear,
            radius: isFocused ? 12 : 0,
            x: 0,
            y: 0
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .animation(.easeInOut(duration: 0.25), value: isDimmed)
        .onTapGesture {
            onTap()
        }
    }
    
    private var opacity: Double {
        if isFocused {
            return 1.0
        } else if isDimmed {
            return 0.25
        } else {
            return 1.0
        }
    }
    
    private var glowColor: Color {
        guard let category = category else {
            return themeManager.accent.opacity(0.5)
        }
        
        return categoryColor(category).opacity(0.6)
    }
    
    private func categoryColor(_ category: Category) -> Color {
        switch category.colorID {
        case "blue": return Color(red: 0.4, green: 0.6, blue: 1.0)
        case "purple": return Color(red: 0.7, green: 0.5, blue: 1.0)
        case "pink": return Color(red: 1.0, green: 0.5, blue: 0.7)
        case "orange": return Color(red: 1.0, green: 0.6, blue: 0.4)
        case "green": return Color(red: 0.5, green: 0.9, blue: 0.6)
        case "teal": return Color(red: 0.4, green: 0.8, blue: 0.9)
        default: return themeManager.accent
        }
    }
}
