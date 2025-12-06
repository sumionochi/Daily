// Services/Stores/TaskStore.swift

import Foundation
import SwiftData
import Combine

class TaskStore: ObservableObject {
    private let modelContext: ModelContext
    private let categoryStore: CategoryStore
    
    init(modelContext: ModelContext, categoryStore: CategoryStore) {
        self.modelContext = modelContext
        self.categoryStore = categoryStore
    }
    
    // MARK: - Fetch
    
    func fetchAll() -> [Task] {
        let descriptor = FetchDescriptor<TaskEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toDomain() }
        } catch {
            print("Failed to fetch tasks: \(error)")
            return []
        }
    }
    
    func fetchByID(_ id: UUID) -> Task? {
        let descriptor = FetchDescriptor<TaskEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.first?.toDomain()
        } catch {
            print("Failed to fetch task: \(error)")
            return nil
        }
    }
    
    func fetchPending() -> [Task] {
        let pendingStatus = TaskStatus.pending.rawValue
        let descriptor = FetchDescriptor<TaskEntity>(
            predicate: #Predicate { $0.statusRaw == pendingStatus },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toDomain() }
        } catch {
            print("Failed to fetch pending tasks: \(error)")
            return []
        }
    }
    
    func fetchCompleted() -> [Task] {
        let completedStatus = TaskStatus.completed.rawValue
        let descriptor = FetchDescriptor<TaskEntity>(
            predicate: #Predicate { $0.statusRaw == completedStatus },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toDomain() }
        } catch {
            print("Failed to fetch completed tasks: \(error)")
            return []
        }
    }
    
    func fetchDueToday() -> [Task] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let completedStatus = TaskStatus.completed.rawValue
        
        let descriptor = FetchDescriptor<TaskEntity>(
            predicate: #Predicate { task in
                task.dueDate != nil &&
                task.dueDate! >= startOfDay &&
                task.dueDate! < endOfDay &&
                task.statusRaw != completedStatus
            },
            sortBy: [SortDescriptor(\.dueDate)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toDomain() }
        } catch {
            print("Failed to fetch tasks due today: \(error)")
            return []
        }
    }
    
    func fetchOverdue() -> [Task] {
        let now = Date()
        let completedStatus = TaskStatus.completed.rawValue
        
        let descriptor = FetchDescriptor<TaskEntity>(
            predicate: #Predicate { task in
                task.dueDate != nil &&
                task.dueDate! < now &&
                task.statusRaw != completedStatus
            },
            sortBy: [SortDescriptor(\.dueDate)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toDomain() }
        } catch {
            print("Failed to fetch overdue tasks: \(error)")
            return []
        }
    }
    
    func fetchUnscheduled() -> [Task] {
        let pendingStatus = TaskStatus.pending.rawValue
        let descriptor = FetchDescriptor<TaskEntity>(
            predicate: #Predicate { task in
                task.statusRaw == pendingStatus &&
                (task.timeBlocks == nil || task.timeBlocks!.isEmpty)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toDomain() }
        } catch {
            print("Failed to fetch unscheduled tasks: \(error)")
            return []
        }
    }
    
    func search(_ query: String) -> [Task] {
        guard !query.isEmpty else { return fetchAll() }
        
        let lowercased = query.lowercased()
        let descriptor = FetchDescriptor<TaskEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities
                .filter { entity in
                    entity.title.lowercased().contains(lowercased) ||
                    (entity.notes?.lowercased().contains(lowercased) ?? false)
                }
                .map { $0.toDomain() }
        } catch {
            print("Failed to search tasks: \(error)")
            return []
        }
    }
    
    // MARK: - Create
    
    @discardableResult
    func create(_ task: Task) -> Task? {
        let entity = TaskEntity.from(task)
        
        // Link category if exists
        if let categoryID = task.categoryID {
            entity.category = categoryStore.entityForID(categoryID)
        }
        
        modelContext.insert(entity)
        
        do {
            try modelContext.save()
            return entity.toDomain()
        } catch {
            print("Failed to create task: \(error)")
            return nil
        }
    }
    
    // MARK: - Update
    
    @discardableResult
    func update(_ task: Task) -> Task? {
        let descriptor = FetchDescriptor<TaskEntity>(
            predicate: #Predicate { $0.id == task.id }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            guard let entity = entities.first else { return nil }
            
            entity.update(from: task)
            
            // Update category relationship
            if let categoryID = task.categoryID {
                entity.category = categoryStore.entityForID(categoryID)
            } else {
                entity.category = nil
            }
            
            try modelContext.save()
            return entity.toDomain()
        } catch {
            print("Failed to update task: \(error)")
            return nil
        }
    }
    
    @discardableResult
    func toggleComplete(_ id: UUID) -> Task? {
        guard var task = fetchByID(id) else { return nil }
        
        if task.isCompleted {
            task.uncomplete()
        } else {
            task.complete()
        }
        
        return update(task)
    }
    
    // MARK: - Delete
    
    func delete(_ id: UUID) -> Bool {
        let descriptor = FetchDescriptor<TaskEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            guard let entity = entities.first else { return false }
            
            modelContext.delete(entity)
            try modelContext.save()
            return true
        } catch {
            print("Failed to delete task: \(error)")
            return false
        }
    }
    
    // MARK: - Helpers
    
    func entityForID(_ id: UUID) -> TaskEntity? {
        let descriptor = FetchDescriptor<TaskEntity>(
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
