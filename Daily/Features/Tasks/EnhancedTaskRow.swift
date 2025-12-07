// Features/Tasks/Views/EnhancedTaskRow.swift

import SwiftUI

struct EnhancedTaskRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let task: Task
    let category: Category?
    
    var body: some View {
        AppCard(padding: 12) {
            HStack(spacing: 12) {
                // Checkbox
                Button {
                    // TODO: Toggle completion
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(task.isCompleted ? .green : themeManager.textTertiaryColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(themeManager.bodyFont)
                        .foregroundColor(themeManager.textPrimaryColor)
                        .strikethrough(task.isCompleted)
                    
                    HStack(spacing: 8) {
                        // Category
                        if let category = category {
                            HStack(spacing: 4) {
                                Text(category.emoji)
                                    .font(.system(size: 12))
                                
                                Text(category.name)
                                    .font(themeManager.captionFont)
                                    .foregroundColor(themeManager.textSecondaryColor)
                            }
                        }
                        
                        // Duration
                        if task.estimatedDuration > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                
                                Text("\(task.estimatedDuration)m")
                                    .font(themeManager.captionFont)
                            }
                            .foregroundColor(themeManager.textSecondaryColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(themeManager.backgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        
                        // Due date
                        if let dueDate = task.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                
                                Text(dueDate, format: .dateTime.month().day())
                                    .font(themeManager.captionFont)
                            }
                            .foregroundColor(isOverdue ? .red : themeManager.textSecondaryColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isOverdue ? Color.red.opacity(0.1) : themeManager.backgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        
                        // Priority
                        if task.priority == .high {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        } else if task.priority == .medium {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.textTertiaryColor)
            }
        }
    }
    
    private var isOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return dueDate < Date() && !task.isCompleted
    }
}

#Preview {
    let task = Task(
        title: "Complete design mockups",
        notes: nil,
        estimatedDuration: 60,
        categoryID: nil,
        priority: .high,
        dueDate: Date()
    )
    
    return VStack {
        EnhancedTaskRow(task: task, category: nil)
    }
    .padding()
    .environmentObject(ThemeManager())
}
