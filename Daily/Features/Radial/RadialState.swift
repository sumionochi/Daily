//
//  RadialState.swift
//  Daily
//
//  Created by Aaditya Srivastava on 08/12/25.
//


// Features/Radial/Models/RadialState.swift

import Foundation
import UIKit

// MARK: - Radial State

enum RadialState: Equatable {
    case unfocused
    case focused(blockID: UUID)
    
    var isFocused: Bool {
        if case .focused = self {
            return true
        }
        return false
    }
    
    var focusedBlockID: UUID? {
        if case .focused(let blockID) = self {
            return blockID
        }
        return nil
    }
}

// MARK: - Interaction Mode

enum RadialInteractionMode {
    case idle
    case draggingBlock(blockID: UUID, originalStartTime: Date)
    case resizingBlockStart(blockID: UUID)
    case resizingBlockEnd(blockID: UUID)
    case longPressing(blockID: UUID)
    case swipingDay
}

// MARK: - Haptic Types

enum RadialHapticType {
    case blockFocus          // When block becomes focused
    case blockUnfocus        // When focus is cleared
    case timeSnap            // When dragging snaps to discrete time
    case dayChange           // When swiping to new day
    case blockEdit           // When edit sheet opens
    case blockDelete         // When block is deleted
    
    var style: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .blockFocus, .blockUnfocus:
            return .light
        case .timeSnap:
            return .rigid
        case .dayChange:
            return .medium
        case .blockEdit:
            return .light
        case .blockDelete:
            return .heavy
        }
    }
}

// MARK: - Time Snap Interval

enum TimeSnapInterval: Int {
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    
    var seconds: TimeInterval {
        TimeInterval(rawValue * 60)
    }
}

// MARK: - Day Statistics

struct DayStatistics {
    let totalScheduled: TimeInterval
    let categoryBreakdown: [(category: Category, duration: TimeInterval)]
    let completedCount: Int
    let totalCount: Int
    
    var totalScheduledFormatted: String {
        let hours = Int(totalScheduled) / 3600
        let minutes = (Int(totalScheduled) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount) * 100
    }
}
