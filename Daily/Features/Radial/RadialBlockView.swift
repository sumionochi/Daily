// Features/Radial/RadialBlockView.swift

import SwiftUI

struct RadialBlockView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let block: TimeBlock
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let category: Category?
    
    var body: some View {
        ZStack {
            // Main arc
            arcShape
                .fill(categoryColor.opacity(block.isDone ? 0.4 : 1.0))
            
            // Subtle separator stroke to make segments feel like one premium ring
            arcShape
                .stroke(Color.black.opacity(0.35), lineWidth: 0.5)
            
            // Optional emoji in the middle of the segment (no noisy outer labels)
            if let emoji = block.emoji, sweepAngle > 10 {
                emojiLabel(emoji: emoji)
            }
        }
    }
    
    // MARK: - Arc Shape
    
    private var arcShape: ArcShape {
        ArcShape(
            startAngle: RadialLayoutEngine.swiftUIAngle(block.startAngle),
            endAngle: RadialLayoutEngine.swiftUIAngle(block.endAngle),
            innerRadius: innerRadius,
            outerRadius: outerRadius   // <- use the full ring thickness passed in
        )
    }
    
    // MARK: - Emoji on the ring
    
    private func emojiLabel(emoji: String) -> some View {
        let midAngle = (block.startAngle + block.endAngle) / 2
        let angleRadians = (midAngle - 90) * .pi / 180
        
        // Place emoji in the middle of the ring thickness
        let radius = (innerRadius + outerRadius) / 2
        let x = radius * cos(angleRadians)
        let y = radius * sin(angleRadians)
        
        return Text(emoji)
            .font(.system(size: 18))
            .offset(x: x, y: y)
    }
    
    // MARK: - Computed
    
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
        endDate: Date().addingTimeInterval(7200)
    )
    
    return ZStack {
        Color.black.ignoresSafeArea()
        
        RadialBlockView(
            block: block,
            innerRadius: 120,
            outerRadius: 180,
            category: nil
        )
        .frame(width: 320, height: 320)
    }
    .environmentObject(ThemeManager())
}
