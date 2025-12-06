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
        seedSampleTasks()
        seedSampleDay()
        print("Seed complete!")
    }
    
    // MARK: - Seed Categories
    
    private func seedCategories() {
        let categories = Category.defaultCategories
        categoryStore.createBatch(categories)
        print("Seeded \(categories.count) default categories")
    }
    
    // MARK: - Seed Sample Tasks
    
    private func seedSampleTasks() {
        let categories = categoryStore.fetchAll()
        guard !categories.isEmpty else { return }
        
        let focusCategory = categories.first { $0.name == "Focus" }
        let adminCategory = categories.first { $0.name == "Admin" }
        let healthCategory = categories.first { $0.name == "Health" }
        let breakCategory = categories.first { $0.name == "Break" }
        
        let sampleTasks: [Task] = [
            Task(
                title: "Review project proposal",
                notes: "Check budget and timeline",
                estimatedDuration: 45,
                categoryID: focusCategory?.id,
                priority: .high,
                dueDate: Date()
            ),
            Task(
                title: "Respond to client emails",
                estimatedDuration: 30,
                categoryID: adminCategory?.id,
                priority: .medium,
                dueDate: Date()
            ),
            Task(
                title: "Morning workout",
                estimatedDuration: 60,
                categoryID: healthCategory?.id,
                priority: .medium
            ),
            Task(
                title: "Team standup meeting",
                estimatedDuration: 15,
                categoryID: adminCategory?.id,
                priority: .medium,
                dueDate: Date()
            ),
            Task(
                title: "Lunch break",
                estimatedDuration: 60,
                categoryID: breakCategory?.id,
                priority: .low
            )
        ]
        
        for task in sampleTasks {
            taskStore.create(task)
        }
        
        print("Seeded \(sampleTasks.count) sample tasks")
    }
    
    // MARK: - Seed Sample Day
    
    private func seedSampleDay() {
        let categories = categoryStore.fetchAll()
        guard !categories.isEmpty else { return }
        
        let focusCategory = categories.first { $0.name == "Focus" }
        let adminCategory = categories.first { $0.name == "Admin" }
        let breakCategory = categories.first { $0.name == "Break" }
        let healthCategory = categories.first { $0.name == "Health" }
        
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        
        // Create sample blocks for today
        let sampleBlocks: [(hour: Int, minute: Int, duration: Int, title: String, emoji: String, categoryID: UUID?)] = [
            (7, 0, 60, "Morning Routine", "☀️", healthCategory?.id),
            (8, 0, 30, "Breakfast", "🍳", breakCategory?.id),
            (9, 0, 120, "Deep Work Session", "🎯", focusCategory?.id),
            (11, 0, 30, "Coffee Break", "☕️", breakCategory?.id),
            (11, 30, 90, "Team Meeting", "👥", adminCategory?.id),
            (13, 0, 60, "Lunch", "🍱", breakCategory?.id),
            (14, 0, 120, "Focus Work", "💻", focusCategory?.id),
            (16, 0, 30, "Quick Break", "🚶", breakCategory?.id),
            (16, 30, 90, "Project Planning", "📋", adminCategory?.id),
            (18, 0, 60, "Evening Workout", "💪", healthCategory?.id),
            (19, 0, 60, "Dinner", "🍽", breakCategory?.id),
            (20, 0, 90, "Personal Time", "📚", breakCategory?.id),
            (22, 0, 480, "Sleep", "😴", nil)
        ]
        
        for blockData in sampleBlocks {
            components.hour = blockData.hour
            components.minute = blockData.minute
            
            guard let startDate = calendar.date(from: components) else { continue }
            let endDate = startDate.addingTimeInterval(TimeInterval(blockData.duration * 60))
            
            let block = TimeBlock(
                title: blockData.title,
                emoji: blockData.emoji,
                startDate: startDate,
                endDate: endDate,
                categoryID: blockData.categoryID,
                sourceType: .manual
            )
            
            planStore.createBlock(block)
        }
        
        print("Seeded \(sampleBlocks.count) sample time blocks for today")
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
