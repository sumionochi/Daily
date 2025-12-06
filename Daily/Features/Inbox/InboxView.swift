// Features/Inbox/Views/InboxView.swift

import SwiftUI
import SwiftData
import Combine

struct InboxView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    @State private var tasks: [Task] = []
    @State private var newTaskTitle = ""
    @State private var selectedFilter: TaskFilter = .all
    @State private var selectedFolder: TaskFolder = .inbox
    @State private var searchText = ""
    @State private var showingNewTask = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                    
                    // Filters
                    filterChips
                    
                    // Folders
                    folderSection
                    
                    // Task list
                    taskListSection
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewTask = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(themeManager.accent)
                    }
                }
            }
            .sheet(isPresented: $showingNewTask) {
                NewTaskSheet(onSave: { task in
                    addTask(task)
                })
            }
            .onAppear {
                loadTasks()
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.textTertiaryColor)
                
                TextField("Search tasks...", text: $searchText)
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.textTertiaryColor)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(themeManager.cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadiusMedium))
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .onChange(of: searchText) { _, _ in
            loadTasks()
        }
    }
    
    // MARK: - Filter Chips
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskFilter.allCases) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        loadTasks()
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Folder Section
    
    private var folderSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskFolder.allCases) { folder in
                    FolderChip(
                        title: folder.rawValue,
                        icon: folder.icon,
                        count: folderCount(folder),
                        isSelected: selectedFolder == folder
                    ) {
                        selectedFolder = folder
                        loadTasks()
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
    
    private func folderCount(_ folder: TaskFolder) -> Int {
        storeContainer.taskStore.fetchByFolder(folder.rawValue)
            .filter { !$0.isCompleted }
            .count
    }
    
    // MARK: - Task List
    
    private var taskListSection: some View {
        Group {
            if filteredTasks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredTasks) { task in
                            EnhancedTaskRow(
                                task: task,
                                onToggle: { toggleTask(task) },
                                onTap: { editTask(task) }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedFilter == .completed ? "checkmark.circle" : "tray")
                .font(.system(size: 60))
                .foregroundColor(themeManager.textTertiaryColor)
            
            Text(emptyStateMessage)
                .font(themeManager.bodyFont)
                .foregroundColor(themeManager.textSecondaryColor)
                .multilineTextAlignment(.center)
            
            if selectedFilter == .all && selectedFolder == .inbox {
                Button {
                    showingNewTask = true
                } label: {
                    Text("Add Your First Task")
                        .font(themeManager.buttonFont)
                        .foregroundColor(themeManager.textOnAccentColor)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(themeManager.accent)
                        .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadiusMedium))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return "No tasks in \(selectedFolder.rawValue)"
        case .today:
            return "No tasks due today"
        case .upcoming:
            return "No upcoming tasks"
        case .completed:
            return "No completed tasks"
        }
    }
    
    // MARK: - Filtered Tasks
    
    private var filteredTasks: [Task] {
        var result = tasks
        
        // Apply search
        if !searchText.isEmpty {
            result = result.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply filter
        switch selectedFilter {
        case .all:
            result = result.filter { !$0.isCompleted }
        case .today:
            result = result.filter { $0.isDueToday && !$0.isCompleted }
        case .upcoming:
            result = result.filter {
                if let dueDate = $0.dueDate {
                    return dueDate > Date() && !$0.isCompleted
                }
                return false
            }
        case .completed:
            result = result.filter { $0.isCompleted }
        }
        
        return result
    }
    
    // MARK: - Actions
    
    private func loadTasks() {
        if searchText.isEmpty {
            tasks = storeContainer.taskStore.fetchByFolder(selectedFolder.rawValue)
        } else {
            tasks = storeContainer.taskStore.search(searchText)
        }
    }
    
    private func addTask(_ task: Task) {
        var newTask = task
        newTask.folder = selectedFolder.rawValue
        
        if let created = storeContainer.taskStore.create(newTask) {
            tasks.insert(created, at: 0)
        }
    }
    
    private func toggleTask(_ task: Task) {
        if let updated = storeContainer.taskStore.toggleComplete(task.id) {
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = updated
            }
        }
    }
    
    private func editTask(_ task: Task) {
        // TODO: Show edit sheet in next step
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(themeManager.captionFont)
            }
            .foregroundColor(isSelected ? themeManager.textOnAccentColor : themeManager.textPrimaryColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? themeManager.accent : themeManager.cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Folder Chip

struct FolderChip: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                
                Text(title)
                    .font(themeManager.captionFont)
                
                if count > 0 {
                    Text("\(count)")
                        .font(themeManager.captionFont)
                        .foregroundColor(isSelected ? themeManager.textOnAccentColor.opacity(0.8) : themeManager.textTertiaryColor)
                }
            }
            .foregroundColor(isSelected ? themeManager.textOnAccentColor : themeManager.textPrimaryColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? themeManager.accent : themeManager.cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.clear : themeManager.borderColor, lineWidth: 1)
            )
        }
    }
}

// MARK: - Enhanced Task Row

struct EnhancedTaskRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let task: Task
    let onToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            AppCard(padding: 12) {
                HStack(spacing: 12) {
                    // Checkbox
                    Button(action: onToggle) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(task.isCompleted ? .green : themeManager.textSecondaryColor)
                    }
                    .buttonStyle(.plain)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(themeManager.bodyFont)
                            .foregroundColor(task.isCompleted ? themeManager.textSecondaryColor : themeManager.textPrimaryColor)
                            .strikethrough(task.isCompleted)
                        
                        HStack(spacing: 12) {
                            // Duration
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                Text("\(task.estimatedDuration)m")
                                    .font(themeManager.captionFont)
                            }
                            .foregroundColor(themeManager.textTertiaryColor)
                            
                            // Due date
                            if let dueDate = task.dueDate {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 12))
                                    Text(dueDate, style: .date)
                                        .font(themeManager.captionFont)
                                }
                                .foregroundColor(task.isOverdue ? .red : themeManager.textTertiaryColor)
                            }
                            
                            // Priority
                            if task.priority == .high || task.priority == .urgent {
                                HStack(spacing: 4) {
                                    Image(systemName: task.priority.icon)
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
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
