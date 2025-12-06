// Models/Domain/DayPlan.swift

import Foundation

struct DayPlan: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date // Normalized to start of day
    var blockIDs: [UUID]
    var notes: String?
    var isTemplate: Bool // For recurring templates
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        date: Date,
        blockIDs: [UUID] = [],
        notes: String? = nil,
        isTemplate: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.blockIDs = blockIDs
        self.notes = notes
        self.isTemplate = isTemplate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed properties
    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(date)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(date)
    }
    
    var isPast: Bool {
        guard !isToday else { return false }
        return date < Date()
    }
    
    var isFuture: Bool {
        guard !isToday else { return false }
        return date > Date()
    }
    
    // Helper methods
    mutating func addBlock(_ blockID: UUID) {
        if !blockIDs.contains(blockID) {
            blockIDs.append(blockID)
            updatedAt = Date()
        }
    }
    
    mutating func removeBlock(_ blockID: UUID) {
        blockIDs.removeAll { $0 == blockID }
        updatedAt = Date()
    }
    
    mutating func reorderBlocks(_ newOrder: [UUID]) {
        blockIDs = newOrder
        updatedAt = Date()
    }
}
