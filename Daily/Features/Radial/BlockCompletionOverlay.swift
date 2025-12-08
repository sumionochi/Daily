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
            checkmarkIcon
        }
    }
    
    // MARK: - Checkmark Icon
    
    private var checkmarkIcon: some View {
        let mid = midAngleAlongArc(start: startAngle, end: endAngle)
        let angleRadians = (mid - 90) * .pi / 180
        
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
    
    // Shared helper
    private func midAngleAlongArc(start: Double, end: Double) -> Double {
        var sweep = end - start
        if sweep < 0 { sweep += 360 }
        var mid = start + sweep / 2
        mid = mid.truncatingRemainder(dividingBy: 360)
        if mid < 0 { mid += 360 }
        return mid
    }
}

struct BlockStrikethroughOverlay: View {
    let isDone: Bool
    let categoryColor: Color
    let startAngle: Double
    let endAngle: Double
    let innerRadius: CGFloat
    let arcThickness: CGFloat
    
    var body: some View {
        if isDone {
            strikethroughLine
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
        }
    }
    
    private var strikethroughLine: some Shape {
        Path { path in
            let mid = midAngleAlongArc(start: startAngle, end: endAngle)
            let angleRadians = (mid - 90) * .pi / 180
            
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
    
    private func midAngleAlongArc(start: Double, end: Double) -> Double {
        var sweep = end - start
        if sweep < 0 { sweep += 360 }
        var mid = start + sweep / 2
        mid = mid.truncatingRemainder(dividingBy: 360)
        if mid < 0 { mid += 360 }
        return mid
    }
}
