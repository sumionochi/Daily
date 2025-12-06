// Models/Domain/UserPreferences.swift

import Foundation

struct UserPreferences: Codable {
    var wakeHour: Int
    var wakeMinute: Int
    var sleepHour: Int
    var sleepMinute: Int
    var defaultBlockDuration: Int // minutes
    var snapInterval: Int // minutes (5, 10, 15, 30)
    
    init(
        wakeHour: Int = 7,
        wakeMinute: Int = 0,
        sleepHour: Int = 22,
        sleepMinute: Int = 0,
        defaultBlockDuration: Int = 30,
        snapInterval: Int = 15
    ) {
        self.wakeHour = wakeHour
        self.wakeMinute = wakeMinute
        self.sleepHour = sleepHour
        self.sleepMinute = sleepMinute
        self.defaultBlockDuration = defaultBlockDuration
        self.snapInterval = snapInterval
    }
    
    var wakeTime: String {
        String(format: "%02d:%02d", wakeHour, wakeMinute)
    }
    
    var sleepTime: String {
        String(format: "%02d:%02d", sleepHour, sleepMinute)
    }
    
    var workingHours: Int {
        let wakeMinutes = wakeHour * 60 + wakeMinute
        let sleepMinutes = sleepHour * 60 + sleepMinute
        
        if sleepMinutes > wakeMinutes {
            return (sleepMinutes - wakeMinutes) / 60
        } else {
            // Crosses midnight
            return ((24 * 60) - wakeMinutes + sleepMinutes) / 60
        }
    }
}

// MARK: - UserDefaults Storage

extension UserPreferences {
    private static let key = "userPreferences"
    
    static func load() -> UserPreferences {
        guard let data = UserDefaults.standard.data(forKey: key),
              let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return UserPreferences()
        }
        return preferences
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: UserPreferences.key)
        }
    }
}