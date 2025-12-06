// Models/Domain/Task.swift

import Foundation

struct Task: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var notes: String?
    var estimatedDuration: Int // minutes
    var categoryID: UUID?
    var status: TaskStatus
    var priority: TaskPriority
    var dueDate: Date?
    var completedAt: Date?
    var sourceType: SourceType
    var externalID: String? // For synced tasks (Notion ID, Reminder ID, etc.)
    var tags: [String]
    var folder: String? // Inbox, Work, Personal, Someday
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        estimatedDuration: Int = 30,
        categoryID: UUID? = nil,
        status: TaskStatus = .pending,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        completedAt: Date? = nil,
        sourceType: SourceType = .manual,
        externalID: String? = nil,
        tags: [String] = [],
        folder: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.estimatedDuration = estimatedDuration
        self.categoryID = categoryID
        self.status = status
        self.priority = priority
        self.dueDate = dueDate
        self.completedAt = completedAt
        self.sourceType = sourceType
        self.externalID = externalID
        self.tags = tags
        self.folder = folder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed properties
    var isCompleted: Bool {
        status == .completed
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }
    
    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    var isDueTomorrow: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInTomorrow(dueDate)
    }
    
    // Helper methods
    mutating func complete() {
        status = .completed
        completedAt = Date()
        updatedAt = Date()
    }
    
    mutating func uncomplete() {
        status = .pending
        completedAt = nil
        updatedAt = Date()
    }
    
    mutating func cancel() {
        status = .cancelled
        updatedAt = Date()
    }
}
