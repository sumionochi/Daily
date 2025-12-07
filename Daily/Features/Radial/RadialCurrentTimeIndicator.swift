// Features/Radial/RadialCurrentTimeIndicator.swift

import SwiftUI

struct RadialCurrentTimeIndicator: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let currentTime: Date
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    
    var body: some View {
        let angle = RadialLayoutEngine.angle(from: currentTime)
        
        ZStack {
            // Main line
            Rectangle()
                .fill(themeManager.accent)
                .frame(width: 2, height: outerRadius - innerRadius)
                .position(
                    RadialLayoutEngine.point(
                        at: angle,
                        radius: (innerRadius + outerRadius) / 2,
                        center: CGPoint(x: outerRadius, y: outerRadius)
                    )
                )
                .rotationEffect(RadialLayoutEngine.swiftUIAngle(angle))
            
            // Dot at outer edge
            Circle()
                .fill(themeManager.accent)
                .frame(width: 8, height: 8)
                .position(
                    RadialLayoutEngine.point(
                        at: angle,
                        radius: outerRadius,
                        center: CGPoint(x: outerRadius, y: outerRadius)
                    )
                )
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        RadialCurrentTimeIndicator(
            currentTime: Date(),
            innerRadius: 80,
            outerRadius: 120
        )
        .frame(width: 240, height: 240)
    }
    .environmentObject(ThemeManager())
}
