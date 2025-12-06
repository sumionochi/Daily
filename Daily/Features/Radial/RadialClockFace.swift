//
//  RadialClockFace.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Features/Radial/RadialClockFace.swift

import SwiftUI

struct RadialClockFace: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let radius: CGFloat
    let showLabels: Bool
    
    init(radius: CGFloat, showLabels: Bool = true) {
        self.radius = radius
        self.showLabels = showLabels
    }
    
    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(themeManager.borderColor.opacity(0.3), lineWidth: 1)
                .frame(width: radius * 2, height: radius * 2)
            
            // Hour markers
            ForEach(0..<24, id: \.self) { hour in
                hourMarker(for: hour)
            }
            
            // Hour labels (every 3 hours)
            if showLabels {
                ForEach([0, 3, 6, 9, 12, 15, 18, 21], id: \.self) { hour in
                    hourLabel(for: hour)
                }
            }
        }
    }
    
    private func hourMarker(for hour: Int) -> some View {
        let angle = RadialLayoutEngine.angle(fromHour: hour)
        let isMainHour = hour % 3 == 0
        let markerLength: CGFloat = isMainHour ? 12 : 6
        let markerWidth: CGFloat = isMainHour ? 2 : 1
        
        return Rectangle()
            .fill(themeManager.textTertiaryColor.opacity(isMainHour ? 0.6 : 0.3))
            .frame(width: markerWidth, height: markerLength)
            .position(
                RadialLayoutEngine.point(
                    at: angle,
                    radius: radius - (markerLength / 2),
                    center: CGPoint(x: radius, y: radius)
                )
            )
            .rotationEffect(RadialLayoutEngine.swiftUIAngle(angle))
    }
    
    private func hourLabel(for hour: Int) -> some View {
        let angle = RadialLayoutEngine.angle(fromHour: hour)
        let label = RadialLayoutEngine.timeLabel(for: angle, format: .hourOnly)
        
        return Text(label)
            .font(themeManager.captionFont)
            .foregroundColor(themeManager.textTertiaryColor)
            .frame(width: 40, height: 20)
            .position(
                RadialLayoutEngine.point(
                    at: angle,
                    radius: radius - 30,
                    center: CGPoint(x: radius, y: radius)
                )
            )
    }
}

#Preview {
    ZStack {
        Color.black
        
        RadialClockFace(radius: 120)
    }
    .environmentObject(ThemeManager())
}