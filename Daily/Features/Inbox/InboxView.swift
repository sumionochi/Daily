// Features/Inbox/Views/InboxView.swift

import SwiftUI
import SwiftData
import Combine

struct InboxView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    @State private var tasks: [Task] = []
    @State private var newTaskTitle = ""
    @State private var showCompleted = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                
                VStack(spacing: 0) {
                    // Add task input
                    addTaskSection
                    
                    // Filter toggle
                    filterSection
                    
                    // Task list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredTasks) { task in
                                TaskRow(task: task, onToggle: {
                                    toggleTask(task)
                                }, onDelete: {
                                    deleteTask(task)
                                })
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadTasks()
            }
        }
    }
    
    private var addTaskSection: some View {
        AppCard {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.accent)
                
                TextField("Add a task...", text: $newTaskTitle)
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .submitLabel(.done)
                    .onSubmit {
                        addTask()
                    }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var filterSection: some View {
        HStack {
            Button {
                showCompleted.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                    Text(showCompleted ? "Hide Completed" : "Show Completed")
                        .font(themeManager.captionFont)
                }
                .foregroundColor(themeManager.accent)
            }
            
            Spacer()
            
            Text("\(filteredTasks.count) tasks")
                .font(themeManager.captionFont)
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var filteredTasks: [Task] {
        if showCompleted {
            return tasks
        } else {
            return tasks.filter { !$0.isCompleted }
        }
    }
    
    // MARK: - Actions
    
    private func loadTasks() {
        tasks = storeContainer.taskStore.fetchAll()
    }
    
    private func addTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let task = Task(title: newTaskTitle)
        if let created = storeContainer.taskStore.create(task) {
            tasks.insert(created, at: 0)
            newTaskTitle = ""
        }
    }
    
    private func toggleTask(_ task: Task) {
        if let updated = storeContainer.taskStore.toggleComplete(task.id) {
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = updated
            }
        }
    }
    
    private func deleteTask(_ task: Task) {
        if storeContainer.taskStore.delete(task.id) {
            tasks.removeAll { $0.id == task.id }
        }
    }
}

// MARK: - Task Row

struct TaskRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let task: Task
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        AppCard(padding: 12) {
            HStack(spacing: 12) {
                // Checkbox
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(task.isCompleted ? themeManager.accent : themeManager.textSecondaryColor)
                }
                
                // Task content
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(themeManager.bodyFont)
                        .foregroundColor(task.isCompleted ? themeManager.textSecondaryColor : themeManager.textPrimaryColor)
                        .strikethrough(task.isCompleted)
                    
                    HStack(spacing: 8) {
                        if let dueDate = task.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12))
                                Text(dueDate, style: .date)
                                    .font(themeManager.captionFont)
                            }
                            .foregroundColor(task.isOverdue ? .red : themeManager.textTertiaryColor)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text("\(task.estimatedDuration)m")
                                .font(themeManager.captionFont)
                        }
                        .foregroundColor(themeManager.textTertiaryColor)
                    }
                }
                
                Spacer()
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    InboxView()
        .environmentObject(ThemeManager())
        .environmentObject({
            let container = ModelContainer.createPreview()
            return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
        }())
}
