//
//  CategoryEntity.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Models/Persistence/CategoryEntity.swift

import Foundation
import SwiftData

@Model
final class CategoryEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var emoji: String
    var colorID: String
    var order: Int
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \TaskEntity.category)
    var tasks: [TaskEntity]?
    
    @Relationship(deleteRule: .nullify, inverse: \TimeBlockEntity.category)
    var timeBlocks: [TimeBlockEntity]?
    
    @Relationship(deleteRule: .nullify, inverse: \RoutineEntity.category)
    var routines: [RoutineEntity]?
    
    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        colorID: String,
        order: Int = 0,
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.colorID = colorID
        self.order = order
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Convert to domain model
    func toDomain() -> Category {
        Category(
            id: id,
            name: name,
            emoji: emoji,
            colorID: colorID,
            order: order,
            isDefault: isDefault,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    // Update from domain model
    func update(from category: Category) {
        self.name = category.name
        self.emoji = category.emoji
        self.colorID = category.colorID
        self.order = category.order
        self.isDefault = category.isDefault
        self.updatedAt = Date()
    }
    
    // Create from domain model
    static func from(_ category: Category) -> CategoryEntity {
        CategoryEntity(
            id: category.id,
            name: category.name,
            emoji: category.emoji,
            colorID: category.colorID,
            order: category.order,
            isDefault: category.isDefault,
            createdAt: category.createdAt,
            updatedAt: category.updatedAt
        )
    }
}