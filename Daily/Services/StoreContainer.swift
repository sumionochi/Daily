// Services/StoreContainer.swift

import Foundation
import SwiftData
import SwiftUI      // ⬅️ ADD THIS so ObservableObject exists
import Combine

@MainActor          // ⬅️ Recommended, since ModelContext is main-actor bound
final class StoreContainer: ObservableObject {
    
    let modelContext: ModelContext
    let categoryStore: CategoryStore
    let taskStore: TaskStore
    let planStore: PlanStore
    let routineStore: RoutineStore
    let seedDataService: SeedDataService
    
    init(modelContext: ModelContext, shouldSeed: Bool = true) {
        self.modelContext = modelContext
        
        // Initialize stores in dependency order
        self.categoryStore = CategoryStore(modelContext: modelContext)
        self.taskStore = TaskStore(modelContext: modelContext, categoryStore: categoryStore)
        self.planStore = PlanStore(modelContext: modelContext, taskStore: taskStore, categoryStore: categoryStore)
        self.routineStore = RoutineStore(modelContext: modelContext, categoryStore: categoryStore)
        self.seedDataService = SeedDataService(
            categoryStore: categoryStore,
            taskStore: taskStore,
            planStore: planStore
        )
        
        if shouldSeed {
            seedDataService.seedIfNeeded()
        }
    }
}
