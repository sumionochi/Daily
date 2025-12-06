// Services/StoreContainer.swift

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
final class StoreContainer: ObservableObject {
    
    let modelContext: ModelContext
    let categoryStore: CategoryStore
    let taskStore: TaskStore
    let planStore: PlanStore
    let routineStore: RoutineStore
    let seedDataService: SeedDataService
    let routineEngine: RoutineEngine
    
    init(modelContext: ModelContext, shouldSeed: Bool = true) {
        self.modelContext = modelContext
        
        // Initialize stores in dependency order
        self.categoryStore = CategoryStore(modelContext: modelContext)
        self.taskStore = TaskStore(modelContext: modelContext, categoryStore: categoryStore)
        self.planStore = PlanStore(modelContext: modelContext, taskStore: taskStore, categoryStore: categoryStore)
        self.routineStore = RoutineStore(modelContext: modelContext, categoryStore: categoryStore)
        self.routineEngine = RoutineEngine(routineStore: routineStore, planStore: planStore)
        self.seedDataService = SeedDataService(
            categoryStore: categoryStore,
            taskStore: taskStore,
            planStore: planStore
        )
        
        if shouldSeed {
            seedDataService.seedIfNeeded()
            routineEngine.generateBlocksForNextDays(30)
        }
    }
}
