// Features/Radial/RadialBlockView.swift

import SwiftUI

struct RadialBlockView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let block: TimeBlock
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let category: Category?
    
    private let arcThickness: CGFloat = 32 // Thinner arcs
    
    var body: some View {
        ZStack {
            // The arc
            arcShape
                .fill(categoryColor.opacity(block.isDone ? 0.4 : 1.0))
            
            // Block label (outside the arc)
            if sweepAngle > 10 {
                blockLabel
            }
        }
    }
    
    // MARK: - Arc Shape
    
    private var arcShape: ArcShape {
        ArcShape(
            startAngle: RadialLayoutEngine.swiftUIAngle(block.startAngle),
            endAngle: RadialLayoutEngine.swiftUIAngle(block.endAngle),
            innerRadius: innerRadius,
            outerRadius: innerRadius + arcThickness
        )
    }
    
    // MARK: - Block Label
    
    private var blockLabel: some View {
        let midAngle = (block.startAngle + block.endAngle) / 2
        let angleRadians = (midAngle - 90) * .pi / 180 // Adjust for top-start
        
        // Position label outside the arc
        let labelRadius = outerRadius + 40
        let x = labelRadius * cos(angleRadians)
        let y = labelRadius * sin(angleRadians)
        
        // Calculate rotation to make text readable
        var textRotation = midAngle
        if midAngle > 90 && midAngle < 270 {
            textRotation += 180 // Flip text on left side
        }
        
        return VStack(spacing: 2) {
            if let emoji = block.emoji {
                Text(emoji)
                    .font(.system(size: 24))
            }
            
            Text(block.title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.textPrimaryColor)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .rotationEffect(.degrees(textRotation))
        .offset(x: x, y: y)
    }
    
    // MARK: - Computed Properties
    
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
        endDate: Date().addingTimeInterval(7200) // 2 hours
    )
    
    return ZStack {
        Color.black
            .ignoresSafeArea()
        
        RadialBlockView(
            block: block,
            innerRadius: 120,
            outerRadius: 160,
            category: nil
        )
        .frame(width: 320, height: 320)
    }
    .environmentObject(ThemeManager())
}
