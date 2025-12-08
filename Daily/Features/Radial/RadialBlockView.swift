// Features/Radial/Views/RadialBlockView.swift

import SwiftUI

struct RadialBlockView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let block: TimeBlock
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let category: Category?
    
    private let arcThickness: CGFloat = 32
    private let borderWidth: CGFloat = 2
    
    var body: some View {
        ZStack {
            // Transparent fill
            arcShape
                .fill(categoryColor.opacity(fillOpacity))
            
            // Opaque border
            arcShape
                .stroke(categoryColor, lineWidth: borderWidth)
            
            // Completion overlay (if done)
            if block.isDone {
                BlockCompletionOverlay(
                    isDone: block.isDone,
                    categoryColor: categoryColor,
                    innerRadius: innerRadius,
                    arcThickness: arcThickness,
                    startAngle: block.startAngle,
                    endAngle: block.endAngle
                )
            }
            
            // Content (emoji + text) inside the arc
            if sweepAngle > 15 {
                arcContent
            }
        }
    }
    
    // MARK: - Arc Shape
    
    private var arcShape: ArcShape {
        ArcShape(
            startAngle: swiftUIAngle(block.startAngle),
            endAngle: swiftUIAngle(block.endAngle),
            innerRadius: innerRadius,
            outerRadius: innerRadius + arcThickness
        )
    }
    
    // Convert our angle system (0° = top) to SwiftUI's (0° = right)
    private func swiftUIAngle(_ degrees: Double) -> Angle {
        Angle(degrees: degrees - 90)
    }
    
    // MARK: - Arc Content
    
    private var arcContent: some View {
        let midAngle = (block.startAngle + block.endAngle) / 2
        let angleRadians = (midAngle - 90) * .pi / 180
        
        // Position in the middle of the arc
        let contentRadius = innerRadius + (arcThickness / 2)
        let x = contentRadius * cos(angleRadians)
        let y = contentRadius * sin(angleRadians)
        
        // Calculate rotation for readability
        var rotation = midAngle
        if midAngle > 90 && midAngle < 270 {
            rotation += 180 // Flip on left side
        }
        
        return contentView
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        VStack(spacing: 2) {
            // Adaptive emoji
            if let emoji = block.emoji {
                AdaptiveArcEmoji(emoji: emoji, sweepAngle: sweepAngle)
            }
            
            // Adaptive text label (only if enough space)
            if sweepAngle > 30 {
                AdaptiveArcText(
                    text: block.title,
                    sweepAngle: sweepAngle,
                    color: textColor
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var fillOpacity: Double {
        if block.isDone {
            return 0.2
        } else {
            return 0.35 // Transparent but visible
        }
    }
    
    private var textColor: Color {
        // Use high contrast for readability
        return themeManager.textPrimaryColor
    }
    
    private var sweepAngle: Double {
        let sweep = block.endAngle - block.startAngle
        return sweep >= 0 ? sweep : sweep + 360
    }
    
    private var categoryColor: Color {
        guard let category = category else {
            return themeManager.accent
        }
        
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

// MARK: - Arc Shape

struct ArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // Outer arc
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        // Line to inner arc start
        path.addLine(to: CGPoint(
            x: center.x + innerRadius * CGFloat(cos(endAngle.radians)),
            y: center.y + innerRadius * CGFloat(sin(endAngle.radians))
        ))
        
        // Inner arc (reverse direction)
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    let block = TimeBlock(
        title: "Deep Work",
        emoji: "🎯",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600),
        categoryID: nil
    )
    
    return ZStack {
        Color.black
        RadialBlockView(
            block: block,
            innerRadius: 140,
            outerRadius: 180,
            category: nil
        )
        .environmentObject(ThemeManager())
    }
}
