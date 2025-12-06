//
//  DayPlanEntity.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Models/Persistence/DayPlanEntity.swift

import Foundation
import SwiftData

@Model
final class DayPlanEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var blockIDsData: Data? // JSON encoded [UUID]
    var notes: String?
    var isTemplate: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \TimeBlockEntity.dayPlan)
    var timeBlocks: [TimeBlockEntity]?
    
    init(
        id: UUID = UUID(),
        date: Date,
        blockIDsData: Data? = nil,
        notes: String? = nil,
        isTemplate: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.blockIDsData = blockIDsData
        self.notes = notes
        self.isTemplate = isTemplate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed properties
    var blockIDs: [UUID] {
        get {
            guard let data = blockIDsData else { return [] }
            return (try? JSONDecoder().decode([UUID].self, from: data)) ?? []
        }
        set {
            blockIDsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // Convert to domain model
    func toDomain() -> DayPlan {
        DayPlan(
            id: id,
            date: date,
            blockIDs: blockIDs,
            notes: notes,
            isTemplate: isTemplate,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    // Update from domain model
    func update(from plan: DayPlan) {
        self.date = Calendar.current.startOfDay(for: plan.date)
        self.blockIDs = plan.blockIDs
        self.notes = plan.notes
        self.isTemplate = plan.isTemplate
        self.updatedAt = Date()
    }
    
    // Create from domain model
    static func from(_ plan: DayPlan) -> DayPlanEntity {
        let entity = DayPlanEntity(
            id: plan.id,
            date: plan.date,
            notes: plan.notes,
            isTemplate: plan.isTemplate,
            createdAt: plan.createdAt,
            updatedAt: plan.updatedAt
        )
        entity.blockIDs = plan.blockIDs
        return entity
    }
}