// Services/RoutineEngine.swift

import Foundation

class RoutineEngine {
    private let routineStore: RoutineStore
    private let planStore: PlanStore
    
    init(routineStore: RoutineStore, planStore: PlanStore) {
        self.routineStore = routineStore
        self.planStore = planStore
    }
    
    // MARK: - Generate Blocks
    
    /// Generate time blocks for all enabled routines for next N days
    func generateBlocksForNextDays(_ days: Int = 30) {
        let routines = routineStore.fetchEnabled()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }
            
            generateBlocksFor(date: date, routines: routines)
        }
    }
    
    /// Generate blocks for a specific date
    func generateBlocksFor(date: Date, routines: [Routine]? = nil) {
        let routinesToUse = routines ?? routineStore.fetchEnabled()
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        
        // Check which routines should occur on this date
        for routine in routinesToUse {
            guard routine.shouldOccurOn(date: normalizedDate) else {
                continue
            }
            
            // Check if block already exists for this routine on this date
            let existingBlocks = planStore.fetchBlocksFor(date: normalizedDate)
            let hasRoutineBlock = existingBlocks.contains { block in
                block.sourceType == .routine &&
                block.title == routine.title &&
                calendar.isDate(block.startDate, inSameDayAs: normalizedDate)
            }
            
            if !hasRoutineBlock {
                // Generate new block
                if let block = routine.generateBlockFor(date: normalizedDate) {
                    _ = planStore.createBlock(block)
                }
            }
        }
    }
    
    // MARK: - Skip Instance
    
    /// Skip a single routine instance without deleting the routine
    func skipRoutineInstance(routine: Routine, on date: Date) -> Bool {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        
        // Find the block for this routine on this date
        let blocks = planStore.fetchBlocksFor(date: normalizedDate)
        
        if let block = blocks.first(where: { 
            $0.sourceType == .routine && $0.title == routine.title 
        }) {
            // Mark as skipped by deleting it
            return planStore.deleteBlock(block.id)
        }
        
        return false
    }
    
    // MARK: - Update Routine Blocks
    
    /// Update all future blocks when routine is modified
    func updateFutureBlocks(for routine: Routine) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Delete all future routine blocks
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }
            
            let blocks = planStore.fetchBlocksFor(date: date)
            for block in blocks where block.sourceType == .routine && block.title == routine.title {
                // Only delete if not started yet
                if !block.isDone && block.isFuture {
                    _ = planStore.deleteBlock(block.id)
                }
            }
        }
        
        // Regenerate if routine is enabled
        if routine.isEnabled {
            generateBlocksForNextDays(30)
        }
    }
    
    // MARK: - Cleanup
    
    /// Remove blocks for disabled routine
    func removeFutureBlocks(for routine: Routine) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }
            
            let blocks = planStore.fetchBlocksFor(date: date)
            for block in blocks where block.sourceType == .routine && block.title == routine.title {
                if !block.isDone && block.isFuture {
                    _ = planStore.deleteBlock(block.id)
                }
            }
        }
    }
    
    // MARK: - Validation
    
    /// Check if routine conflicts with existing blocks
    func hasConflicts(routine: Routine, on date: Date) -> Bool {
        guard let block = routine.generateBlockFor(date: date) else {
            return false
        }
        
        let conflicts = planStore.detectConflicts(for: block, on: date)
        return !conflicts.isEmpty
    }
}
