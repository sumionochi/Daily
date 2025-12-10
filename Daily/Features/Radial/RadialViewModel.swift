// Features/Radial/ViewModels/RadialViewModel.swift

import SwiftUI
import Combine

@MainActor
class RadialViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var state: RadialState = .unfocused
    @Published var currentDate: Date
    @Published var interactionMode: RadialInteractionMode = .idle
    @Published var timeSnapInterval: TimeSnapInterval = .fifteenMinutes
    
    // Data
    @Published var blocks: [TimeBlock] = []
    @Published var statistics: DayStatistics?
    
    // Editing
    @Published var editingBlockID: UUID? = nil
    // In RadialViewModel

    @Published var liveEditingBlock: TimeBlock?

    // MARK: - Dependencies
    
    let storeContainer: StoreContainer
    private let hapticManager = HapticManager.shared
    
    // MARK: - Private State
    
    private var cancellables = Set<AnyCancellable>()
    private let secondsInDay: TimeInterval = 24 * 60 * 60
    
    // MARK: - Initialization
    
    init(date: Date, storeContainer: StoreContainer) {
        self.currentDate = date
        self.storeContainer = storeContainer
        
        // Prepare haptics for low latency
        hapticManager.prepare()
        
        // Load initial data
        loadBlocks()
        calculateStatistics()
    }
    
    // MARK: - State Transitions
    
    func focusBlock(_ blockID: UUID) {
        guard state.focusedBlockID != blockID else { return }
        
        withAnimation(.easeInOut(duration: 0.25)) {
            state = .focused(blockID: blockID)
        }
        
        hapticManager.trigger(.blockFocus)
    }
    
    func unfocus() {
        guard state.isFocused else { return }
        
        withAnimation(.easeInOut(duration: 0.25)) {
            state = .unfocused
            editingBlockID = nil
        }
        
        hapticManager.trigger(.blockUnfocus)
    }
    
    // Features/Radial/ViewModels/RadialViewModel.swift

    func commitBlock(_ updatedBlock: TimeBlock) {
        guard let index = blocks.firstIndex(where: { $0.id == updatedBlock.id }) else {
            return
        }

        // Update in-memory array once
        blocks[index] = updatedBlock

        // Persist to store
        _ = storeContainer.planStore.updateBlock(updatedBlock)
        NotificationCenter.default.post(name: NSNotification.Name("BlocksUpdated"), object: nil)
    }
    
    func toggleFocus(for blockID: UUID) {
        if case .focused(let currentID) = state, currentID == blockID {
            unfocus()
        } else {
            focusBlock(blockID)
        }
    }
    
    // MARK: - Editing
    
    func beginEditingBlock(blockID: UUID) {
        // Ensure block exists
        guard getBlock(by: blockID) != nil else { return }
        
        // Always focus when editing
        if !isBlockFocused(blockID) {
            focusBlock(blockID)
        }
        
        editingBlockID = blockID
        hapticManager.trigger(.blockEdit)
    }
    
    func endEditingBlock() {
        editingBlockID = nil
    }
    
    // MARK: - Day Navigation
    
    func goToPreviousDay() {
        guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else {
            return
        }
        
        changeDay(to: previousDay)
    }
    
    func goToNextDay() {
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else {
            return
        }
        
        changeDay(to: nextDay)
    }
    
    private func changeDay(to newDate: Date) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentDate = newDate
            state = .unfocused // Clear focus when changing days
            editingBlockID = nil
        }
        
        hapticManager.trigger(.dayChange)
        
        loadBlocks()
        calculateStatistics()
    }
    
    // MARK: - Block Operations
    
    /// Drag the whole block around the dial, preserving duration (even across midnight).
    func moveBlock(_ blockID: UUID, toAngle angle: Double) {
        guard let index = blocks.firstIndex(where: { $0.id == blockID }) else {
            return
        }
        
        var block = blocks[index]
        
        let originalDuration = normalizedDuration(from: block.startDate, to: block.endDate)
        
        let newStartTime = angleToTime(angle, for: currentDate)
        let snappedStart = snapToInterval(newStartTime)
        
        block.startDate = snappedStart
        block.endDate = snappedStart.addingTimeInterval(originalDuration)
        
        // ✅ Use preview, don't republish array
        liveEditingBlock = block
    }
    
    /// Resize by dragging either start or end handle. Handles wrap through 00 gracefully.
    func resizeBlock(_ blockID: UUID, newStartAngle: Double? = nil, newEndAngle: Double? = nil) {
        guard let index = blocks.firstIndex(where: { $0.id == blockID }) else {
            return
        }
        
        var block = blocks[index]
        let calendar = Calendar.current
        
        var changedStart = false
        var changedEnd = false
        
        // Resize start
        if let startAngle = newStartAngle {
            let newStart = angleToTime(startAngle, for: currentDate)
            let snappedStart = snapToInterval(newStart)
            block.startDate = snappedStart
            changedStart = true
        }
        
        // Resize end
        if let endAngle = newEndAngle {
            let endTOD = angleToTime(endAngle, for: currentDate)
            let snappedTOD = snapToInterval(endTOD)
            
            let sameDayEnd = snappedTOD
            let nextDayEnd = calendar.date(byAdding: .day, value: 1, to: sameDayEnd)!
            
            let diffSame = abs(sameDayEnd.timeIntervalSince(block.endDate))
            let diffNext = abs(nextDayEnd.timeIntervalSince(block.endDate))
            
            let chosenEnd = (diffSame <= diffNext) ? sameDayEnd : nextDayEnd
            block.endDate = chosenEnd
            changedEnd = true
        }
        
        // Enforce minimum duration
        let minDuration = timeSnapInterval.seconds
        var duration = normalizedDuration(from: block.startDate, to: block.endDate)
        
        if duration < minDuration {
            if changedStart && !changedEnd {
                block.startDate = block.endDate.addingTimeInterval(-minDuration)
            } else {
                block.endDate = block.startDate.addingTimeInterval(minDuration)
            }
            duration = minDuration
        }
        
        if duration > secondsInDay {
            block.endDate = block.startDate.addingTimeInterval(secondsInDay)
        }
        
        // ✅ Use preview, don't republish array
        liveEditingBlock = block
    }
    
    func updateLiveEditingPreview(_ block: TimeBlock) {
        // Called while dragging/resizing
        liveEditingBlock = block
    }

    func clearLiveEditingPreview(for blockID: UUID) {
        if liveEditingBlock?.id == blockID {
            liveEditingBlock = nil
        }
    }
    
    func saveBlockChanges(_ blockID: UUID) {
        // Use liveEditingBlock if available, otherwise use blocks array
        let blockToSave: TimeBlock
        
        if let live = liveEditingBlock, live.id == blockID {
            blockToSave = live
        } else if let block = blocks.first(where: { $0.id == blockID }) {
            blockToSave = block
        } else {
            return
        }
        
        // Update blocks array (only once, on save)
        if let index = blocks.firstIndex(where: { $0.id == blockID }) {
            blocks[index] = blockToSave
        }
        
        // Clear live preview
        liveEditingBlock = nil
        
        // Persist
        _ = storeContainer.planStore.updateBlock(blockToSave)
        NotificationCenter.default.post(name: NSNotification.Name("BlocksUpdated"), object: nil)
    }
    
    // MARK: - Interaction Mode
    
    func setInteractionMode(_ mode: RadialInteractionMode) {
        interactionMode = mode
    }
    
    // MARK: - Data Loading
    
    func loadBlocks() {
        blocks = storeContainer.planStore.fetchBlocksFor(date: currentDate)
    }
    
    func calculateStatistics() {
        let categories = storeContainer.categoryStore.fetchAll()
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        
        let totalScheduled = blocks.reduce(0.0) { $0 + $1.duration }
        let completedCount = blocks.filter { $0.isDone }.count
        
        // Group by category
        var categoryDurations: [UUID: TimeInterval] = [:]
        for block in blocks {
            if let catID = block.categoryID {
                categoryDurations[catID, default: 0] += block.duration
            }
        }
        
        let breakdown = categoryDurations
            .compactMap { catID, duration -> (Category, TimeInterval)? in
                guard let category = categoryMap[catID] else { return nil }
                return (category, duration)
            }
            .sorted { $0.1 > $1.1 } // Sort by duration descending
        
        statistics = DayStatistics(
            totalScheduled: totalScheduled,
            categoryBreakdown: breakdown,
            completedCount: completedCount,
            totalCount: blocks.count
        )
    }
    
    // MARK: - Helpers
    
    func getBlock(by id: UUID) -> TimeBlock? {
        blocks.first { $0.id == id }
    }
    
    func isBlockFocused(_ blockID: UUID) -> Bool {
        state.focusedBlockID == blockID
    }
    
    // MARK: - Time Utilities
    
    /// Angle (0° = top, clockwise) → Date on a given day.
    private func angleToTime(_ angle: Double, for date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Normalize angle to 0-360
        let normalizedAngle = angle.truncatingRemainder(dividingBy: 360)
        let positiveAngle = normalizedAngle < 0 ? normalizedAngle + 360 : normalizedAngle
        
        // Convert angle to hours (0° = 12am, clockwise)
        let hours = (positiveAngle / 360.0) * 24.0
        let hoursPart = Int(hours)
        let minutesPart = Int((hours - Double(hoursPart)) * 60)
        
        components.hour = hoursPart
        components.minute = minutesPart
        components.second = 0
        
        return calendar.date(from: components) ?? date
    }
    
    /// Snap any Date to the current `timeSnapInterval` grid (within its day).
    private func snapToInterval(_ time: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: time)
        
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let hour = components.hour,
              let minute = components.minute else {
            return time
        }
        
        let intervalMinutes = timeSnapInterval.rawValue
        let snappedMinute = (minute / intervalMinutes) * intervalMinutes
        
        var snappedComponents = DateComponents()
        snappedComponents.year = year
        snappedComponents.month = month
        snappedComponents.day = day
        snappedComponents.hour = hour
        snappedComponents.minute = snappedMinute
        snappedComponents.second = 0
        
        return calendar.date(from: snappedComponents) ?? time
    }
    
    /// Duration in a 24h-wrapped sense (so 22:00 → 02:00 = 4h).
    private func normalizedDuration(from start: Date, to end: Date) -> TimeInterval {
        let raw = end.timeIntervalSince(start)
        if raw >= 0 {
            return raw
        } else {
            // Crosses midnight – treat end as “tomorrow”.
            return raw + secondsInDay
        }
    }
    
    // Inside RadialViewModel class (recommended)
    func focusNextOverlappingBlock(from baseBlockID: UUID) {
        guard let baseBlock = blocks.first(where: { $0.id == baseBlockID }) else { return }

        // All blocks that overlap in time with baseBlock
        let overlapping = blocks.filter {
            $0.id != baseBlock.id && $0.overlaps(with: baseBlock)
        }
        guard !overlapping.isEmpty else { return }

        let sorted = overlapping.sorted { $0.startDate < $1.startDate }
        let currentID = state.focusedBlockID

        if let currentID,
           let idx = sorted.firstIndex(where: { $0.id == currentID }) {
            // Already focused one overlapping block → go to next
            let nextIdx = (idx + 1) % sorted.count
            focusBlock(sorted[nextIdx].id)
        } else {
            // First double-tap → focus the earliest overlapping block
            focusBlock(sorted[0].id)
        }
    }

}
