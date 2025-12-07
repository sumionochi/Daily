// Services/SeedDataService.swift

import Foundation
import SwiftData

class SeedDataService {
    private let categoryStore: CategoryStore
    private let taskStore: TaskStore
    private let planStore: PlanStore
    
    init(categoryStore: CategoryStore, taskStore: TaskStore, planStore: PlanStore) {
        self.categoryStore = categoryStore
        self.taskStore = taskStore
        self.planStore = planStore
    }
    
    // MARK: - Main Seed
    
    func seedIfNeeded() {
        // Check if already seeded
        let existingCategories = categoryStore.fetchAll()
        guard existingCategories.isEmpty else {
            print("Data already seeded, skipping...")
            return
        }
        
        print("Seeding initial data...")
        seedCategories()
        seedSampleTasksAndBlocks() // Updated to link tasks and blocks
        print("Seed complete!")
    }
    
    // MARK: - Seed Categories
    
    private func seedCategories() {
        let categories = Category.defaultCategories
        categoryStore.createBatch(categories)
        print("Seeded \(categories.count) default categories")
    }
    
    // MARK: - Seed Sample Tasks & Blocks (SYNCED)
    
    private func seedSampleTasksAndBlocks() {
        let categories = categoryStore.fetchAll()
        guard !categories.isEmpty else { return }
        
        let focusCategory = categories.first { $0.name == "Focus" }
        let adminCategory = categories.first { $0.name == "Admin" }
        let breakCategory = categories.first { $0.name == "Break" }
        let healthCategory = categories.first { $0.name == "Health" }
        
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        
        // Sample data: (hour, minute, duration, title, emoji, category, shouldCreateTask)
        let sampleData: [(hour: Int, minute: Int, duration: Int, title: String, emoji: String, category: Category?, createTask: Bool)] = [
            (7, 0, 60, "Morning Routine", "☀️", healthCategory, true),
            (8, 0, 30, "Breakfast", "🍳", breakCategory, false),
            (9, 0, 120, "Deep Work Session", "🎯", focusCategory, true),
            (11, 0, 30, "Coffee Break", "☕️", breakCategory, false),
            (11, 30, 90, "Team Meeting", "👥", adminCategory, true),
            (13, 0, 60, "Lunch", "🍱", breakCategory, false),
            (14, 0, 120, "Focus Work", "💻", focusCategory, true),
            (16, 0, 30, "Quick Break", "🚶", breakCategory, false),
            (16, 30, 90, "Project Planning", "📋", adminCategory, true),
            (18, 0, 60, "Evening Workout", "💪", healthCategory, true),
            (19, 0, 60, "Dinner", "🍽", breakCategory, false),
            (20, 0, 90, "Personal Time", "📚", breakCategory, false),
            (22, 0, 480, "Sleep", "😴", nil, false)
        ]
        
        var createdCount = 0
        
        for data in sampleData {
            components.hour = data.hour
            components.minute = data.minute
            
            guard let startDate = calendar.date(from: components) else { continue }
            let endDate = startDate.addingTimeInterval(TimeInterval(data.duration * 60))
            
            var taskID: UUID? = nil
            
            // Create task if needed (for work-related items)
            if data.createTask {
                let task = Task(
                    title: data.title,
                    notes: nil,
                    estimatedDuration: data.duration,
                    categoryID: data.category?.id,
                    priority: .medium,
                    dueDate: today
                )
                
                if let createdTask = taskStore.create(task) {
                    taskID = createdTask.id
                }
            }
            
            // Create block (always)
            let block = TimeBlock(
                taskID: taskID, // Link to task if created
                title: data.title,
                emoji: data.emoji,
                startDate: startDate,
                endDate: endDate,
                categoryID: data.category?.id,
                sourceType: .manual
            )
            
            planStore.createBlock(block)
            createdCount += 1
        }
        
        print("Seeded \(createdCount) sample blocks (some linked to tasks)")
    }
    
    // MARK: - Clear All Data
    
    func clearAllData() {
        let tasks = taskStore.fetchAll()
        for task in tasks {
            _ = taskStore.delete(task.id)
        }
        
        let categories = categoryStore.fetchAll()
        for category in categories where !category.isDefault {
            _ = categoryStore.delete(category.id)
        }
        
        print("Cleared all non-default data")
    }
}
