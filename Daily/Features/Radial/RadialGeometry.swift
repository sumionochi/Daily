//
//  RadialGeometry.swift
//  Daily
//
//  Created by Aaditya Srivastava on 08/12/25.
//


// Features/Radial/Utilities/RadialGeometry.swift

import Foundation
import SwiftUI

struct RadialGeometry {
    
    // MARK: - Time <-> Angle Conversion
    
    /// Converts a time to an angle (0° = midnight at top, clockwise)
    static func timeToAngle(_ date: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0)
        let second = Double(components.second ?? 0)
        
        let totalHours = hour + minute / 60.0 + second / 3600.0
        
        // Convert to angle (0-360°, where 0° = midnight at top)
        let angle = (totalHours / 24.0) * 360.0
        
        return angle
    }
    
    /// Converts an angle to a time on a specific date
    static func angleToTime(_ angle: Double, on date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Normalize angle to 0-360
        let normalizedAngle = angle.truncatingRemainder(dividingBy: 360)
        let positiveAngle = normalizedAngle < 0 ? normalizedAngle + 360 : normalizedAngle
        
        // Convert angle to hours
        let hours = (positiveAngle / 360.0) * 24.0
        let hoursPart = Int(hours)
        let minutesPart = Int((hours - Double(hoursPart)) * 60)
        
        components.hour = hoursPart
        components.minute = minutesPart
        components.second = 0
        
        return calendar.date(from: components) ?? date
    }
    
    // MARK: - Point <-> Angle Conversion
    
    /// Converts a CGPoint (relative to radial center) to an angle
    static func pointToAngle(_ point: CGPoint, center: CGPoint) -> Double {
        let dx = point.x - center.x
        let dy = point.y - center.y
        
        // atan2 gives angle from positive X-axis, counterclockwise
        let radians = atan2(dy, dx)
        
        // Convert to degrees
        var degrees = radians * 180.0 / .pi
        
        // Adjust to our coordinate system (0° = top, clockwise)
        degrees = 90 - degrees
        
        // Normalize to 0-360
        if degrees < 0 {
            degrees += 360
        }
        
        return degrees
    }
    
    /// Converts an angle to a point on a circle
    static func angleToPoint(_ angle: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        // Convert to our coordinate system (0° = top, clockwise)
        let adjustedAngle = (angle - 90) * .pi / 180.0
        
        let x = center.x + radius * cos(adjustedAngle)
        let y = center.y + radius * sin(adjustedAngle)
        
        return CGPoint(x: x, y: y)
    }
    
    // MARK: - Hit Testing
    
    /// Check if a point hits a radial ring area
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
    
    /// Check if a point hits a specific arc segment
    static func hitTestArc(
        point: CGPoint,
        center: CGPoint,
        innerRadius: CGFloat,
        outerRadius: CGFloat,
        startAngle: Double,
        endAngle: Double
    ) -> Bool {
        // First check if in ring
        guard hitTestRing(point: point, center: center, innerRadius: innerRadius, outerRadius: outerRadius) else {
            return false
        }
        
        // Then check if in angular range
        let pointAngle = pointToAngle(point, center: center)
        
        // Normalize angles
        var start = startAngle.truncatingRemainder(dividingBy: 360)
        var end = endAngle.truncatingRemainder(dividingBy: 360)
        var angle = pointAngle.truncatingRemainder(dividingBy: 360)
        
        if start < 0 { start += 360 }
        if end < 0 { end += 360 }
        if angle < 0 { angle += 360 }
        
        // Handle wrap-around
        if end < start {
            return angle >= start || angle <= end
        } else {
            return angle >= start && angle <= end
        }
    }
    
    // MARK: - Distance Calculations
    
    /// Calculate distance from point to center
    static func distanceToCenter(_ point: CGPoint, center: CGPoint) -> CGFloat {
        let dx = point.x - center.x
        let dy = point.y - center.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Check if a point is in the inner circle (inner place)
    static func isInInnerPlace(point: CGPoint, center: CGPoint, innerRadius: CGFloat) -> Bool {
        distanceToCenter(point, center: center) < innerRadius
    }
}