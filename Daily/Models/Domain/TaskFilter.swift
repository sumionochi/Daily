//
//  TaskFilter.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Models/Domain/TaskFilter.swift

import Foundation

enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case today = "Today"
    case upcoming = "Upcoming"
    case completed = "Completed"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "tray"
        case .today: return "calendar"
        case .upcoming: return "calendar.badge.clock"
        case .completed: return "checkmark.circle"
        }
    }
}

enum TaskFolder: String, CaseIterable, Identifiable {
    case inbox = "Inbox"
    case work = "Work"
    case personal = "Personal"
    case someday = "Someday"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .inbox: return "tray"
        case .work: return "briefcase"
        case .personal: return "person"
        case .someday: return "archivebox"
        }
    }
}