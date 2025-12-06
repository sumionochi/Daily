//
//  TodayViewiPad.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Features/Today/Views/TodayViewiPad.swift

import SwiftUI
import SwiftData

struct TodayViewiPad: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    @State private var currentDate = Date()
    @State private var timeBlocks: [TimeBlock] = []
    @State private var unscheduledTasks: [Task] = []
    @State private var selectedBlock: TimeBlock?
    @State private var showBlockDetail = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppBackgroundView()
                
                HStack(spacing: 0) {
                    // Left: Radial planner
                    leftPanel
                        .frame(width: geometry.size.width * 0.55)
                    
                    Divider()
                    
                    // Right: Task list & details
                    rightPanel
                        .frame(width: geometry.size.width * 0.45)
                }
            }
        }
        .onAppear {
            loadData()
        }
        .onChange(of: currentDate) { _, _ in
            loadData()
        }
        .sheet(isPresented: $showBlockDetail) {
            if let selected = selectedBlock {
                BlockDetailSheet(
                    block: selected,
                    onSave: { updated in
                        updateBlock(updated)
                    },
                    onDelete: {
                        deleteBlock(selected)
                    }
                )
            }
        }
    }
    
    // MARK: - Left Panel
    
    private var leftPanel: some View {
        VStack(spacing: 20) {
            // Date navigation
            dateNavigationBar
                .padding(.horizontal, 30)
                .padding(.top, 20)
            
            Spacer()
            
            // Radial planner (larger for iPad)
            InteractiveRadialViewiPad(
                date: currentDate,
                size: 450,
                onBlockTapped: { block in
                    selectedBlock = block
                    showBlockDetail = true
                }
            )
            
            Spacer()
            
            // Stats row
            statsSection
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
        }
    }
    
    // MARK: - Right Panel
    
    private var rightPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Tasks & Schedule")
                    .font(themeManager.titleFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Spacer()
            }
            .padding(20)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Unscheduled tasks
                    if !unscheduledTasks.isEmpty {
                        unscheduledSection
                    }
                    
                    // Today's blocks list
                    scheduledBlocksSection
                    
                    // Category legend
                    categoryLegend
                }
                .padding(20)
            }
        }
        .background(themeManager.secondaryBackgroundColor.opacity(0.3))
    }
    
    // MARK: - Components
    
    private var dateNavigationBar: some View {
        HStack {
            IconButton(icon: "chevron.left") {
                changeDate(by: -1)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(currentDate, format: .dateTime.weekday(.wide))
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                Text(currentDate, format: .dateTime.month().day().year())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.textPrimaryColor)
            }
            
            Spacer()
            
            IconButton(icon: "chevron.right") {
                changeDate(by: 1)
            }
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
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
        AppCard(padding: 16) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.accent)
                
                Text(value)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Text(title)
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var unscheduledSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Unscheduled")
                    .font(themeManager.subtitleFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Spacer()
                
                Text("\(unscheduledTasks.count)")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            
            VStack(spacing: 8) {
                ForEach(unscheduledTasks) { task in
                    Button {
                        scheduleTask(task)
                    } label: {
                        iPadTaskRow(task: task)
                    }
                }
            }
        }
    }
    
    private var scheduledBlocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Schedule")
                    .font(themeManager.subtitleFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Spacer()
                
                Text("\(timeBlocks.count) blocks")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            
            VStack(spacing: 8) {
                ForEach(timeBlocks.sorted(by: { $0.startDate < $1.startDate })) { block in
                    Button {
                        selectedBlock = block
                        showBlockDetail = true
                    } label: {
                        iPadBlockRow(block: block)
                    }
                }
            }
        }
    }
    
    private func iPadTaskRow(task: Task) -> some View {
        AppCard(padding: 12) {
            HStack(spacing: 12) {
                Image(systemName: "circle")
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.textSecondaryColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(themeManager.bodyFont)
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    Text("\(task.estimatedDuration)m")
                        .font(themeManager.captionFont)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.accent)
            }
        }
    }
    
    private func iPadBlockRow(block: TimeBlock) -> some View {
        let category = block.categoryID != nil ? 
            storeContainer.categoryStore.fetchByID(block.categoryID!) : nil
        
        return AppCard(padding: 12) {
            HStack(spacing: 12) {
                // Time
                VStack(alignment: .leading, spacing: 2) {
                    Text(block.startDate, format: .dateTime.hour().minute())
                        .font(themeManager.captionFont)
                        .foregroundColor(themeManager.textSecondaryColor)
                    
                    Text(block.endDate, format: .dateTime.hour().minute())
                        .font(themeManager.captionFont)
                        .foregroundColor(themeManager.textTertiaryColor)
                }
                .frame(width: 60, alignment: .leading)
                
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
                    }
                    
                    if let category = category {
                        HStack(spacing: 4) {
                            Text(category.emoji)
                                .font(.system(size: 12))
                            Text(category.name)
                                .font(themeManager.captionFont)
                                .foregroundColor(themeManager.textSecondaryColor)
                        }
                    }
                }
                
                Spacer()
                
                // Status
                if block.isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private var categoryLegend: some View {
        let categories = storeContainer.categoryStore.fetchAll()
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(themeManager.subtitleFont)
                .foregroundColor(themeManager.textPrimaryColor)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(categories) { category in
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
            timeBlocks.append(created)
            loadUnscheduledTasks()
            
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
    
    private func updateBlock(_ block: TimeBlock) {
        if let updated = storeContainer.planStore.updateBlock(block) {
            if let index = timeBlocks.firstIndex(where: { $0.id == updated.id }) {
                timeBlocks[index] = updated
            }
        }
    }
    
    private func deleteBlock(_ block: TimeBlock) {
        if storeContainer.planStore.deleteBlock(block.id) {
            timeBlocks.removeAll { $0.id == block.id }
        }
    }
}

#Preview {
    TodayViewiPad()
        .environmentObject(ThemeManager())
        .environmentObject({
            let container = ModelContainer.createPreview()
            return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
        }())
}
