// Features/Radial/Views/RadialBlockView.swift

import SwiftUI

struct RadialBlockView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let block: TimeBlock
    let innerRadius: CGFloat      // ring inner radius
    let outerRadius: CGFloat      // not used for drawing, but kept for consistency
    let category: Category?
    
    // Visual tuning
    private let arcThickness: CGFloat = 32      // thickness of the “pill”
    private let borderWidth: CGFloat = 2
    
    var body: some View {
        let bubbleArc = BubblyArcShape(
            startAngle: block.startAngle,
            endAngle: block.endAngle,
            radius: innerRadius + arcThickness / 2,
            lineWidth: arcThickness
        )
        
        ZStack {
            // Bubbly, soft, semi-transparent fill
            bubbleArc
                .fill(
                    LinearGradient(
                        colors: [
                            categoryColor.opacity(fillOpacity * 1.05),
                            categoryColor.opacity(fillOpacity)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: categoryColor.opacity(0.30), radius: 6)
            
            // Soft border (slight inner highlight + color edge)
            bubbleArc
                .stroke(
                    Color.white.opacity(0.20),
                    style: StrokeStyle(
                        lineWidth: borderWidth,
                        lineCap: .butt,
                        lineJoin: .round
                    )
                )
                .overlay(
                    bubbleArc
                        .stroke(
                            categoryColor.opacity(0.85),
                            style: StrokeStyle(
                                lineWidth: 0.75,
                                lineCap: .butt,
                                lineJoin: .round
                            )
                        )
                )
            
            // Completion overlay (still positioned in the arc)
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
    
    // MARK: - Arc Content

    private var arcContent: some View {
        // Use true sweep (handles midnight crossing)
        let sweep = sweepAngle
        
        // Midpoint *along the arc path*, not simple average
        var midAngle = block.startAngle + sweep / 2.0
        
        // Normalize to 0–360
        midAngle = midAngle.truncatingRemainder(dividingBy: 360)
        if midAngle < 0 { midAngle += 360 }
        
        let angleRadians = (midAngle - 90) * .pi / 180
        
        // Position in the middle of the arc thickness
        let contentRadius = innerRadius + (arcThickness / 2)
        let x = contentRadius * cos(angleRadians)
        let y = contentRadius * sin(angleRadians)
        
        // Keep content upright (no rotation around the tangent)
        return contentView
            .rotationEffect(.degrees(0))
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
        // Less transparent (more solid color) than before
        if block.isDone {
            return 0.45
        } else {
            return 0.70
        }
    }
    
    private var textColor: Color {
        themeManager.textPrimaryColor
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
        case "blue":   return Color(red: 0.4, green: 0.6, blue: 1.0)
        case "purple": return Color(red: 0.7, green: 0.5, blue: 1.0)
        case "pink":   return Color(red: 1.0, green: 0.5, blue: 0.7)
        case "orange": return Color(red: 1.0, green: 0.6, blue: 0.4)
        case "green":  return Color(red: 0.5, green: 0.9, blue: 0.6)
        case "teal":   return Color(red: 0.4, green: 0.8, blue: 0.9)
        default:       return themeManager.accent
        }
    }
}

// MARK: - Bubbly arc shape with rounded caps

/// Draws a single circular arc as a thick stroke with rounded caps,
/// giving a "pill" / bubbly look around the ring.
struct BubblyArcShape: Shape {
    /// Angles are in the radial system (0° = top, clockwise).
    let startAngle: Double
    let endAngle: Double
    let radius: CGFloat
    let lineWidth: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // Convert to SwiftUI coordinate system (0° = right, CCW)
        let start = Angle(degrees: startAngle - 90)
        let end   = Angle(degrees: endAngle - 90)
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: start,
            endAngle: end,
            clockwise: false
        )
        
        // Stroke with rounded caps to get the "bubble" ends
        return path.strokedPath(
            StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .butt,
                lineJoin: .round
            )
        )
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
