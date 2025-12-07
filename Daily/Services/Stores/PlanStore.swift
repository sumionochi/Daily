// Services/Stores/PlanStore.swift

import Foundation
import SwiftData

@Observable
class PlanStore {
    private let modelContext: ModelContext
    private let taskStore: TaskStore
    private let categoryStore: CategoryStore
    
    init(modelContext: ModelContext, taskStore: TaskStore, categoryStore: CategoryStore) {
        self.modelContext = modelContext
        self.taskStore = taskStore
        self.categoryStore = categoryStore
    }
    
    // MARK: - DayPlan Operations
    
    func fetchPlanFor(date: Date) -> DayPlan? {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<DayPlanEntity>(
            predicate: #Predicate { $0.date == normalizedDate }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.first?.toDomain()
        } catch {
            print("Failed to fetch day plan: \(error)")
            return nil
        }
    }
    
    func getOrCreatePlanFor(date: Date) -> DayPlan {
        if let existing = fetchPlanFor(date: date) {
            return existing
        }
        
        let newPlan = DayPlan(date: date)
        let entity = DayPlanEntity.from(newPlan)
        modelContext.insert(entity)
        
        do {
            try modelContext.save()
            return entity.toDomain()
        } catch {
            print("Failed to create day plan: \(error)")
            return newPlan
        }
    }
    
    @discardableResult
    func updatePlan(_ plan: DayPlan) -> DayPlan? {
        let normalizedDate = Calendar.current.startOfDay(for: plan.date)
        let descriptor = FetchDescriptor<DayPlanEntity>(
            predicate: #Predicate { $0.date == normalizedDate }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            guard let entity = entities.first else { return nil }
            
            entity.update(from: plan)
            try modelContext.save()
            return entity.toDomain()
        } catch {
            print("Failed to update day plan: \(error)")
            return nil
        }
    }
    
    // MARK: - TimeBlock Operations
    
    func fetchBlocksFor(date: Date) -> [TimeBlock] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<TimeBlockEntity>(
            predicate: #Predicate { block in
                block.startDate >= startOfDay && block.startDate < endOfDay
            },
            sortBy: [SortDescriptor(\.startDate)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toDomain() }
        } catch {
            print("Failed to fetch blocks for date: \(error)")
            return []
        }
    }
    
    func fetchBlockByID(_ id: UUID) -> TimeBlock? {
        let descriptor = FetchDescriptor<TimeBlockEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.first?.toDomain()
        } catch {
            print("Failed to fetch block: \(error)")
            return nil
        }
    }
    
    func fetchCurrentBlock() -> TimeBlock? {
        let now = Date()
        let descriptor = FetchDescriptor<TimeBlockEntity>(
            predicate: #Predicate { block in
                block.startDate <= now && block.endDate > now
            },
            sortBy: [SortDescriptor(\.startDate)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.first?.toDomain()
        } catch {
            print("Failed to fetch current block: \(error)")
            return nil
        }
    }
    
    func fetchUpcomingBlocks(limit: Int = 5) -> [TimeBlock] {
        let now = Date()
        let descriptor = FetchDescriptor<TimeBlockEntity>(
            predicate: #Predicate { $0.startDate > now },
            sortBy: [SortDescriptor(\.startDate)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return Array(entities.prefix(limit)).map { $0.toDomain() }
        } catch {
            print("Failed to fetch upcoming blocks: \(error)")
            return []
        }
    }
    
    @discardableResult
    func createBlock(_ block: TimeBlock) -> TimeBlock? {
        let entity = TimeBlockEntity.from(block)
        
        // Link relationships
        if let taskID = block.taskID {
            entity.task = taskStore.entityForID(taskID)
        }
        
        if let categoryID = block.categoryID {
            entity.category = categoryStore.entityForID(categoryID)
        }
        
        modelContext.insert(entity)
        
        // Add to day plan
        var plan = getOrCreatePlanFor(date: block.startDate)
        plan.addBlock(entity.id)
        updatePlan(plan)
        
        do {
            try modelContext.save()
            return entity.toDomain()
        } catch {
            print("Failed to create block: \(error)")
            return nil
        }
    }
    
    @discardableResult
    func updateBlock(_ block: TimeBlock) -> TimeBlock? {
        let descriptor = FetchDescriptor<TimeBlockEntity>(
            predicate: #Predicate { $0.id == block.id }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            guard let entity = entities.first else { return nil }
            
            // Check if date changed - update day plans
            let oldDate = entity.startDate
            let newDate = block.startDate
            
            entity.update(from: block)
            
            // Update relationships
            if let taskID = block.taskID {
                entity.task = taskStore.entityForID(taskID)
            } else {
                entity.task = nil
            }
            
            if let categoryID = block.categoryID {
                entity.category = categoryStore.entityForID(categoryID)
            } else {
                entity.category = nil
            }
            
            // Handle day plan changes
            if !Calendar.current.isDate(oldDate, inSameDayAs: newDate) {
                // Remove from old plan
                if var oldPlan = fetchPlanFor(date: oldDate) {
                    oldPlan.removeBlock(block.id)
                    updatePlan(oldPlan)
                }
                
                // Add to new plan
                var newPlan = getOrCreatePlanFor(date: newDate)
                newPlan.addBlock(block.id)
                updatePlan(newPlan)
            }
            
            try modelContext.save()
            return entity.toDomain()
        } catch {
            print("Failed to update block: \(error)")
            return nil
        }
    }
    
    func deleteBlock(_ id: UUID) -> Bool {
        let descriptor = FetchDescriptor<TimeBlockEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            guard let entity = entities.first else { return false }
            
            // Remove from day plan
            if var plan = fetchPlanFor(date: entity.startDate) {
                plan.removeBlock(id)
                updatePlan(plan)
            }
            
            modelContext.delete(entity)
            try modelContext.save()
            return true
        } catch {
            print("Failed to delete block: \(error)")
            return false
        }
    }
    
    // MARK: - Conflict Detection
    
    func detectConflicts(for block: TimeBlock, on date: Date) -> [TimeBlock] {
        let blocks = fetchBlocksFor(date: date)
        return blocks.filter { existing in
            existing.id != block.id && block.overlaps(with: existing)
        }
    }
    
    func hasConflicts(for block: TimeBlock, on date: Date) -> Bool {
        !detectConflicts(for: block, on: date).isEmpty
    }
    
    // MARK: - Statistics
    
    func totalScheduledMinutesFor(date: Date) -> Int {
        let blocks = fetchBlocksFor(date: date)
        return blocks.reduce(0) { $0 + $1.durationMinutes }
    }
    
    func completedMinutesFor(date: Date) -> Int {
        let blocks = fetchBlocksFor(date: date)
        return blocks
            .filter { $0.isDone }
            .reduce(0) { $0 + ($1.actualDurationMinutes ?? $1.durationMinutes) }
    }
}
