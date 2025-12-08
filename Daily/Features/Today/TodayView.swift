// Features/Today/Views/TodayView.swift

import SwiftUI
import SwiftData

enum TodayTab: String, CaseIterable {
    case radial = "Radial"
    case schedule = "Schedule"
    
    var icon: String {
        switch self {
        case .radial: return "circle.circle"
        case .schedule: return "list.bullet"
        }
    }
}

struct TodayView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    @State private var currentDate = Date()
    @State private var selectedTab: TodayTab = .radial
    @State private var unscheduledTasks: [Task] = []
    @State private var showStats = false
    @State private var showNewBlock = false
    
    var body: some View {
        ZStack {
            AppBackgroundView()
            
            VStack(spacing: 0) {
                // Date navigation
                headerSection
                
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                Group {
                    if selectedTab == .radial {
                        radialContent
                    } else {
                        scheduleContent
                    }
                }
                
                // Bottom action buttons
                bottomActionButtons
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                
                // Task strip (if unscheduled tasks exist)
                if !unscheduledTasks.isEmpty {
                    TaskStripView(tasks: unscheduledTasks) { task in
                        scheduleTask(task)
                    }
                }
            }
        }
        .sheet(isPresented: $showStats) {
            DayStatsPopup(date: currentDate)
        }
        .sheet(isPresented: $showNewBlock) {
            QuickTaskSheet(date: currentDate) { block in
                createBlock(block)
            }
        }
        .onAppear {
            loadUnscheduledTasks()
        }
        .onChange(of: currentDate) { _, _ in
            loadUnscheduledTasks()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
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
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 12) {
            ForEach(TodayTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14))
                        Text(tab.rawValue)
                            .font(themeManager.captionFont)
                    }
                    .foregroundColor(selectedTab == tab ?
                        (themeManager.accentColor == .mono ?
                            Color(light: .white, dark: .black) : .white) :
                        themeManager.textPrimaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedTab == tab ?
                        themeManager.accent : themeManager.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    // MARK: - Radial Content
    
    private var radialContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                InteractiveRadialView(
                    date: currentDate,
                    size: 360,
                    storeContainer: storeContainer
                )
            }
        }
    }
    
    // MARK: - Schedule Content
    
    private var scheduleContent: some View {
        ScrollView {
            TodayScheduledView(date: currentDate)
                .padding(.bottom, 80) // Extra padding for buttons
        }
    }
    
    // MARK: - Bottom Action Buttons
    
    private var bottomActionButtons: some View {
        VStack(spacing: 12) {
            // Stats button
            Button {
                showStats = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                    Text("View Stats")
                }
                .font(themeManager.buttonFont)
                .foregroundColor(themeManager.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(themeManager.cardBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadiusMedium)
                        .stroke(themeManager.accent, lineWidth: 2)
                )
            }
            
            // New Block button
            Button {
                showNewBlock = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("New Block")
                }
                .font(themeManager.buttonFont)
                .foregroundColor(themeManager.accentColor == .mono ?
                    Color(light: .white, dark: .black) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(themeManager.accent)
                .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadiusMedium))
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadUnscheduledTasks() {
        let timeBlocks = storeContainer.planStore.fetchBlocksFor(date: currentDate)
        let allUnscheduled = storeContainer.taskStore.fetchUnscheduled()
        let todayBlockTaskIDs = Set(timeBlocks.compactMap { $0.taskID })
        unscheduledTasks = allUnscheduled.filter { !todayBlockTaskIDs.contains($0.id) }
    }
    
    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func createBlock(_ block: TimeBlock) {
        if let created = storeContainer.planStore.createBlock(block) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
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
        let endTime = startTime.addingTimeInterval(duration)
        
        let block = TimeBlock(
            taskID: task.id,
            title: task.title,
            emoji: nil,
            startDate: startTime,
            endDate: endTime,
            categoryID: task.categoryID,
            sourceType: .manual
        )
        
        if let created = storeContainer.planStore.createBlock(block) {
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
