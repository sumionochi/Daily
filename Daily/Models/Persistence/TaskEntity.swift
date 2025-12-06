//
//  TaskEntity.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Models/Persistence/TaskEntity.swift

import Foundation
import SwiftData

@Model
final class TaskEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String?
    var estimatedDuration: Int
    var statusRaw: String
    var priorityRaw: Int
    var dueDate: Date?
    var completedAt: Date?
    var sourceTypeRaw: String
    var externalID: String?
    var tagsData: Data? // JSON encoded [String]
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    var category: CategoryEntity?
    
    @Relationship(deleteRule: .nullify, inverse: \TimeBlockEntity.task)
    var timeBlocks: [TimeBlockEntity]?
    
    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        estimatedDuration: Int = 30,
        statusRaw: String = TaskStatus.pending.rawValue,
        priorityRaw: Int = TaskPriority.medium.rawValue,
        dueDate: Date? = nil,
        completedAt: Date? = nil,
        sourceTypeRaw: String = SourceType.manual.rawValue,
        externalID: String? = nil,
        tagsData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.estimatedDuration = estimatedDuration
        self.statusRaw = statusRaw
        self.priorityRaw = priorityRaw
        self.dueDate = dueDate
        self.completedAt = completedAt
        self.sourceTypeRaw = sourceTypeRaw
        self.externalID = externalID
        self.tagsData = tagsData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed properties
    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
    
    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
    
    var sourceType: SourceType {
        get { SourceType(rawValue: sourceTypeRaw) ?? .manual }
        set { sourceTypeRaw = newValue.rawValue }
    }
    
    var tags: [String] {
        get {
            guard let data = tagsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            tagsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // Convert to domain model
    func toDomain() -> Task {
        Task(
            id: id,
            title: title,
            notes: notes,
            estimatedDuration: estimatedDuration,
            categoryID: category?.id,
            status: status,
            priority: priority,
            dueDate: dueDate,
            completedAt: completedAt,
            sourceType: sourceType,
            externalID: externalID,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    // Update from domain model
    func update(from task: Task) {
        self.title = task.title
        self.notes = task.notes
        self.estimatedDuration = task.estimatedDuration
        self.status = task.status
        self.priority = task.priority
        self.dueDate = task.dueDate
        self.completedAt = task.completedAt
        self.sourceType = task.sourceType
        self.externalID = task.externalID
        self.tags = task.tags
        self.updatedAt = Date()
    }
    
    // Create from domain model
    static func from(_ task: Task) -> TaskEntity {
        let entity = TaskEntity(
            id: task.id,
            title: task.title,
            notes: task.notes,
            estimatedDuration: task.estimatedDuration,
            statusRaw: task.status.rawValue,
            priorityRaw: task.priority.rawValue,
            dueDate: task.dueDate,
            completedAt: task.completedAt,
            sourceTypeRaw: task.sourceType.rawValue,
            externalID: task.externalID,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt
        )
        entity.tags = task.tags
        return entity
    }
}