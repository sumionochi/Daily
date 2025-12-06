//
//  DailyStatsView.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Features/Stats/Views/DailyStatsView.swift

import SwiftUI
import Charts
import SwiftData

struct DailyStatsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    let date: Date
    
    @State private var timeBlocks: [TimeBlock] = []
    @State private var categories: [UUID: Category] = [:]
    @State private var stats: DailyStats?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overview cards
                overviewSection
                
                // Category breakdown
                categoryBreakdownSection
                
                // Completion stats
                completionSection
            }
            .padding()
        }
        .onAppear {
            loadStats()
        }
        .onChange(of: date) { _, _ in
            loadStats()
        }
    }
    
    // MARK: - Overview Section
    
    private var overviewSection: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Planned",
                value: stats?.totalPlannedFormatted ?? "0h",
                color: themeManager.accent
            )
            
            statCard(
                title: "Actual",
                value: stats?.totalActualFormatted ?? "0h",
                color: .green
            )
            
            statCard(
                title: "Rate",
                value: "\(stats?.completionRate ?? 0)%",
                color: stats?.completionRate ?? 0 >= 80 ? .green : .orange
            )
        }
    }
    
    private func statCard(title: String, value: String, color: Color) -> some View {
        AppCard(padding: 16) {
            VStack(spacing: 8) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                Text(title)
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Category Breakdown
    
    private var categoryBreakdownSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Time by Category")
                    .font(themeManager.subtitleFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                if let categoryStats = stats?.categoryStats, !categoryStats.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(categoryStats.sorted(by: { $0.minutes > $1.minutes }), id: \.categoryID) { stat in
                            categoryRow(stat: stat)
                        }
                    }
                } else {
                    Text("No data for this day")
                        .font(themeManager.bodyFont)
                        .foregroundColor(themeManager.textSecondaryColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
            }
        }
    }
    
    private func categoryRow(stat: CategoryStat) -> some View {
        let category = stat.categoryID != nil ? categories[stat.categoryID!] : nil
        let percentage = stats?.totalPlannedMinutes ?? 0 > 0 ?
            Double(stat.minutes) / Double(stats!.totalPlannedMinutes) * 100 : 0
        
        return VStack(spacing: 4) {
            HStack {
                // Category info
                HStack(spacing: 8) {
                    if let category = category {
                        Text(category.emoji)
                            .font(.system(size: 16))
                        Text(category.name)
                            .font(themeManager.bodyFont)
                            .foregroundColor(themeManager.textPrimaryColor)
                    } else {
                        Text("Uncategorized")
                            .font(themeManager.bodyFont)
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                }
                
                Spacer()
                
                // Time
                Text(stat.hoursFormatted)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(themeManager.textPrimaryColor)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(themeManager.cardBackgroundColor)
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(categoryColor(for: category))
                        .frame(width: geometry.size.width * (percentage / 100), height: 4)
                }
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
            .frame(height: 4)
        }
    }
    
    private func categoryColor(for category: Category?) -> Color {
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
    
    // MARK: - Completion Section
    
    private var completionSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Completion")
                    .font(themeManager.subtitleFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                HStack(spacing: 20) {
                    completionBadge(
                        count: stats?.completedCount ?? 0,
                        label: "Completed",
                        color: .green
                    )
                    
                    completionBadge(
                        count: stats?.pendingCount ?? 0,
                        label: "Remaining",
                        color: .orange
                    )
                    
                    completionBadge(
                        count: stats?.totalCount ?? 0,
                        label: "Total",
                        color: themeManager.accent
                    )
                }
            }
        }
    }
    
    private func completionBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(themeManager.captionFont)
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Data Loading
    
    private func loadStats() {
        timeBlocks = storeContainer.planStore.fetchBlocksFor(date: date)
        
        let allCategories = storeContainer.categoryStore.fetchAll()
        categories = Dictionary(uniqueKeysWithValues: allCategories.map { ($0.id, $0) })
        
        stats = DailyStats.calculate(from: timeBlocks)
    }
}

// MARK: - Daily Stats Model

struct DailyStats {
    let totalPlannedMinutes: Int
    let totalActualMinutes: Int
    let completedCount: Int
    let pendingCount: Int
    let totalCount: Int
    let categoryStats: [CategoryStat]
    
    var totalPlannedFormatted: String {
        let hours = totalPlannedMinutes / 60
        let minutes = totalPlannedMinutes % 60
        return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
    }
    
    var totalActualFormatted: String {
        let hours = totalActualMinutes / 60
        let minutes = totalActualMinutes % 60
        return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
    }
    
    var completionRate: Int {
        guard totalPlannedMinutes > 0 else { return 0 }
        return Int((Double(totalActualMinutes) / Double(totalPlannedMinutes)) * 100)
    }
    
    static func calculate(from blocks: [TimeBlock]) -> DailyStats {
        let totalPlanned = blocks.reduce(0) { $0 + $1.durationMinutes }
        let totalActual = blocks.reduce(0) { $0 + ($1.actualDurationMinutes ?? 0) }
        let completed = blocks.filter { $0.isDone }.count
        let pending = blocks.filter { !$0.isDone }.count
        
        // Group by category
        var categoryDict: [UUID?: Int] = [:]
        for block in blocks {
            categoryDict[block.categoryID, default: 0] += block.durationMinutes
        }
        
        let categoryStats = categoryDict.map { categoryID, minutes in
            CategoryStat(categoryID: categoryID, minutes: minutes)
        }
        
        return DailyStats(
            totalPlannedMinutes: totalPlanned,
            totalActualMinutes: totalActual,
            completedCount: completed,
            pendingCount: pending,
            totalCount: blocks.count,
            categoryStats: categoryStats
        )
    }
}

struct CategoryStat {
    let categoryID: UUID?
    let minutes: Int
    
    var hoursFormatted: String {
        let hours = minutes / 60
        let mins = minutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }
}

#Preview {
    DailyStatsView(date: Date())
        .environmentObject(ThemeManager())
        .environmentObject({
            let container = ModelContainer.createPreview()
            return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
        }())
}
