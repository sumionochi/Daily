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
            // Arc shape
            ArcShape(
                startAngle: RadialLayoutEngine.swiftUIAngle(block.startAngle),
                endAngle: RadialLayoutEngine.swiftUIAngle(block.endAngle),
                innerRadius: innerRadius,
                outerRadius: outerRadius
            )
            .fill(blockColor.opacity(block.isDone ? 0.4 : 0.8))
            
            // Border
            ArcShape(
                startAngle: RadialLayoutEngine.swiftUIAngle(block.startAngle),
                endAngle: RadialLayoutEngine.swiftUIAngle(block.endAngle),
                innerRadius: innerRadius,
                outerRadius: outerRadius
            )
            .stroke(blockColor, lineWidth: 2)
            
            // Emoji/Icon (if duration is long enough)
            if block.sweepAngle > 20, let emoji = block.emoji {
                let midAngle = block.startAngle + (block.sweepAngle / 2)
                let midRadius = (innerRadius + outerRadius) / 2
                
                Text(emoji)
                    .font(.system(size: 20))
                    .position(
                        RadialLayoutEngine.point(
                            at: midAngle,
                            radius: midRadius,
                            center: CGPoint(x: outerRadius, y: outerRadius)
                        )
                    )
            }
        }
    }
    
    private var blockColor: Color {
        if let category = category {
            return categoryColor(for: category.colorID)
        }
        return themeManager.accent
    }
    
    private func categoryColor(for colorID: String) -> Color {
        switch colorID {
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
        startDate: Calendar.current.date(from: DateComponents(hour: 9, minute: 0))!,
        endDate: Calendar.current.date(from: DateComponents(hour: 11, minute: 0))!
    )
    
    let category = Category(name: "Focus", emoji: "🎯", colorID: "blue")
    
    return ZStack {
        Color.black
        
        RadialBlockView(
            block: block,
            innerRadius: 80,
            outerRadius: 120,
            category: category
        )
        .frame(width: 240, height: 240)
    }
    .environmentObject(ThemeManager())
}
