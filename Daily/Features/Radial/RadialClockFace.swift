// Features/Radial/RadialClockFace.swift

import SwiftUI

struct RadialClockFace: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let radius: CGFloat
    
    var body: some View {
        ZStack {
            // All hour ticks (24 total)
            ForEach(0..<96, id: \.self) { index in
                // 4 ticks per hour = 96 total for 24 hours
                let isHourTick = index % 4 == 0
                let isMainTick = index % 12 == 0 // Every 3 hours
                
                tickMark(
                    index: index,
                    isHour: isHourTick,
                    isMain: isMainTick
                )
            }
            
            // Hour labels at main positions (00, 03, 06, 09, 12, 15, 18, 21)
            ForEach([0, 3, 6, 9, 12, 15, 18, 21], id: \.self) { hour in
                hourLabel(for: hour)
            }
        }
    }
    
    // MARK: - Tick Mark
    
    private func tickMark(index: Int, isHour: Bool, isMain: Bool) -> some View {
        let angle = Double(index) * (360.0 / 96.0) - 90 // Start at top
        let angleRadians = angle * .pi / 180
        
        // Tick dimensions based on type
        let tickLength: CGFloat = isMain ? 16 : (isHour ? 12 : 8)
        let tickWidth: CGFloat = isMain ? 2.5 : (isHour ? 2 : 1.5)
        let tickOpacity: Double = isMain ? 0.7 : (isHour ? 0.5 : 0.3)
        
        // Position at edge of circle
        let tickRadius = radius - tickLength / 2
        let x = tickRadius * cos(angleRadians)
        let y = tickRadius * sin(angleRadians)
        
        return Rectangle()
            .fill(themeManager.textPrimaryColor.opacity(tickOpacity))
            .frame(width: tickWidth, height: tickLength)
            .rotationEffect(.degrees(angle + 90)) // Orient radially
            .offset(x: x, y: y)
    }
    
    // MARK: - Hour Label
    
    private func hourLabel(for hour: Int) -> some View {
        let angle = Double(hour) * 15.0 - 90 // 15° per hour, start at top
        let angleRadians = angle * .pi / 180
        
        // Position inside the ticks
        let labelRadius = radius - 32
        let x = labelRadius * cos(angleRadians)
        let y = labelRadius * sin(angleRadians)
        
        return Text(String(format: "%02d", hour))
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(themeManager.textSecondaryColor.opacity(0.8))
            .offset(x: x, y: y)
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        RadialClockFace(radius: 160)
            .frame(width: 320, height: 320)
    }
    .environmentObject(ThemeManager())
}
