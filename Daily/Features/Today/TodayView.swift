// Features/Today/Views/TodayView.swift

import SwiftUI
import SwiftData

struct TodayView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    @State private var currentDate = Date()
    @State private var timeBlocks: [TimeBlock] = []
    @State private var unscheduledTasks: [Task] = []
    @State private var currentBlock: TimeBlock?
    
    var body: some View {
        ZStack {
            AppBackgroundView()
            
            VStack(spacing: 0) {
                // Date navigation
                dateNavigationBar
                    .padding(.horizontal)
                    .padding(.top)
                
                // Main content
                ScrollView {
                    VStack(spacing: 20) {
                        // Interactive radial planner
                        InteractiveRadialView(date: currentDate, size: 320)
                            .padding(.vertical, 10)
                        
                        // Category legend
                        categoryLegend
                        
                        // Quick stats
                        statsSection
                    }
                    .padding(.horizontal)
                }
                
                // Task strip at bottom
                if !unscheduledTasks.isEmpty {
                    TaskStripView(tasks: unscheduledTasks) { task in
                        scheduleTask(task)
                    }
                }
            }
        }
        .onAppear {
            loadData()
        }
        .onChange(of: currentDate) { _, _ in
            loadData()
        }
    }
    
    private var dateNavigationBar: some View {
        HStack {
            IconButton(icon: "chevron.left") {
                changeDate(by: -1)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(currentDate, format: .dateTime.weekday(.wide))
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                Text(currentDate, format: .dateTime.month().day().year())
                    .font(themeManager.titleFont)
                    .foregroundColor(themeManager.textPrimaryColor)
            }
            
            Spacer()
            
            IconButton(icon: "chevron.right") {
                changeDate(by: 1)
            }
        }
    }
    
    private var categoryLegend: some View {
        let categories = storeContainer.categoryStore.fetchAll()
        
        return AppCard(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Categories")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(categories.prefix(6)) { category in
                        HStack(spacing: 6) {
                            Text(category.emoji)
                                .font(.system(size: 14))
                            
                            Text(category.name)
                                .font(themeManager.captionFont)
                                .foregroundColor(themeManager.textPrimaryColor)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Scheduled",
                value: "\(totalScheduledHours)h",
                icon: "calendar"
            )
            
            statCard(
                title: "Completed",
                value: "\(completedBlocks)",
                icon: "checkmark.circle"
            )
            
            statCard(
                title: "Remaining",
                value: "\(remainingBlocks)",
                icon: "clock"
            )
        }
    }
    
    private func statCard(title: String, value: String, icon: String) -> some View {
        AppCard(padding: 12) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.accent)
                
                Text(value)
                    .font(themeManager.subtitleFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Text(title)
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalScheduledHours: Int {
        let minutes = storeContainer.planStore.totalScheduledMinutesFor(date: currentDate)
        return minutes / 60
    }
    
    private var completedBlocks: Int {
        timeBlocks.filter { $0.isDone }.count
    }
    
    private var remainingBlocks: Int {
        timeBlocks.filter { !$0.isDone && !$0.isPast }.count
    }
    
    // MARK: - Actions
    
    private func loadData() {
        timeBlocks = storeContainer.planStore.fetchBlocksFor(date: currentDate)
        currentBlock = storeContainer.planStore.fetchCurrentBlock()
        loadUnscheduledTasks()
    }
    
    private func loadUnscheduledTasks() {
        // Get all unscheduled tasks
        let allUnscheduled = storeContainer.taskStore.fetchUnscheduled()
        
        // Filter out tasks that already have blocks today
        let todayBlockTaskIDs = Set(timeBlocks.compactMap { $0.taskID })
        unscheduledTasks = allUnscheduled.filter { !todayBlockTaskIDs.contains($0.id) }
    }
    
    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func scheduleTask(_ task: Task) {
        // Find next available slot
        let preferences = UserPreferences.load()
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
        components.hour = preferences.wakeHour
        components.minute = preferences.wakeMinute
        
        guard let startTime = calendar.date(from: components) else { return }
        
        // Find first free slot
        var proposedStart = startTime
        let duration = TimeInterval(task.estimatedDuration * 60)
        let proposedEnd = proposedStart.addingTimeInterval(duration)
        
        // Create block
        let block = TimeBlock(
            taskID: task.id,
            title: task.title,
            emoji: nil,
            startDate: proposedStart,
            endDate: proposedEnd,
            categoryID: task.categoryID,
            sourceType: .manual
        )
        
        if let created = storeContainer.planStore.createBlock(block) {
            timeBlocks.append(created)
            loadUnscheduledTasks()
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(ThemeManager())
        .environmentObject({
            let container = ModelContainer.createPreview()
            return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
        }())
}
