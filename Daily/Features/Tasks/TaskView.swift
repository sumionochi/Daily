// Features/Tasks/Views/TasksView.swift

import SwiftUI
import SwiftData

enum TaskSection: String, CaseIterable {
    case unscheduled = "Unscheduled"
    case scheduled = "Scheduled"
    
    var icon: String {
        switch self {
        case .unscheduled: return "tray"
        case .scheduled: return "calendar"
        }
    }
}

struct TasksView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    @State private var selectedSection: TaskSection = .unscheduled
    @State private var unscheduledTasks: [Task] = []
    @State private var categories: [UUID: Category] = [:]
    @State private var searchText = ""
    @State private var selectedFilter: TaskFilter = .all
    @State private var selectedFolder: TaskFolder? = nil
    @State private var showNewTask = false
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                
                VStack(spacing: 0) {
                    // Section toggle
                    sectionToggle
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Content based on selected section
                    if selectedSection == .unscheduled {
                        unscheduledSection
                    } else {
                        scheduledSection
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewTask = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(themeManager.accent)
                    }
                }
            }
            .sheet(isPresented: $showNewTask) {
                NewTaskSheet(onSave: { task in
                    if let created = storeContainer.taskStore.create(task) {
                        unscheduledTasks.append(created)
                    }
                })
            }
            .onAppear {
                loadData()
            }
            .onChange(of: selectedSection) { _, _ in
                loadData()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BlocksUpdated"))) { _ in
                if selectedSection == .scheduled {
                    refreshID = UUID()
                }
            }
        }
    }
    
    // MARK: - Section Toggle
    
    private var sectionToggle: some View {
        HStack(spacing: 12) {
            ForEach(TaskSection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSection = section
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: section.icon)
                            .font(.system(size: 14))
                        Text(section.rawValue)
                            .font(themeManager.captionFont)
                    }
                    .foregroundColor(selectedSection == section ?
                        (themeManager.accentColor == .mono ?
                            Color(light: .white, dark: .black) : .white) :
                        themeManager.textPrimaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedSection == section ?
                        themeManager.accent : themeManager.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Unscheduled Section
    
    private var unscheduledSection: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.textSecondaryColor)
                
                TextField("Search tasks...", text: $searchText)
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                }
            }
            .padding(12)
            .background(themeManager.cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Filters
            filterChips
            
            // Folders
            folderChips
            
            // Task list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredUnscheduledTasks) { task in
                        EnhancedTaskRow(task: task, category: task.categoryID != nil ? categories[task.categoryID!] : nil)
                            .onTapGesture {
                                // TODO: Edit task
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            if filteredUnscheduledTasks.isEmpty {
                emptyUnscheduledState
            }
        }
    }
    
    // MARK: - Scheduled Section
    
    private var scheduledSection: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.textSecondaryColor)
                
                TextField("Search blocks...", text: $searchText)
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                }
            }
            .padding(12)
            .background(themeManager.cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Filter chips
            filterChips
            
            // Scheduled blocks grouped by date
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(scheduledDates, id: \.self) { date in
                        let dateBlocks = blocksFor(date: date)
                        
                        if !dateBlocks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                // Date header
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(date, format: .dateTime.weekday(.wide))
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(themeManager.textPrimaryColor)
                                        
                                        Text(date, format: .dateTime.month().day().year())
                                            .font(themeManager.captionFont)
                                            .foregroundColor(themeManager.textSecondaryColor)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(dateBlocks.count) blocks")
                                        .font(themeManager.captionFont)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                }
                                .padding(.horizontal)
                                
                                // Blocks
                                VStack(spacing: 8) {
                                    ForEach(dateBlocks) { block in
                                        ScheduledBlockRow(
                                            block: block,
                                            category: block.categoryID != nil ? categories[block.categoryID!] : nil,
                                            onUpdate: {
                                                refreshID = UUID()
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .id(refreshID)
            
            if scheduledDates.isEmpty {
                emptyScheduledState
            }
        }
    }
    
    // MARK: - Filter Chips
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Folder Chips
    
    private var folderChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskFolder.allCases, id: \.self) { folder in
                    let count = folderCount(folder)
                    
                    FolderChip(
                        title: folder.rawValue,
                        icon: folder.icon,
                        count: count,
                        isSelected: selectedFolder == folder
                    ) {
                        selectedFolder = selectedFolder == folder ? nil : folder
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Empty States
    
    private var emptyUnscheduledState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(themeManager.textTertiaryColor)
            
            Text("No tasks here")
                .font(themeManager.subtitleFont)
                .foregroundColor(themeManager.textPrimaryColor)
            
            Text("Create a new task to get started")
                .font(themeManager.bodyFont)
                .foregroundColor(themeManager.textSecondaryColor)
            
            Button {
                showNewTask = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("New Task")
                }
                .font(themeManager.buttonFont)
                .foregroundColor(themeManager.accentColor == .mono ?
                    Color(light: .white, dark: .black) : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(themeManager.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyScheduledState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundColor(themeManager.textTertiaryColor)
            
            Text("Nothing scheduled")
                .font(themeManager.subtitleFont)
                .foregroundColor(themeManager.textPrimaryColor)
            
            Text("Go to Today tab to schedule blocks")
                .font(themeManager.bodyFont)
                .foregroundColor(themeManager.textSecondaryColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Computed Properties
    
    private var filteredUnscheduledTasks: [Task] {
        var tasks = unscheduledTasks
        
        // Search filter
        if !searchText.isEmpty {
            tasks = tasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Status filter
        switch selectedFilter {
        case .all:
            break
        case .today:
            let calendar = Calendar.current
            tasks = tasks.filter {
                guard let dueDate = $0.dueDate else { return false }
                return calendar.isDateInToday(dueDate)
            }
        case .upcoming:
            tasks = tasks.filter {
                guard let dueDate = $0.dueDate else { return false }
                return dueDate > Date()
            }
        case .completed:
            tasks = tasks.filter { $0.isCompleted }
        }
        
        // Folder filter
        if let folder = selectedFolder {
            tasks = tasks.filter { $0.folder == folder.rawValue }
        }
        
        return tasks
    }
    
    // Scheduled section computed properties
    private var allScheduledBlocks: [TimeBlock] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get blocks from last 7 days to next 30 days
        var allBlocks: [TimeBlock] = []
        
        for dayOffset in -7...30 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                let blocks = storeContainer.planStore.fetchBlocksFor(date: date)
                allBlocks.append(contentsOf: blocks)
            }
        }
        
        return allBlocks
    }
    
    private var filteredScheduledBlocks: [TimeBlock] {
        var blocks = allScheduledBlocks
        
        // Search filter
        if !searchText.isEmpty {
            blocks = blocks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Status filter
        switch selectedFilter {
        case .all:
            break
        case .today:
            let calendar = Calendar.current
            blocks = blocks.filter { calendar.isDateInToday($0.startDate) }
        case .upcoming:
            blocks = blocks.filter { $0.startDate > Date() }
        case .completed:
            blocks = blocks.filter { $0.isDone }
        }
        
        return blocks.sorted { $0.startDate < $1.startDate }
    }
    
    private var scheduledDates: [Date] {
        let calendar = Calendar.current
        let uniqueDates = Set(filteredScheduledBlocks.map { calendar.startOfDay(for: $0.startDate) })
        return Array(uniqueDates).sorted()
    }
    
    private func blocksFor(date: Date) -> [TimeBlock] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        return filteredScheduledBlocks.filter {
            calendar.isDate($0.startDate, inSameDayAs: startOfDay)
        }
    }
    
    private func folderCount(_ folder: TaskFolder) -> Int {
        unscheduledTasks.filter { $0.folder == folder.rawValue }.count
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        if selectedSection == .unscheduled {
            unscheduledTasks = storeContainer.taskStore.fetchUnscheduled()
        }
        
        let allCategories = storeContainer.categoryStore.fetchAll()
        categories = Dictionary(uniqueKeysWithValues: allCategories.map { ($0.id, $0) })
    }
}

// MARK: - Scheduled Block Row

struct ScheduledBlockRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    let block: TimeBlock
    let category: Category?
    let onUpdate: (() -> Void)?
    
    @State private var showDetail = false
    @State private var isCompleted: Bool
    
    init(block: TimeBlock, category: Category?, onUpdate: (() -> Void)? = nil) {
        self.block = block
        self.category = category
        self.onUpdate = onUpdate
        _isCompleted = State(initialValue: block.isDone)
    }
    
    var body: some View {
        Button {
            showDetail = true
        } label: {
            AppCard(padding: 12) {
                HStack(spacing: 12) {
                    // Time indicator
                    VStack(alignment: .leading, spacing: 2) {
                        Text(block.startDate, format: .dateTime.hour().minute())
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(themeManager.textPrimaryColor)
                        
                        Text(block.endDate, format: .dateTime.hour().minute())
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                    .frame(width: 60, alignment: .leading)
                    
                    // Category color line
                    Rectangle()
                        .fill(categoryColor)
                        .frame(width: 3)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            if let emoji = block.emoji {
                                Text(emoji)
                                    .font(.system(size: 16))
                            }
                            
                            Text(block.title)
                                .font(themeManager.bodyFont)
                                .foregroundColor(themeManager.textPrimaryColor)
                                .lineLimit(2)
                                .strikethrough(isCompleted)
                        }
                        
                        HStack(spacing: 8) {
                            if let category = category {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(categoryColor)
                                        .frame(width: 6, height: 6)
                                    
                                    Text(category.name)
                                        .font(themeManager.captionFont)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                }
                            }
                            
                            Text("\(block.durationMinutes)m")
                                .font(themeManager.captionFont)
                                .foregroundColor(themeManager.textSecondaryColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(themeManager.backgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    
                    Spacer()
                    
                    // Status checkbox
                    Button {
                        toggleComplete()
                    } label: {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isCompleted ? .green : themeManager.textTertiaryColor)
                            .font(.system(size: 24))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            BlockDetailSheet(
                block: block,
                onSave: { updated in
                    if let _ = storeContainer.planStore.updateBlock(updated) {
                        NotificationCenter.default.post(name: NSNotification.Name("BlocksUpdated"), object: nil)
                        onUpdate?()
                    }
                },
                onDelete: {
                    if storeContainer.planStore.deleteBlock(block.id) {
                        NotificationCenter.default.post(name: NSNotification.Name("BlocksUpdated"), object: nil)
                        onUpdate?()
                    }
                }
            )
        }
    }
    
    private var categoryColor: Color {
        guard let category = category else {
            return themeManager.textTertiaryColor
        }
        
        switch category.colorID {
        case "blue": return Color(red: 0.4, green: 0.6, blue: 1.0)
        case "purple": return Color(red: 0.7, green: 0.5, blue: 1.0)
        case "pink": return Color(red: 1.0, green: 0.5, blue: 0.7)
        case "orange": return Color(red: 1.0, green: 0.6, blue: 0.4)
        case "green": return Color(red: 0.5, green: 0.9, blue: 0.6)
        case "teal": return Color(red: 0.4, green: 0.8, blue: 0.9)
        default: return themeManager.accent
        }
    }
    
    private func toggleComplete() {
        var updated = block
        if isCompleted {
            updated.markUndone()
        } else {
            updated.markDone()
        }
        
        if let saved = storeContainer.planStore.updateBlock(updated) {
            isCompleted = saved.isDone
            NotificationCenter.default.post(name: NSNotification.Name("BlocksUpdated"), object: nil)
            onUpdate?()
            
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
}

#Preview {
    TasksView()
        .environmentObject(ThemeManager())
        .environmentObject({
            let container = ModelContainer.createPreview()
            return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
        }())
}
