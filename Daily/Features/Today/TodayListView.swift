//  TodayListView.swift

import SwiftUI
import SwiftData

struct TodayListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    let date: Date
    
    @State private var timeBlocks: [TimeBlock] = []
    @State private var categories: [UUID: Category] = [:]
    @State private var selectedBlock: TimeBlock?
    @State private var showBlockDetail = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if timeBlocks.isEmpty {
                    emptyState
                } else {
                    // Group by time periods
                    if !morningBlocks.isEmpty {
                        timeSection(title: "Morning", blocks: morningBlocks)
                    }
                    
                    if !afternoonBlocks.isEmpty {
                        timeSection(title: "Afternoon", blocks: afternoonBlocks)
                    }
                    
                    if !eveningBlocks.isEmpty {
                        timeSection(title: "Evening", blocks: eveningBlocks)
                    }
                    
                    if !nightBlocks.isEmpty {
                        timeSection(title: "Night", blocks: nightBlocks)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            loadData()
        }
        .onChange(of: date) { _, _ in
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
    
    // MARK: - Time Sections
    
    private func timeSection(title: String, blocks: [TimeBlock]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(themeManager.subtitleFont)
                .foregroundColor(themeManager.textPrimaryColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                ForEach(blocks) { block in
                    TodayListBlockRow(
                        block: block,
                        category: block.categoryID != nil ? categories[block.categoryID!] : nil,
                        onTap: {
                            selectedBlock = block
                            showBlockDetail = true
                        },
                        onToggle: {
                            toggleBlock(block)
                        }
                    )
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundColor(themeManager.textTertiaryColor)
            
            Text("No blocks scheduled")
                .font(themeManager.bodyFont)
                .foregroundColor(themeManager.textSecondaryColor)
            
            Text("Switch to radial view to plan your day")
                .font(themeManager.captionFont)
                .foregroundColor(themeManager.textTertiaryColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Time Periods
    
    private var morningBlocks: [TimeBlock] {
        timeBlocks.filter { block in
            let hour = Calendar.current.component(.hour, from: block.startDate)
            return hour >= 5 && hour < 12
        }
    }
    
    private var afternoonBlocks: [TimeBlock] {
        timeBlocks.filter { block in
            let hour = Calendar.current.component(.hour, from: block.startDate)
            return hour >= 12 && hour < 17
        }
    }
    
    private var eveningBlocks: [TimeBlock] {
        timeBlocks.filter { block in
            let hour = Calendar.current.component(.hour, from: block.startDate)
            return hour >= 17 && hour < 21
        }
    }
    
    private var nightBlocks: [TimeBlock] {
        timeBlocks.filter { block in
            let hour = Calendar.current.component(.hour, from: block.startDate)
            return hour >= 21 || hour < 5
        }
    }
    
    // MARK: - Actions
    
    private func loadData() {
        timeBlocks = storeContainer.planStore.fetchBlocksFor(date: date)
            .sorted { $0.startDate < $1.startDate }
        
        let allCategories = storeContainer.categoryStore.fetchAll()
        categories = Dictionary(uniqueKeysWithValues: allCategories.map { ($0.id, $0) })
    }
    
    private func toggleBlock(_ block: TimeBlock) {
        var updated = block
        if updated.isDone {
            updated.markUndone()
        } else {
            updated.markDone()
        }
        
        if let saved = storeContainer.planStore.updateBlock(updated) {
            if let index = timeBlocks.firstIndex(where: { $0.id == saved.id }) {
                timeBlocks[index] = saved
            }
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

// MARK: - Today List Block Row

struct TodayListBlockRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let block: TimeBlock
    let category: Category?
    let onTap: () -> Void
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            AppCard(padding: 16) {
                HStack(spacing: 16) {
                    // Time
                    VStack(alignment: .leading, spacing: 2) {
                        Text(block.startDate, format: .dateTime.hour().minute())
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(themeManager.textPrimaryColor)
                        
                        Text(block.endDate, format: .dateTime.hour().minute())
                            .font(themeManager.captionFont)
                            .foregroundColor(themeManager.textTertiaryColor)
                    }
                    .frame(width: 70, alignment: .leading)
                    
                    // Vertical line with category color
                    Rectangle()
                        .fill(categoryColor)
                        .frame(width: 3)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                    
                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            if let emoji = block.emoji {
                                Text(emoji)
                                    .font(.system(size: 20))
                            }
                            
                            Text(block.title)
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(block.isDone ? themeManager.textSecondaryColor : themeManager.textPrimaryColor)
                                .strikethrough(block.isDone)
                        }
                        
                        HStack(spacing: 12) {
                            // Category
                            if let category = category {
                                HStack(spacing: 4) {
                                    Text(category.emoji)
                                        .font(.system(size: 12))
                                    Text(category.name)
                                        .font(themeManager.captionFont)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                }
                            }
                            
                            // Duration
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                Text("\(block.durationMinutes)m")
                                    .font(themeManager.captionFont)
                            }
                            .foregroundColor(themeManager.textTertiaryColor)
                            
                            // Status indicator
                            if block.isInProgress {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(themeManager.accent)
                                        .frame(width: 6, height: 6)
                                    Text("Now")
                                        .font(themeManager.captionFont)
                                        .foregroundColor(themeManager.accent)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Checkbox
                    Button(action: onToggle) {
                        Image(systemName: block.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 28))
                            .foregroundColor(block.isDone ? .green : themeManager.textSecondaryColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .buttonStyle(.plain)
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
}

#Preview {
    TodayListView(date: Date())
        .environmentObject(ThemeManager())
        .environmentObject({
            let container = ModelContainer.createPreview()
            return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
        }())
}
