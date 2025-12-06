// Features/Today/Views/TodayView.swift

import SwiftUI
import SwiftData

enum TodayViewMode: String, CaseIterable {
    case radial = "Radial"
    case list = "List"
    
    var icon: String {
        switch self {
        case .radial: return "circle.circle"
        case .list: return "list.bullet"
        }
    }
}

struct TodayView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    @State private var currentDate = Date()
    @State private var timeBlocks: [TimeBlock] = []
    @State private var unscheduledTasks: [Task] = []
    @State private var currentBlock: TimeBlock?
    @State private var viewMode: TodayViewMode = .radial
    
    var body: some View {
        ZStack {
            AppBackgroundView()
            
            VStack(spacing: 0) {
                // Date navigation with view mode toggle
                headerSection
                
                // Main content based on mode
                Group {
                    if viewMode == .radial {
                        radialModeContent
                    } else {
                        listModeContent
                    }
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
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Date navigation
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
            
            // View mode toggle
            HStack {
                ForEach(TodayViewMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewMode = mode
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 14))
                            Text(mode.rawValue)
                                .font(themeManager.captionFont)
                        }
                        .foregroundColor(viewMode == mode ? .white : themeManager.textPrimaryColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(viewMode == mode ? themeManager.accent : themeManager.cardBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 60)
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Radial Mode Content
    
    private var radialModeContent: some View {
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
    }
    
    // MARK: - List Mode Content
    
    private var listModeContent: some View {
        VStack(spacing: 0) {
            // Stats row
            statsSection
                .padding(.horizontal)
                .padding(.top, 12)
            
            // List view
            TodayListView(date: currentDate)
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
        let allUnscheduled = storeContainer.taskStore.fetchUnscheduled()
        let todayBlockTaskIDs = Set(timeBlocks.compactMap { $0.taskID })
        unscheduledTasks = allUnscheduled.filter { !todayBlockTaskIDs.contains($0.id) }
    }
    
    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func scheduleTask(_ task: Task) {
        let preferences = UserPreferences.load()
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
        components.hour = preferences.wakeHour
        components.minute = preferences.wakeMinute
        
        guard let startTime = calendar.date(from: components) else { return }
        
        let duration = TimeInterval(task.estimatedDuration * 60)
        let proposedEnd = startTime.addingTimeInterval(duration)
        
        let block = TimeBlock(
            taskID: task.id,
            title: task.title,
            emoji: nil,
            startDate: startTime,
            endDate: proposedEnd,
            categoryID: task.categoryID,
            sourceType: .manual
        )
        
        if let created = storeContainer.planStore.createBlock(block) {
            timeBlocks.append(created)
            loadUnscheduledTasks()
            
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
