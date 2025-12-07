// Features/Today/Views/DayStatsPopup.swift

import SwiftUI
import SwiftData

struct DayStatsPopup: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    @Environment(\.dismiss) var dismiss
    
    let date: Date
    
    @State private var timeBlocks: [TimeBlock] = []
    @State private var categories: [UUID: Category] = [:]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Date header
                        dateHeader
                        
                        // Overview stats
                        overviewStats
                        
                        // Category breakdown
                        categoryBreakdown
                        
                        // Completion details
                        completionDetails
                        
                        // Time distribution
                        timeDistribution
                    }
                    .padding()
                }
            }
            .navigationTitle("Day Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
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
    
    // MARK: - Date Header
    
    private var dateHeader: some View {
        VStack(spacing: 4) {
            Text(date, format: .dateTime.weekday(.wide))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.textSecondaryColor)
            
            Text(date, format: .dateTime.month().day().year())
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.textPrimaryColor)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Overview Stats
    
    private var overviewStats: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Scheduled",
                value: totalScheduledFormatted,
                icon: "calendar",
                color: themeManager.accent
            )
            
            statCard(
                title: "Completed",
                value: "\(completedCount)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            statCard(
                title: "Remaining",
                value: "\(remainingCount)",
                icon: "clock",
                color: .orange
            )
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        AppCard(padding: 16) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Text(title)
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Category Breakdown
    
    private var categoryBreakdown: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .foregroundColor(themeManager.accent)
                    
                    Text("Category Breakdown")
                        .font(themeManager.subtitleFont)
                        .foregroundColor(themeManager.textPrimaryColor)
                }
                
                if categorySummary.isEmpty {
                    Text("No blocks scheduled")
                        .font(themeManager.bodyFont)
                        .foregroundColor(themeManager.textSecondaryColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 12) {
                        ForEach(categorySummary, id: \.0.id) { category, minutes in
                            categoryRow(category: category, minutes: minutes)
                        }
                    }
                }
            }
        }
    }
    
    private func categoryRow(category: Category, minutes: Int) -> some View {
        let percentage = totalScheduledMinutes > 0 ?
            Double(minutes) / Double(totalScheduledMinutes) * 100 : 0
        
        return VStack(spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    Text(category.emoji)
                        .font(.system(size: 18))
                    
                    Text(category.name)
                        .font(themeManager.bodyFont)
                        .foregroundColor(themeManager.textPrimaryColor)
                }
                
                Spacer()
                
                Text(formatMinutes(minutes))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Text("(\(Int(percentage))%)")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(themeManager.cardBackgroundColor)
                        .frame(height: 6)
                    
                    Rectangle()
                        .fill(categoryColor(for: category))
                        .frame(width: geometry.size.width * (percentage / 100), height: 6)
                }
                .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .frame(height: 6)
        }
    }
    
    // MARK: - Completion Details
    
    private var completionDetails: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
                        .foregroundColor(themeManager.accent)
                    
                    Text("Completion Status")
                        .font(themeManager.subtitleFont)
                        .foregroundColor(themeManager.textPrimaryColor)
                }
                
                HStack(spacing: 16) {
                    completionBadge(
                        icon: "checkmark.circle.fill",
                        label: "Done",
                        count: completedCount,
                        color: .green
                    )
                    
                    completionBadge(
                        icon: "clock.fill",
                        label: "Pending",
                        count: remainingCount,
                        color: .orange
                    )
                    
                    completionBadge(
                        icon: "circle.fill",
                        label: "Total",
                        count: timeBlocks.count,
                        color: themeManager.accent
                    )
                }
            }
        }
    }
    
    private func completionBadge(icon: String, label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.textPrimaryColor)
            
            Text(label)
                .font(themeManager.captionFont)
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Time Distribution
    
    private var timeDistribution: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(themeManager.accent)
                    
                    Text("Time Distribution")
                        .font(themeManager.subtitleFont)
                        .foregroundColor(themeManager.textPrimaryColor)
                }
                
                VStack(spacing: 12) {
                    timeSlot(period: "Morning", hours: morningHours, icon: "sunrise.fill", color: .orange)
                    timeSlot(period: "Afternoon", hours: afternoonHours, icon: "sun.max.fill", color: .yellow)
                    timeSlot(period: "Evening", hours: eveningHours, icon: "sunset.fill", color: .pink)
                    timeSlot(period: "Night", hours: nightHours, icon: "moon.stars.fill", color: .purple)
                }
            }
        }
    }
    
    private func timeSlot(period: String, hours: Double, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(period)
                .font(themeManager.bodyFont)
                .foregroundColor(themeManager.textPrimaryColor)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Text(String(format: "%.1fh", hours))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.textPrimaryColor)
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalScheduledMinutes: Int {
        timeBlocks.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var totalScheduledFormatted: String {
        let hours = totalScheduledMinutes / 60
        let minutes = totalScheduledMinutes % 60
        return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
    }
    
    private var completedCount: Int {
        timeBlocks.filter { $0.isDone }.count
    }
    
    private var remainingCount: Int {
        timeBlocks.filter { !$0.isDone }.count
    }
    
    private var categorySummary: [(Category, Int)] {
        var categoryMinutes: [UUID: Int] = [:]
        
        for block in timeBlocks {
            if let catID = block.categoryID {
                categoryMinutes[catID, default: 0] += block.durationMinutes
            }
        }
        
        return categoryMinutes.compactMap { catID, minutes in
            guard let category = categories[catID] else { return nil }
            return (category, minutes)
        }
        .sorted { $0.1 > $1.1 }
    }
    
    // Time period calculations
    private var morningHours: Double {
        timeInPeriod(start: 5, end: 12)
    }
    
    private var afternoonHours: Double {
        timeInPeriod(start: 12, end: 17)
    }
    
    private var eveningHours: Double {
        timeInPeriod(start: 17, end: 21)
    }
    
    private var nightHours: Double {
        let night1 = timeInPeriod(start: 21, end: 24)
        let night2 = timeInPeriod(start: 0, end: 5)
        return night1 + night2
    }
    
    private func timeInPeriod(start: Int, end: Int) -> Double {
        let calendar = Calendar.current
        var minutes = 0
        
        for block in timeBlocks {
            let hour = calendar.component(.hour, from: block.startDate)
            if hour >= start && hour < end {
                minutes += block.durationMinutes
            }
        }
        
        return Double(minutes) / 60.0
    }
    
    // MARK: - Helper Methods
    
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
    
    private func categoryColor(for category: Category) -> Color {
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
    
    private func loadData() {
        timeBlocks = storeContainer.planStore.fetchBlocksFor(date: date)
        
        let allCategories = storeContainer.categoryStore.fetchAll()
        categories = Dictionary(uniqueKeysWithValues: allCategories.map { ($0.id, $0) })
    }
}

#Preview {
    DayStatsPopup(date: Date())
        .environmentObject(ThemeManager())
        .environmentObject({
            let container = ModelContainer.createPreview()
            return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
        }())
}
