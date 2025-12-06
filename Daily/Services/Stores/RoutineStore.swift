//
//  RoutineStore.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Services/Stores/RoutineStore.swift

import Foundation
import SwiftData

@Observable
class RoutineStore {
    private let modelContext: ModelContext
    private let categoryStore: CategoryStore
    
    init(modelContext: ModelContext, categoryStore: CategoryStore) {
        self.modelContext = modelContext
        self.categoryStore = categoryStore
    }
    
    // MARK: - Fetch
    
    func fetchAll() -> [Routine] {
        let descriptor = FetchDescriptor<RoutineEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toDomain() }
        } catch {
            print("Failed to fetch routines: \(error)")
            return []
        }
    }
    
    func fetchEnabled() -> [Routine] {
        let descriptor = FetchDescriptor<RoutineEntity>(
            predicate: #Predicate { $0.isEnabled == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toDomain() }
        } catch {
            print("Failed to fetch enabled routines: \(error)")
            return []
        }
    }
    
    func fetchByID(_ id: UUID) -> Routine? {
        let descriptor = FetchDescriptor<RoutineEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.first?.toDomain()
        } catch {
            print("Failed to fetch routine: \(error)")
            return nil
        }
    }
    
    func fetchRoutinesFor(date: Date) -> [Routine] {
        let enabled = fetchEnabled()
        return enabled.filter { $0.shouldOccurOn(date: date) }
    }
    
    // MARK: - Create
    
    @discardableResult
    func create(_ routine: Routine) -> Routine? {
        let entity = RoutineEntity.from(routine)
        
        // Link category if exists
        if let categoryID = routine.categoryID {
            entity.category = categoryStore.entityForID(categoryID)
        }
        
        modelContext.insert(entity)
        
        do {
            try modelContext.save()
            return entity.toDomain()
        } catch {
            print("Failed to create routine: \(error)")
            return nil
        }
    }
    
    // MARK: - Update
    
    @discardableResult
    func update(_ routine: Routine) -> Routine? {
        let descriptor = FetchDescriptor<RoutineEntity>(
            predicate: #Predicate { $0.id == routine.id }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            guard let entity = entities.first else { return nil }
            
            entity.update(from: routine)
            
            // Update category relationship
            if let categoryID = routine.categoryID {
                entity.category = categoryStore.entityForID(categoryID)
            } else {
                entity.category = nil
            }
            
            try modelContext.save()
            return entity.toDomain()
        } catch {
            print("Failed to update routine: \(error)")
            return nil
        }
    }
    
    @discardableResult
    func toggleEnabled(_ id: UUID) -> Routine? {
        guard var routine = fetchByID(id) else { return nil }
        routine.isEnabled.toggle()
        return update(routine)
    }
    
    // MARK: - Delete
    
    func delete(_ id: UUID) -> Bool {
        let descriptor = FetchDescriptor<RoutineEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            guard let entity = entities.first else { return false }
            
            modelContext.delete(entity)
            try modelContext.save()
            return true
        } catch {
            print("Failed to delete routine: \(error)")
            return false
        }
    }
}