//
//  EndOfDaySummaryView.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Features/Stats/Views/EndOfDaySummaryView.swift

import SwiftUI
import SwiftData

struct EndOfDaySummaryView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    @Environment(\.dismiss) var dismiss
    
    let date: Date
    
    @State private var timeBlocks: [TimeBlock] = []
    @State private var unfinishedTasks: [Task] = []
    @State private var stats: DailyStats?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Stats summary
                        statsSection
                        
                        // Category pie chart visualization
                        categoryVisualization
                        
                        // Unfinished tasks
                        if !unfinishedTasks.isEmpty {
                            unfinishedTasksSection
                        }
                        
                        // Actions
                        actionButtons
                    }
                    .padding()
                }
            }
            .navigationTitle("Day Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: stats?.completionRate ?? 0 >= 80 ? "checkmark.circle.fill" : "chart.pie.fill")
                .font(.system(size: 60))
                .foregroundColor(stats?.completionRate ?? 0 >= 80 ? .green : themeManager.accent)
            
            Text(date, format: .dateTime.month().day().year())
                .font(themeManager.titleFont)
                .foregroundColor(themeManager.textPrimaryColor)
            
            Text(summaryMessage)
                .font(themeManager.bodyFont)
                .foregroundColor(themeManager.textSecondaryColor)
                .multilineTextAlignment(.center)
        }
    }
    
    private var summaryMessage: String {
        let rate = stats?.completionRate ?? 0
        if rate >= 90 {
            return "Excellent work! You crushed today! 🎉"
        } else if rate >= 70 {
            return "Great job! You got most things done! 👏"
        } else if rate >= 50 {
            return "Good effort! Keep it up! 💪"
        } else {
            return "Tomorrow is a new day! 🌅"
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        AppCard {
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    statItem(
                        label: "Planned",
                        value: stats?.totalPlannedFormatted ?? "0h"
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    statItem(
                        label: "Completed",
                        value: stats?.totalActualFormatted ?? "0h"
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    statItem(
                        label: "Rate",
                        value: "\(stats?.completionRate ?? 0)%"
                    )
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(themeManager.cardBackgroundColor)
                            .frame(height: 8)
                        
                        Rectangle()
                            .fill(
                                stats?.completionRate ?? 0 >= 80 ? Color.green :
                                stats?.completionRate ?? 0 >= 50 ? Color.orange : Color.red
                            )
                            .frame(
                                width: geometry.size.width * (Double(stats?.completionRate ?? 0) / 100),
                                height: 8
                            )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .frame(height: 8)
            }
        }
    }
    
    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.textPrimaryColor)
            
            Text(label)
                .font(themeManager.captionFont)
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Category Visualization
    
    private var categoryVisualization: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Time Breakdown")
                    .font(themeManager.subtitleFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                if let categoryStats = stats?.categoryStats, !categoryStats.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(categoryStats.sorted(by: { $0.minutes > $1.minutes }).prefix(5), id: \.categoryID) { stat in
                            categoryBar(stat: stat)
                        }
                    }
                }
            }
        }
    }
    
    private func categoryBar(stat: CategoryStat) -> some View {
        let category = stat.categoryID != nil ? 
            storeContainer.categoryStore.fetchByID(stat.categoryID!) : nil
        
        return HStack(spacing: 12) {
            if let category = category {
                Text(category.emoji)
                    .font(.system(size: 20))
                
                Text(category.name)
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .frame(width: 80, alignment: .leading)
            } else {
                Text("⚪️")
                    .font(.system(size: 20))
                
                Text("Other")
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textSecondaryColor)
                    .frame(width: 80, alignment: .leading)
            }
            
            Text(stat.hoursFormatted)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.textPrimaryColor)
                .frame(width: 60, alignment: .trailing)
        }
    }
    
    // MARK: - Unfinished Tasks
    
    private var unfinishedTasksSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Unfinished Tasks")
                        .font(themeManager.subtitleFont)
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    Spacer()
                    
                    Text("\(unfinishedTasks.count)")
                        .font(themeManager.captionFont)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
                
                VStack(spacing: 8) {
                    ForEach(unfinishedTasks.prefix(5)) { task in
                        HStack {
                            Image(systemName: "circle")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.textTertiaryColor)
                            
                            Text(task.title)
                                .font(themeManager.bodyFont)
                                .foregroundColor(themeManager.textPrimaryColor)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !unfinishedTasks.isEmpty {
                PrimaryButton("Roll Over to Tomorrow", icon: "arrow.right.circle") {
                    rollOverTasks()
                }
            }
            
            SecondaryButton("View Detailed Stats", icon: "chart.bar") {
                // TODO: Navigate to detailed stats
                dismiss()
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        timeBlocks = storeContainer.planStore.fetchBlocksFor(date: date)
        stats = DailyStats.calculate(from: timeBlocks)
        
        // Find unfinished tasks
        let blockTaskIDs = Set(timeBlocks.compactMap { $0.taskID })
        let allTasks = storeContainer.taskStore.fetchAll()
        unfinishedTasks = allTasks.filter { task in
            blockTaskIDs.contains(task.id) && !task.isCompleted
        }
    }
    
    // MARK: - Actions
    
    private func rollOverTasks() {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) else { return }
        
        let preferences = UserPreferences.load()
        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = preferences.wakeHour
        components.minute = preferences.wakeMinute
        
        guard var currentTime = calendar.date(from: components) else { return }
        
        // Schedule unfinished tasks for tomorrow
        for task in unfinishedTasks {
            let duration = TimeInterval(task.estimatedDuration * 60)
            let endTime = currentTime.addingTimeInterval(duration)
            
            let block = TimeBlock(
                taskID: task.id,
                title: task.title,
                emoji: nil,
                startDate: currentTime,
                endDate: endTime,
                categoryID: task.categoryID,
                sourceType: .manual
            )
            
            _ = storeContainer.planStore.createBlock(block)
            
            // Move time forward for next task
            currentTime = endTime.addingTimeInterval(300) // 5 min gap
        }
        
        // Haptic feedback
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        
        dismiss()
    }
}

#Preview {
    EndOfDaySummaryView(date: Date())
        .environmentObject(ThemeManager())
        .environmentObject({
            let container = ModelContainer.createPreview()
            return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
        }())
}
