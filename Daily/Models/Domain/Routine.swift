// Models/Domain/Routine.swift

import Foundation

struct Routine: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var emoji: String?
    var categoryID: UUID?
    var duration: Int // minutes
    var preferredStartTime: DateComponents? // Hour and minute for preferred start
    var recurrenceRule: RecurrenceRule
    var isEnabled: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        emoji: String? = nil,
        categoryID: UUID? = nil,
        duration: Int = 30,
        preferredStartTime: DateComponents? = nil,
        recurrenceRule: RecurrenceRule = .daily,
        isEnabled: Bool = true,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.categoryID = categoryID
        self.duration = duration
        self.preferredStartTime = preferredStartTime
        self.recurrenceRule = recurrenceRule
        self.isEnabled = isEnabled
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Helper methods
    func shouldOccurOn(date: Date) -> Bool {
        guard isEnabled else { return false }
        
        // Check end date
        if let endDate = recurrenceRule.endDate, date > endDate {
            return false
        }
        
        let calendar = Calendar.current
        
        switch recurrenceRule.frequency {
        case .daily:
            return true
            
        case .weekdays:
            let weekday = calendar.component(.weekday, from: date)
            return (2...6).contains(weekday) // Mon-Fri
            
        case .weekly:
            guard let daysOfWeek = recurrenceRule.daysOfWeek else { return false }
            let weekday = calendar.component(.weekday, from: date)
            return daysOfWeek.contains(weekday)
            
        case .monthly:
            guard let dayOfMonth = recurrenceRule.dayOfMonth else { return false }
            let day = calendar.component(.day, from: date)
            return day == dayOfMonth
        }
    }
    
    func generateBlockFor(date: Date) -> TimeBlock? {
        guard shouldOccurOn(date: date) else { return nil }
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Apply preferred start time or default to 9 AM
        if let preferredTime = preferredStartTime {
            components.hour = preferredTime.hour ?? 9
            components.minute = preferredTime.minute ?? 0
        } else {
            components.hour = 9
            components.minute = 0
        }
        
        guard let startDate = calendar.date(from: components) else { return nil }
        let endDate = startDate.addingTimeInterval(TimeInterval(duration * 60))
        
        return TimeBlock(
            taskID: nil,
            title: title,
            emoji: emoji,
            startDate: startDate,
            endDate: endDate,
            categoryID: categoryID,
            sourceType: .routine,
            notes: notes
        )
    }
}
