// Features/Today/Views/TodayScheduledView.swift

import SwiftUI
import Combine
import SwiftData

struct TodayScheduledView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    let date: Date
    
    @State private var timeBlocks: [TimeBlock] = []
    @State private var categories: [UUID: Category] = [:]
    @State private var refreshID = UUID()
    @State private var isAnySheetPresented = false
    
    // Timer for real-time updates
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 16) {
            // Date header
            dateHeader
            
            // Grouped by time period
            if !timeBlocks.isEmpty {
                ForEach(timePeriods, id: \.name) { period in
                    let periodBlocks = blocksInPeriod(period)
                    
                    if !periodBlocks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            // Period header
                            HStack {
                                Text(period.name)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(themeManager.textSecondaryColor)
                                
                                Text(period.timeRange)
                                    .font(themeManager.captionFont)
                                    .foregroundColor(themeManager.textTertiaryColor)
                            }
                            .padding(.horizontal)
                            
                            // Blocks in period
                            VStack(spacing: 8) {
                                ForEach(periodBlocks) { block in
                                    TodayBlockRow(
                                        block: block,
                                        category: block.categoryID != nil ? categories[block.categoryID!] : nil,
                                        onUpdate: {
                                            loadData()
                                        },
                                        onSheetStateChange: { isPresented in
                                            isAnySheetPresented = isPresented
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            } else {
                emptyState
            }
        }
        .padding(.vertical, 16)
        .id(refreshID)
        .onAppear {
            loadData()
        }
        .onChange(of: date) { _, _ in
            loadData()
        }
        .onReceive(timer) { _ in
            // Only refresh if no sheet is open
            if !isAnySheetPresented {
                refreshID = UUID()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BlocksUpdated"))) { _ in
            // Only reload if no sheet is open
            if !isAnySheetPresented {
                loadData()
            }
        }
    }
    
    // MARK: - Date Header
    
    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Calendar.current.isDateInToday(date) ? "Today" : "Schedule")
                    .font(themeManager.subtitleFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Text(date, format: .dateTime.weekday().month().day())
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(timeBlocks.count)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.accent)
                
                Text("blocks")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundColor(themeManager.textTertiaryColor)
            
            Text("Nothing scheduled")
                .font(themeManager.subtitleFont)
                .foregroundColor(themeManager.textPrimaryColor)
            
            Text("Tap + New Block to add")
                .font(themeManager.bodyFont)
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Computed Properties
    
    private var timePeriods: [(name: String, timeRange: String, startHour: Int, endHour: Int)] {
        [
            ("Morning", "5AM - 12PM", 5, 12),
            ("Afternoon", "12PM - 5PM", 12, 17),
            ("Evening", "5PM - 9PM", 17, 21),
            ("Night", "9PM - 5AM", 21, 29) // 29 = next day 5AM
        ]
    }
    
    private func blocksInPeriod(_ period: (name: String, timeRange: String, startHour: Int, endHour: Int)) -> [TimeBlock] {
        let calendar = Calendar.current
        return timeBlocks.filter { block in
            let hour = calendar.component(.hour, from: block.startDate)
            if period.endHour > 24 {
                return hour >= period.startHour || hour < (period.endHour - 24)
            } else {
                return hour >= period.startHour && hour < period.endHour
            }
        }
        .sorted { $0.startDate < $1.startDate }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        timeBlocks = storeContainer.planStore.fetchBlocksFor(date: date)
        
        let allCategories = storeContainer.categoryStore.fetchAll()
        categories = Dictionary(uniqueKeysWithValues: allCategories.map { ($0.id, $0) })
    }
}

// MARK: - Today Block Row

struct TodayBlockRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    let block: TimeBlock
    let category: Category?
    let onUpdate: () -> Void
    let onSheetStateChange: (Bool) -> Void
    
    @State private var isSheetPresented = false
    @State private var isCompleted: Bool
    
    init(block: TimeBlock, category: Category?, onUpdate: @escaping () -> Void, onSheetStateChange: @escaping (Bool) -> Void) {
        self.block = block
        self.category = category
        self.onUpdate = onUpdate
        self.onSheetStateChange = onSheetStateChange
        _isCompleted = State(initialValue: block.isDone)
    }
    
    var body: some View {
        Button {
            isSheetPresented = true
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
                            
                            // Now indicator
                            if isCurrentBlock {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                    
                                    Text("Now")
                                        .font(themeManager.captionFont)
                                        .foregroundColor(.green)
                                }
                            }
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
        .sheet(isPresented: $isSheetPresented) {
            BlockDetailSheet(
                block: block,
                onSave: { updated in
                    if let _ = storeContainer.planStore.updateBlock(updated) {
                        NotificationCenter.default.post(name: NSNotification.Name("BlocksUpdated"), object: nil)
                        onUpdate()
                    }
                },
                onDelete: {
                    if storeContainer.planStore.deleteBlock(block.id) {
                        NotificationCenter.default.post(name: NSNotification.Name("BlocksUpdated"), object: nil)
                        onUpdate()
                    }
                }
            )
        }
        .onChange(of: isSheetPresented) { _, newValue in
            onSheetStateChange(newValue)
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
    
    private var isCurrentBlock: Bool {
        let now = Date()
        return block.startDate <= now && now < block.endDate
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
            onUpdate()
            
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
}

#Preview {
    TodayScheduledView(date: Date())
        .environmentObject(ThemeManager())
        .environmentObject({
            let container = ModelContainer.createPreview()
            return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
        }())
}
