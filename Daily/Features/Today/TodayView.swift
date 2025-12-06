// Features/Today/Views/TodayView.swift

import SwiftUI
import SwiftData

struct TodayView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    @State private var currentDate = Date()
    @State private var timeBlocks: [TimeBlock] = []
    @State private var currentBlock: TimeBlock?
    
    var body: some View {
        ZStack {
            AppBackgroundView()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Date navigation
                    dateNavigationBar
                    
                    // Radial planner
                    RadialDayView(date: currentDate, size: 320)
                        .padding(.vertical, 10)
                    
                    // Category legend
                    categoryLegend
                    
                    // Quick stats
                    statsSection
                }
                .padding()
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
    }
    
    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) {
            currentDate = newDate
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
