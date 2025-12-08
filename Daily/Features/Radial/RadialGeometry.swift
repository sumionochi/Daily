// Features/Radial/Utilities/RadialGeometry.swift

import Foundation
import SwiftUI

struct RadialGeometry {
    
    // MARK: - Time <-> Angle Conversion
    // 0° = midnight at top, 90° = 6am (right), 180° = noon (bottom), 270° = 6pm (left)
    
    static func timeToAngle(_ date: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        
        let hour   = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0)
        let second = Double(components.second ?? 0)
        
        let totalHours = hour + minute / 60.0 + second / 3600.0
        return (totalHours / 24.0) * 360.0
    }
    
    static func angleToTime(_ angle: Double, on date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Normalize angle to 0–360
        let normalizedAngle = angle.truncatingRemainder(dividingBy: 360)
        let positiveAngle = normalizedAngle < 0 ? normalizedAngle + 360 : normalizedAngle
        
        let hours = (positiveAngle / 360.0) * 24.0
        let hoursPart   = Int(hours)
        let minutesPart = Int((hours - Double(hoursPart)) * 60)
        
        components.hour   = hoursPart
        components.minute = minutesPart
        components.second = 0
        
        return calendar.date(from: components) ?? date
    }
    
    // MARK: - Point <-> Angle Conversion
    
    /// Converts a CGPoint (in SwiftUI coordinates) to an angle in our system:
    /// 0° = top, 90° = right, 180° = bottom, 270° = left (clockwise)
    static func pointToAngle(_ point: CGPoint, center: CGPoint) -> Double {
        let dx = point.x - center.x
        let dy = point.y - center.y
        
        // atan2 gives angle from +X axis, CCW, in radians
        let radians = atan2(dy, dx)
        var degrees = radians * 180.0 / .pi
        
        // Our convention: 0° at top, clockwise
        // angleToPoint uses (angle - 90°), so inverse is +90°
        degrees += 90
        
        // Normalize to 0–360
        if degrees < 0 {
            degrees += 360
        } else if degrees >= 360 {
            degrees -= 360
        }
        
        return degrees
    }
    
    /// Converts an angle in our system (0° = top) to a point on a circle.
    static func angleToPoint(_ angle: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        // Same convention: 0° = top, clockwise
        let adjustedAngle = (angle - 90) * .pi / 180.0
        let x = center.x + radius * cos(adjustedAngle)
        let y = center.y + radius * sin(adjustedAngle)
        return CGPoint(x: x, y: y)
    }
    
    // MARK: - Hit Testing
    
    static func hitTestRing(
        point: CGPoint,
        center: CGPoint,
        innerRadius: CGFloat,
        outerRadius: CGFloat
    ) -> Bool {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        
        return distance >= innerRadius && distance <= outerRadius
    }
    
    static func hitTestArc(
        point: CGPoint,
        center: CGPoint,
        innerRadius: CGFloat,
        outerRadius: CGFloat,
        startAngle: Double,
        endAngle: Double
    ) -> Bool {
        guard hitTestRing(point: point,
                          center: center,
                          innerRadius: innerRadius,
                          outerRadius: outerRadius) else {
            return false
        }
        
        let pointAngle = pointToAngle(point, center: center)
        
        var start = startAngle.truncatingRemainder(dividingBy: 360)
        var end   = endAngle.truncatingRemainder(dividingBy: 360)
        var angle = pointAngle.truncatingRemainder(dividingBy: 360)
        
        if start < 0 { start += 360 }
        if end   < 0 { end   += 360 }
        if angle < 0 { angle += 360 }
        
        if end < start {
            // Wraps past midnight
            return angle >= start || angle <= end
        } else {
            return angle >= start && angle <= end
        }
    }
    
    // MARK: - Distance
    
    static func distanceToCenter(_ point: CGPoint, center: CGPoint) -> CGFloat {
        let dx = point.x - center.x
        let dy = point.y - center.y
        return sqrt(dx * dx + dy * dy)
    }
    
    static func isInInnerPlace(point: CGPoint, center: CGPoint, innerRadius: CGFloat) -> Bool {
        distanceToCenter(point, center: center) < innerRadius
    }
}
