//
//  TimeBlockEntity.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Models/Persistence/TimeBlockEntity.swift

import Foundation
import SwiftData

@Model
final class TimeBlockEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var emoji: String?
    var startDate: Date
    var endDate: Date
    var isDone: Bool
    var actualStartDate: Date?
    var actualEndDate: Date?
    var sourceTypeRaw: String
    var externalID: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    var task: TaskEntity?
    var category: CategoryEntity?
    var dayPlan: DayPlanEntity?
    
    init(
        id: UUID = UUID(),
        title: String,
        emoji: String? = nil,
        startDate: Date,
        endDate: Date,
        isDone: Bool = false,
        actualStartDate: Date? = nil,
        actualEndDate: Date? = nil,
        sourceTypeRaw: String = SourceType.manual.rawValue,
        externalID: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.startDate = startDate
        self.endDate = endDate
        self.isDone = isDone
        self.actualStartDate = actualStartDate
        self.actualEndDate = actualEndDate
        self.sourceTypeRaw = sourceTypeRaw
        self.externalID = externalID
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed properties
    var sourceType: SourceType {
        get { SourceType(rawValue: sourceTypeRaw) ?? .manual }
        set { sourceTypeRaw = newValue.rawValue }
    }
    
    // Convert to domain model
    func toDomain() -> TimeBlock {
        TimeBlock(
            id: id,
            taskID: task?.id,
            title: title,
            emoji: emoji,
            startDate: startDate,
            endDate: endDate,
            categoryID: category?.id,
            isDone: isDone,
            actualStartDate: actualStartDate,
            actualEndDate: actualEndDate,
            sourceType: sourceType,
            externalID: externalID,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    // Update from domain model
    func update(from block: TimeBlock) {
        self.title = block.title
        self.emoji = block.emoji
        self.startDate = block.startDate
        self.endDate = block.endDate
        self.isDone = block.isDone
        self.actualStartDate = block.actualStartDate
        self.actualEndDate = block.actualEndDate
        self.sourceType = block.sourceType
        self.externalID = block.externalID
        self.notes = block.notes
        self.updatedAt = Date()
    }
    
    // Create from domain model
    static func from(_ block: TimeBlock) -> TimeBlockEntity {
        TimeBlockEntity(
            id: block.id,
            title: block.title,
            emoji: block.emoji,
            startDate: block.startDate,
            endDate: block.endDate,
            isDone: block.isDone,
            actualStartDate: block.actualStartDate,
            actualEndDate: block.actualEndDate,
            sourceTypeRaw: block.sourceType.rawValue,
            externalID: block.externalID,
            notes: block.notes,
            createdAt: block.createdAt,
            updatedAt: block.updatedAt
        )
    }
}