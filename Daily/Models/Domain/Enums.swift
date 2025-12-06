// Models/Domain/Enums.swift

import Foundation

// MARK: - Task Status

enum TaskStatus: String, Codable, CaseIterable {
    case pending
    case inProgress
    case completed
    case cancelled
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        }
    }
}

// MARK: - Source Type

enum SourceType: String, Codable, CaseIterable {
    case manual
    case notion
    case reminders
    case calendar
    case routine
    
    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .notion: return "Notion"
        case .reminders: return "Reminders"
        case .calendar: return "Calendar"
        case .routine: return "Routine"
        }
    }
}

// MARK: - Recurrence Rule

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily
    case weekdays
    case weekly
    case monthly
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

struct RecurrenceRule: Codable, Equatable {
    let frequency: RecurrenceFrequency
    let interval: Int // Every N days/weeks/months
    let daysOfWeek: [Int]? // 1=Sunday, 2=Monday, etc. (for weekly)
    let dayOfMonth: Int? // 1-31 (for monthly)
    let endDate: Date?
    
    init(
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        daysOfWeek: [Int]? = nil,
        dayOfMonth: Int? = nil,
        endDate: Date? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
        self.endDate = endDate
    }
    
    // Convenience initializers
    static var daily: RecurrenceRule {
        RecurrenceRule(frequency: .daily)
    }
    
    static var weekdays: RecurrenceRule {
        RecurrenceRule(frequency: .weekdays, daysOfWeek: [2, 3, 4, 5, 6]) // Mon-Fri
    }
    
    static func weekly(on days: [Int]) -> RecurrenceRule {
        RecurrenceRule(frequency: .weekly, daysOfWeek: days)
    }
    
    static func monthly(day: Int) -> RecurrenceRule {
        RecurrenceRule(frequency: .monthly, dayOfMonth: day)
    }
}

// MARK: - Priority

enum TaskPriority: Int, Codable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    case urgent = 3
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "equal"
        case .high: return "arrow.up"
        case .urgent: return "exclamationmark.2"
        }
    }
}
