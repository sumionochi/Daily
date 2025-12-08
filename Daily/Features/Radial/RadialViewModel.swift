//
//  RadialViewModel.swift
//  Daily
//
//  Created by Aaditya Srivastava on 08/12/25.
//


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
    
    // MARK: - Data
    
    @Published var blocks: [TimeBlock] = []
    @Published var statistics: DayStatistics?
    
    // MARK: - Dependencies
    
    let storeContainer: StoreContainer
    private let hapticManager = HapticManager.shared
    
    // MARK: - Private State
    
    private var lastSnapTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
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
        }
        
        hapticManager.trigger(.blockUnfocus)
    }
    
    func toggleFocus(for blockID: UUID) {
        if case .focused(let currentID) = state, currentID == blockID {
            unfocus()
        } else {
            focusBlock(blockID)
        }
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
        }
        
        hapticManager.trigger(.dayChange)
        
        loadBlocks()
        calculateStatistics()
    }
    
    // MARK: - Block Operations
    
    func moveBlock(_ blockID: UUID, toAngle angle: Double) {
        guard let index = blocks.firstIndex(where: { $0.id == blockID }) else {
            return
        }
        
        let newStartTime = angleToTime(angle, for: currentDate)
        let snappedTime = snapToInterval(newStartTime)
        
        // Check if we crossed a snap boundary
        if let lastSnap = lastSnapTime, lastSnap != snappedTime {
            hapticManager.dialTick()
        }
        lastSnapTime = snappedTime
        
        var block = blocks[index]
        let duration = block.duration
        block.startDate = snappedTime
        block.endDate = snappedTime.addingTimeInterval(duration)
        
        blocks[index] = block
    }
    
    func resizeBlock(_ blockID: UUID, newStartAngle: Double? = nil, newEndAngle: Double? = nil) {
        guard let index = blocks.firstIndex(where: { $0.id == blockID }) else {
            return
        }
        
        var block = blocks[index]
        
        if let startAngle = newStartAngle {
            let newStart = angleToTime(startAngle, for: currentDate)
            let snappedStart = snapToInterval(newStart)
            
            if let lastSnap = lastSnapTime, lastSnap != snappedStart {
                hapticManager.dialTick()
            }
            lastSnapTime = snappedStart
            
            block.startDate = snappedStart
        }
        
        if let endAngle = newEndAngle {
            let newEnd = angleToTime(endAngle, for: currentDate)
            let snappedEnd = snapToInterval(newEnd)
            
            if let lastSnap = lastSnapTime, lastSnap != snappedEnd {
                hapticManager.dialTick()
            }
            lastSnapTime = snappedEnd
            
            block.endDate = snappedEnd
        }
        
        // Ensure minimum duration (e.g. 15 minutes)
        let minDuration: TimeInterval = 15 * 60
        if block.duration < minDuration {
            block.endDate = block.startDate.addingTimeInterval(minDuration)
        }
        
        blocks[index] = block
    }
    
    func saveBlockChanges(_ blockID: UUID) {
        guard let block = blocks.first(where: { $0.id == blockID }) else {
            return
        }
        
        _ = storeContainer.planStore.updateBlock(block)
        NotificationCenter.default.post(name: NSNotification.Name("BlocksUpdated"), object: nil)
    }
    
    // MARK: - Interaction Mode
    
    func setInteractionMode(_ mode: RadialInteractionMode) {
        interactionMode = mode
        
        if case .idle = mode {
            lastSnapTime = nil
        }
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
    
    private func snapToInterval(_ time: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: time)
        
        guard let hour = components.hour, let minute = components.minute else {
            return time
        }
        
        let intervalMinutes = timeSnapInterval.rawValue
        let snappedMinute = (minute / intervalMinutes) * intervalMinutes
        
        var snappedComponents = DateComponents()
        snappedComponents.year = components.year
        snappedComponents.month = components.month
        snappedComponents.day = components.day
        snappedComponents.hour = hour
        snappedComponents.minute = snappedMinute
        snappedComponents.second = 0
        
        return calendar.date(from: snappedComponents) ?? time
    }
}