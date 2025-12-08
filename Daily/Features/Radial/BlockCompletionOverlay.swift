// Features/Radial/Views/BlockCompletionOverlay.swift

import SwiftUI

struct BlockCompletionOverlay: View {
    let isDone: Bool
    let categoryColor: Color
    let innerRadius: CGFloat
    let arcThickness: CGFloat
    let startAngle: Double
    let endAngle: Double
    
    var body: some View {
        if isDone {
            ZStack {
                // Checkmark in center
                checkmarkIcon
            }
        }
    }
    
    // MARK: - Checkmark Icon
    
    private var checkmarkIcon: some View {
        let midAngle = (startAngle + endAngle) / 2
        let angleRadians = (midAngle - 90) * .pi / 180
        
        let contentRadius = innerRadius + (arcThickness / 2)
        let x = contentRadius * cos(angleRadians)
        let y = contentRadius * sin(angleRadians)
        
        return Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 16))
            .foregroundColor(.green)
            .background(
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 24, height: 24)
            )
            .offset(x: x, y: y)
    }
}

// MARK: - Strikethrough Overlay

struct BlockStrikethroughOverlay: View {
    let isDone: Bool
    let categoryColor: Color
    let startAngle: Double
    let endAngle: Double
    let innerRadius: CGFloat
    let arcThickness: CGFloat
    
    var body: some View {
        if isDone {
            // Diagonal line through the arc
            strikethroughLine
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
        }
    }
    
    private var strikethroughLine: some Shape {
        Path { path in
            let midAngle = (startAngle + endAngle) / 2
            let angleRadians = (midAngle - 90) * .pi / 180
            
            let innerPoint = CGPoint(
                x: innerRadius * cos(angleRadians),
                y: innerRadius * sin(angleRadians)
            )
            
            let outerPoint = CGPoint(
                x: (innerRadius + arcThickness) * cos(angleRadians),
                y: (innerRadius + arcThickness) * sin(angleRadians)
            )
            
            path.move(to: innerPoint)
            path.addLine(to: outerPoint)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        // Sample arc with completion overlay
        Circle()
            .trim(from: 0, to: 0.3)
            .stroke(Color.blue, lineWidth: 32)
            .frame(width: 300, height: 300)
        
        BlockCompletionOverlay(
            isDone: true,
            categoryColor: .blue,
            innerRadius: 118,
            arcThickness: 32,
            startAngle: 0,
            endAngle: 108
        )
    }
}
