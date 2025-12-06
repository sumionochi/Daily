//
//  CategoryStore.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Services/Stores/CategoryStore.swift

import Foundation
import SwiftData

@Observable
class CategoryStore {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Fetch
    
    func fetchAll() -> [Category] {
        let descriptor = FetchDescriptor<CategoryEntity>(
            sortBy: [SortDescriptor(\.order)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toDomain() }
        } catch {
            print("Failed to fetch categories: \(error)")
            return []
        }
    }
    
    func fetchByID(_ id: UUID) -> Category? {
        let descriptor = FetchDescriptor<CategoryEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.first?.toDomain()
        } catch {
            print("Failed to fetch category: \(error)")
            return nil
        }
    }
    
    func fetchDefault() -> [Category] {
        let descriptor = FetchDescriptor<CategoryEntity>(
            predicate: #Predicate { $0.isDefault == true },
            sortBy: [SortDescriptor(\.order)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toDomain() }
        } catch {
            print("Failed to fetch default categories: \(error)")
            return []
        }
    }
    
    // MARK: - Create
    
    @discardableResult
    func create(_ category: Category) -> Category? {
        let entity = CategoryEntity.from(category)
        modelContext.insert(entity)
        
        do {
            try modelContext.save()
            return entity.toDomain()
        } catch {
            print("Failed to create category: \(error)")
            return nil
        }
    }
    
    @discardableResult
    func createBatch(_ categories: [Category]) -> [Category] {
        var created: [Category] = []
        
        for category in categories {
            let entity = CategoryEntity.from(category)
            modelContext.insert(entity)
            created.append(entity.toDomain())
        }
        
        do {
            try modelContext.save()
            return created
        } catch {
            print("Failed to create categories batch: \(error)")
            return []
        }
    }
    
    // MARK: - Update
    
    @discardableResult
    func update(_ category: Category) -> Category? {
        let descriptor = FetchDescriptor<CategoryEntity>(
            predicate: #Predicate { $0.id == category.id }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            guard let entity = entities.first else { return nil }
            
            entity.update(from: category)
            try modelContext.save()
            return entity.toDomain()
        } catch {
            print("Failed to update category: \(error)")
            return nil
        }
    }
    
    // MARK: - Delete
    
    func delete(_ id: UUID) -> Bool {
        let descriptor = FetchDescriptor<CategoryEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            guard let entity = entities.first else { return false }
            
            modelContext.delete(entity)
            try modelContext.save()
            return true
        } catch {
            print("Failed to delete category: \(error)")
            return false
        }
    }
    
    // MARK: - Helpers
    
    func reorder(_ categories: [Category]) {
        for (index, category) in categories.enumerated() {
            var updated = category
            updated.order = index
            update(updated)
        }
    }
    
    func entityForID(_ id: UUID) -> CategoryEntity? {
        let descriptor = FetchDescriptor<CategoryEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.first
        } catch {
            return nil
        }
    }
}
