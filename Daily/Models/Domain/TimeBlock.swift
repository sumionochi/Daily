// Models/Domain/TimeBlock.swift

import Foundation

struct TimeBlock: Identifiable, Codable, Equatable {
    let id: UUID
    var taskID: UUID? // Optional - can be a standalone block
    var title: String // Can be different from task title
    var emoji: String?
    var startDate: Date
    var endDate: Date
    var categoryID: UUID?
    var isDone: Bool
    var actualStartDate: Date?
    var actualEndDate: Date?
    var sourceType: SourceType
    var externalID: String? // For calendar events
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        taskID: UUID? = nil,
        title: String,
        emoji: String? = nil,
        startDate: Date,
        endDate: Date,
        categoryID: UUID? = nil,
        isDone: Bool = false,
        actualStartDate: Date? = nil,
        actualEndDate: Date? = nil,
        sourceType: SourceType = .manual,
        externalID: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.taskID = taskID
        self.title = title
        self.emoji = emoji
        self.startDate = startDate
        self.endDate = endDate
        self.categoryID = categoryID
        self.isDone = isDone
        self.actualStartDate = actualStartDate
        self.actualEndDate = actualEndDate
        self.sourceType = sourceType
        self.externalID = externalID
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed properties
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    var durationMinutes: Int {
        Int(duration / 60)
    }
    
    var actualDuration: TimeInterval? {
        guard let start = actualStartDate, let end = actualEndDate else { return nil }
        return end.timeIntervalSince(start)
    }
    
    var actualDurationMinutes: Int? {
        guard let duration = actualDuration else { return nil }
        return Int(duration / 60)
    }
    
    var isInProgress: Bool {
        guard let now = Date() as Date? else { return false }
        return now >= startDate && now < endDate
    }
    
    var isPast: Bool {
        endDate < Date()
    }
    
    var isFuture: Bool {
        startDate > Date()
    }
    
    var isFromCalendar: Bool {
        sourceType == .calendar
    }
    
    var isFromRoutine: Bool {
        sourceType == .routine
    }
    
    // Helper methods
    mutating func markDone() {
        isDone = true
        if actualStartDate == nil {
            actualStartDate = startDate
        }
        if actualEndDate == nil {
            actualEndDate = Date()
        }
        updatedAt = Date()
    }
    
    mutating func markUndone() {
        isDone = false
        actualStartDate = nil
        actualEndDate = nil
        updatedAt = Date()
    }
    
    mutating func startTimer() {
        actualStartDate = Date()
        updatedAt = Date()
    }
    
    mutating func stopTimer() {
        actualEndDate = Date()
        isDone = true
        updatedAt = Date()
    }
    
    func overlaps(with other: TimeBlock) -> Bool {
        return startDate < other.endDate && endDate > other.startDate
    }
}
