// Features/Radial/Views/AdaptiveArcText.swift

import SwiftUI

struct AdaptiveArcText: View {
    let text: String
    let sweepAngle: Double
    let color: Color
    
    var body: some View {
        Text(text)
            .font(adaptiveFont)
            .foregroundColor(color)
            .lineLimit(lineLimit)
            .multilineTextAlignment(.center)
            .frame(width: adaptiveWidth)
            .minimumScaleFactor(0.7)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Adaptive Properties
    
    private var adaptiveFont: Font {
        if sweepAngle > 90 {
            return .system(size: 12, weight: .semibold, design: .rounded)
        } else if sweepAngle > 60 {
            return .system(size: 11, weight: .medium, design: .rounded)
        } else if sweepAngle > 30 {
            return .system(size: 10, weight: .medium, design: .rounded)
        } else {
            return .system(size: 9, weight: .medium, design: .rounded)
        }
    }
    
    private var adaptiveWidth: CGFloat {
        if sweepAngle > 90 {
            return 80
        } else if sweepAngle > 60 {
            return 70
        } else if sweepAngle > 30 {
            return 60
        } else {
            return 50
        }
    }
    
    private var lineLimit: Int {
        if sweepAngle > 90 {
            return 3
        } else if sweepAngle > 60 {
            return 2
        } else {
            return 1
        }
    }
}

// MARK: - Adaptive Emoji

struct AdaptiveArcEmoji: View {
    let emoji: String
    let sweepAngle: Double
    
    var body: some View {
        Text(emoji)
            .font(.system(size: emojiSize))
    }
    
    private var emojiSize: CGFloat {
        // base size – change this number to make the emoji bigger/smaller
        let base: CGFloat = 28

        // (Optional) slightly scale with block length
        if sweepAngle > 90 { return base + 4 }
        if sweepAngle > 45 { return base + 2 }
        return base
    }
}

#Preview {
    VStack(spacing: 20) {
        // Large arc (90°+)
        VStack {
            AdaptiveArcEmoji(emoji: "🎯", sweepAngle: 120)
            AdaptiveArcText(
                text: "Deep Work Session",
                sweepAngle: 120,
                color: .white
            )
        }
        .padding()
        .background(Color.blue.opacity(0.3))
        .cornerRadius(12)
        
        // Medium arc (60°)
        VStack {
            AdaptiveArcEmoji(emoji: "☕", sweepAngle: 60)
            AdaptiveArcText(
                text: "Coffee Break",
                sweepAngle: 60,
                color: .white
            )
        }
        .padding()
        .background(Color.orange.opacity(0.3))
        .cornerRadius(12)
        
        // Small arc (30°)
        VStack {
            AdaptiveArcEmoji(emoji: "🏃", sweepAngle: 30)
            AdaptiveArcText(
                text: "Quick Break",
                sweepAngle: 30,
                color: .white
            )
        }
        .padding()
        .background(Color.green.opacity(0.3))
        .cornerRadius(12)
    }
    .padding()
    .background(Color.black)
}
