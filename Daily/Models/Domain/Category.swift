// Models/Domain/Category.swift

import Foundation

struct Category: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var emoji: String
    var colorID: String // Reference to preset color
    var order: Int
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        colorID: String,
        order: Int = 0,
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.colorID = colorID
        self.order = order
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Default categories
    static let defaultCategories: [Category] = [
        Category(
            name: "Focus",
            emoji: "🎯",
            colorID: "blue",
            order: 0,
            isDefault: true
        ),
        Category(
            name: "Admin",
            emoji: "📋",
            colorID: "purple",
            order: 1,
            isDefault: true
        ),
        Category(
            name: "Break",
            emoji: "☕️",
            colorID: "green",
            order: 2,
            isDefault: true
        ),
        Category(
            name: "Health",
            emoji: "💪",
            colorID: "orange",
            order: 3,
            isDefault: true
        ),
        Category(
            name: "Creative",
            emoji: "🎨",
            colorID: "pink",
            order: 4,
            isDefault: true
        ),
        Category(
            name: "Social",
            emoji: "👥",
            colorID: "teal",
            order: 5,
            isDefault: true
        )
    ]
}
