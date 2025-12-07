// Features/Radial/RadialLayoutEngine.swift

import Foundation
import SwiftUI

struct RadialLayoutEngine {
    
    // MARK: - Constants
    
    static let hoursInDay: Double = 24
    static let degreesInCircle: Double = 360
    static let degreesPerHour: Double = degreesInCircle / hoursInDay  // 15° per hour
    static let degreesPerMinute: Double = degreesPerHour / 60  // 0.25° per minute
    
    // 12 o'clock (top) is 0° in our system (matches clock convention)
    // We rotate -90° from standard SwiftUI coordinate system where 0° is 3 o'clock
    static let rotationOffset: Double = -90
    
    // MARK: - Time to Angle Conversion
    
    /// Convert time to degrees (0° = midnight at top, clockwise)
    static func angle(from date: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        
        let hours = Double(components.hour ?? 0)
        let minutes = Double(components.minute ?? 0)
        let seconds = Double(components.second ?? 0)
        
        let totalMinutes = (hours * 60) + minutes + (seconds / 60)
        let angle = (totalMinutes / (hoursInDay * 60)) * degreesInCircle
        
        return angle
    }
    
    /// Convert hour (0-23) to degrees
    static func angle(fromHour hour: Int, minute: Int = 0) -> Double {
        let totalMinutes = Double(hour * 60 + minute)
        return (totalMinutes / (hoursInDay * 60)) * degreesInCircle
    }
    
    /// Get angle for TimeBlock start
    static func startAngle(for block: TimeBlock) -> Double {
        angle(from: block.startDate)
    }
    
    /// Get angle for TimeBlock end
    static func endAngle(for block: TimeBlock) -> Double {
        angle(from: block.endDate)
    }
    
    /// Get sweep angle (duration) for TimeBlock
    static func sweepAngle(for block: TimeBlock) -> Double {
        let start = startAngle(for: block)
        let end = endAngle(for: block)
        
        // Handle midnight crossing
        if end < start {
            return (degreesInCircle - start) + end
        }
        
        return end - start
    }
    
    // MARK: - Angle to Time Conversion
    
    /// Convert angle back to time components
    static func timeComponents(from angle: Double) -> (hour: Int, minute: Int) {
        let normalizedAngle = angle.truncatingRemainder(dividingBy: degreesInCircle)
        let totalMinutes = (normalizedAngle / degreesInCircle) * (hoursInDay * 60)
        
        let hours = Int(totalMinutes / 60)
        let minutes = Int(totalMinutes.truncatingRemainder(dividingBy: 60))
        
        return (hour: hours, minute: minutes)
    }
    
    /// Snap angle to interval (in minutes)
    static func snapAngle(_ angle: Double, toMinutes interval: Int) -> Double {
        let totalMinutes = (angle / degreesInCircle) * (hoursInDay * 60)
        let snappedMinutes = round(totalMinutes / Double(interval)) * Double(interval)
        return (snappedMinutes / (hoursInDay * 60)) * degreesInCircle
    }
    
    // MARK: - SwiftUI Geometry Helpers
    
    /// Convert our angle system to SwiftUI's Angle
    static func swiftUIAngle(_ degrees: Double) -> Angle {
        Angle(degrees: degrees + rotationOffset)
    }
    
    /// Get center point for angle at given radius
    static func point(
        at angle: Double,
        radius: CGFloat,
        center: CGPoint
    ) -> CGPoint {
        let radians = (angle + rotationOffset) * .pi / 180
        let x = center.x + radius * cos(radians)
        let y = center.y + radius * sin(radians)
        return CGPoint(x: x, y: y)
    }
    
    /// Check if angle is between start and end (clockwise)
    static func isAngle(_ angle: Double, between start: Double, and end: Double) -> Bool {
        let normalized = angle.truncatingRemainder(dividingBy: degreesInCircle)
        let normalizedStart = start.truncatingRemainder(dividingBy: degreesInCircle)
        let normalizedEnd = end.truncatingRemainder(dividingBy: degreesInCircle)
        
        if normalizedStart <= normalizedEnd {
            return normalized >= normalizedStart && normalized <= normalizedEnd
        } else {
            // Crosses midnight
            return normalized >= normalizedStart || normalized <= normalizedEnd
        }
    }
    
    // MARK: - Block Validation
    
    /// Check if block crosses midnight
    static func crossesMidnight(_ block: TimeBlock) -> Bool {
        endAngle(for: block) < startAngle(for: block)
    }
    
    /// Get display label for time
    static func timeLabel(for angle: Double, format: TimeFormat = .hour12) -> String {
        let (hour, minute) = timeComponents(from: angle)
        
        switch format {
        case .hour24:
            return String(format: "%02d:%02d", hour, minute)
        case .hour12:
            let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            let period = hour < 12 ? "AM" : "PM"
            if minute == 0 {
                return "\(hour12)\(period)"
            }
            return "\(hour12):\(String(format: "%02d", minute))\(period)"
        case .hourOnly:
            if hour == 0 {
                return "12AM"
            } else if hour < 12 {
                return "\(hour)AM"
            } else if hour == 12 {
                return "12PM"
            } else {
                return "\(hour - 12)PM"
            }
        }
    }
    
    enum TimeFormat {
        case hour24      // 14:30
        case hour12      // 2:30PM
        case hourOnly    // 2PM
    }
}

// MARK: - Helper Extensions

extension TimeBlock {
    var startAngle: Double {
        RadialLayoutEngine.startAngle(for: self)
    }
    
    var endAngle: Double {
        RadialLayoutEngine.endAngle(for: self)
    }
    
    var sweepAngle: Double {
        RadialLayoutEngine.sweepAngle(for: self)
    }
    
    var crossesMidnight: Bool {
        RadialLayoutEngine.crossesMidnight(self)
    }
}
