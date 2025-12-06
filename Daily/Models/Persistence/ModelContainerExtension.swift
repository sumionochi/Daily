// Models/Persistence/ModelContainer+Extension.swift

import Foundation
import SwiftData

extension ModelContainer {
    static func create() -> ModelContainer {
        let schema = Schema([
            CategoryEntity.self,
            TaskEntity.self,
            TimeBlockEntity.self,
            DayPlanEntity.self,
            RoutineEntity.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
            // cloudKitDatabase: .automatic  // DISABLED - Re-enable when you buy ADP
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    static func createPreview() -> ModelContainer {
        let schema = Schema([
            CategoryEntity.self,
            TaskEntity.self,
            TimeBlockEntity.self,
            DayPlanEntity.self,
            RoutineEntity.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            return container
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }
}
