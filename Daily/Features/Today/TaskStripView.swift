//
//  TaskStripView.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Features/Today/Views/TaskStripView.swift

import SwiftUI

struct TaskStripView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let tasks: [Task]
    let onTaskTapped: (Task) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Unscheduled Tasks")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                Spacer()
                
                Text("\(tasks.count)")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textTertiaryColor)
            }
            .padding(.horizontal, 16)
            
            if tasks.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(tasks) { task in
                            TaskStripCard(task: task)
                                .onTapGesture {
                                    onTaskTapped(task)
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 12)
        .background(themeManager.secondaryBackgroundColor)
    }
    
    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 32))
                    .foregroundColor(themeManager.textTertiaryColor)
                
                Text("All tasks scheduled")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }
}

// MARK: - Task Strip Card

struct TaskStripCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let task: Task
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if !task.title.isEmpty && task.title.first?.isEmoji == true {
                    Text(String(task.title.prefix(2)))
                        .font(.system(size: 20))
                } else {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(themeManager.accent)
                }
                
                Text(task.title)
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .lineLimit(1)
            }
            
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("\(task.estimatedDuration)m")
                        .font(themeManager.captionFont)
                }
                .foregroundColor(themeManager.textTertiaryColor)
                
                if task.priority == .high || task.priority == .urgent {
                    HStack(spacing: 4) {
                        Image(systemName: task.priority.icon)
                            .font(.system(size: 10))
                        Text(task.priority.displayName)
                            .font(themeManager.captionFont)
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 160)
        .background(themeManager.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.cornerRadiusMedium)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Character Extension for Emoji Detection

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}

#Preview {
    let tasks = [
        Task(title: "Review proposal", estimatedDuration: 45, priority: .high),
        Task(title: "Team meeting", estimatedDuration: 30),
        Task(title: "Email responses", estimatedDuration: 20),
        Task(title: "🎯 Deep work", estimatedDuration: 120, priority: .urgent)
    ]
    
    return ZStack {
        AppBackgroundView()
        
        VStack {
            Spacer()
            TaskStripView(tasks: tasks) { task in
                print("Tapped: \(task.title)")
            }
        }
    }
    .environmentObject(ThemeManager())
}