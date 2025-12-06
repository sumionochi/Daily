// Models/Persistence/RoutineEntity.swift

import Foundation
import SwiftData

@Model
final class RoutineEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var emoji: String?
    var duration: Int
    var preferredStartHour: Int?
    var preferredStartMinute: Int?
    var recurrenceFrequencyRaw: String
    var recurrenceInterval: Int
    var recurrenceDaysOfWeekData: Data?
    var recurrenceDayOfMonth: Int?
    var recurrenceEndDate: Date?
    var isEnabled: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    var category: CategoryEntity?
    
    init(
        id: UUID = UUID(),
        title: String,
        emoji: String? = nil,
        duration: Int = 30,
        preferredStartHour: Int? = nil,
        preferredStartMinute: Int? = nil,
        recurrenceFrequencyRaw: String = RecurrenceFrequency.daily.rawValue,
        recurrenceInterval: Int = 1,
        recurrenceDaysOfWeekData: Data? = nil,
        recurrenceDayOfMonth: Int? = nil,
        recurrenceEndDate: Date? = nil,
        isEnabled: Bool = true,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.duration = duration
        self.preferredStartHour = preferredStartHour
        self.preferredStartMinute = preferredStartMinute
        self.recurrenceFrequencyRaw = recurrenceFrequencyRaw
        self.recurrenceInterval = recurrenceInterval
        self.recurrenceDaysOfWeekData = recurrenceDaysOfWeekData
        self.recurrenceDayOfMonth = recurrenceDayOfMonth
        self.recurrenceEndDate = recurrenceEndDate
        self.isEnabled = isEnabled
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed properties
    var preferredStartTime: DateComponents? {
        get {
            guard let hour = preferredStartHour, let minute = preferredStartMinute else { return nil }
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            return components
        }
        set {
            preferredStartHour = newValue?.hour
            preferredStartMinute = newValue?.minute
        }
    }
    
    var recurrenceRule: RecurrenceRule {
        get {
            let frequency = RecurrenceFrequency(rawValue: recurrenceFrequencyRaw) ?? .daily
            let daysOfWeek: [Int]? = {
                guard let data = recurrenceDaysOfWeekData else { return nil }
                return try? JSONDecoder().decode([Int].self, from: data)
            }()
            
            return RecurrenceRule(
                frequency: frequency,
                interval: recurrenceInterval,
                daysOfWeek: daysOfWeek,
                dayOfMonth: recurrenceDayOfMonth,
                endDate: recurrenceEndDate
            )
        }
        set {
            recurrenceFrequencyRaw = newValue.frequency.rawValue
            recurrenceInterval = newValue.interval
            recurrenceDaysOfWeekData = try? JSONEncoder().encode(newValue.daysOfWeek)
            recurrenceDayOfMonth = newValue.dayOfMonth
            recurrenceEndDate = newValue.endDate
        }
    }
    
    // Convert to domain model
    func toDomain() -> Routine {
        Routine(
            id: id,
            title: title,
            emoji: emoji,
            categoryID: category?.id,
            duration: duration,
            preferredStartTime: preferredStartTime,
            recurrenceRule: recurrenceRule,
            isEnabled: isEnabled,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    // Update from domain model
    func update(from routine: Routine) {
        self.title = routine.title
        self.emoji = routine.emoji
        self.duration = routine.duration
        self.preferredStartTime = routine.preferredStartTime
        self.recurrenceRule = routine.recurrenceRule
        self.isEnabled = routine.isEnabled
        self.notes = routine.notes
        self.updatedAt = Date()
    }
    
    // Create from domain model
    static func from(_ routine: Routine) -> RoutineEntity {
        let entity = RoutineEntity(
            id: routine.id,
            title: routine.title,
            emoji: routine.emoji,
            duration: routine.duration,
            preferredStartHour: routine.preferredStartTime?.hour,
            preferredStartMinute: routine.preferredStartTime?.minute,
            recurrenceFrequencyRaw: routine.recurrenceRule.frequency.rawValue,
            recurrenceInterval: routine.recurrenceRule.interval,
            recurrenceDayOfMonth: routine.recurrenceRule.dayOfMonth,
            recurrenceEndDate: routine.recurrenceRule.endDate,
            isEnabled: routine.isEnabled,
            notes: routine.notes,
            createdAt: routine.createdAt,
            updatedAt: routine.updatedAt
        )
        entity.recurrenceDaysOfWeekData = try? JSONEncoder().encode(routine.recurrenceRule.daysOfWeek)
        return entity
    }
}
