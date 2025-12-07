// Features/Radial/InteractiveRadialView.swift

import SwiftUI
import SwiftData

struct InteractiveRadialView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    let date: Date
    let size: CGFloat
    
    @State private var timeBlocks: [TimeBlock] = []
    @State private var categories: [UUID: Category] = [:]
    @State private var currentTime = Date()
    @State private var draggedBlock: TimeBlock?
    @State private var selectedBlock: TimeBlock?
    @State private var showBlockDetail = false
    @State private var conflicts: Set<UUID> = []
    
    // Radial dimensions - refined
    private let outerRadius: CGFloat
    private let innerRadius: CGFloat
    private let arcThickness: CGFloat = 32
    
    init(date: Date, size: CGFloat = 360) {
        self.date = date
        self.size = size
        self.outerRadius = size / 2 - 20
        self.innerRadius = outerRadius - 60 // Space for ticks
    }
    
    var body: some View {
        ZStack {
            // Clock face with ticks
            RadialClockFace(radius: outerRadius)
            
            // Time blocks as thin arcs
            ForEach(timeBlocks) { block in
                if block.id != draggedBlock?.id {
                    RadialBlockView(
                        block: block,
                        innerRadius: innerRadius,
                        outerRadius: outerRadius,
                        category: block.categoryID != nil ? categories[block.categoryID!] : nil
                    )
                    .onTapGesture {
                        selectedBlock = block
                        showBlockDetail = true
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { _ in
                                draggedBlock = block
                            }
                    )
                }
            }
            
            // Dragged block overlay
            if let dragged = draggedBlock {
                RadialBlockView(
                    block: dragged,
                    innerRadius: innerRadius,
                    outerRadius: outerRadius,
                    category: dragged.categoryID != nil ? categories[dragged.categoryID!] : nil
                )
                .opacity(0.8)
                .scaleEffect(1.02)
            }
            
            // Current time indicator
            if Calendar.current.isDateInToday(date) {
                currentTimeIndicator
            }
            
            // Center info
            centerInfo
        }
        .frame(width: size, height: size)
        .gesture(
            DragGesture()
                .onChanged { value in
                    handleDrag(value)
                }
                .onEnded { _ in
                    completeDrag()
                }
        )
        .onAppear {
            loadData()
            startTimer()
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
    
    // MARK: - Current Time Indicator
    
    private var currentTimeIndicator: some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let angle = RadialLayoutEngine.angle(fromHour: hour, minute: minute)
        let angleRadians = (angle - 90) * .pi / 180
        
        let startRadius: CGFloat = innerRadius - 10
        let endRadius: CGFloat = outerRadius + 10
        
        return ZStack {
            // Line
            Path { path in
                let startX = startRadius * cos(angleRadians)
                let startY = startRadius * sin(angleRadians)
                let endX = endRadius * cos(angleRadians)
                let endY = endRadius * sin(angleRadians)
                
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))
            }
            .stroke(themeManager.accent, lineWidth: 2)
            
            // Dot at end
            Circle()
                .fill(themeManager.accent)
                .frame(width: 8, height: 8)
                .offset(
                    x: endRadius * cos(angleRadians),
                    y: endRadius * sin(angleRadians)
                )
        }
    }
    
    // MARK: - Center Info
    
    private var centerInfo: some View {
        VStack(spacing: 8) {
            Text(date, format: .dateTime.weekday(.abbreviated))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(themeManager.textSecondaryColor)
                        .textCase(.uppercase)
            
            Text("\(totalScheduledHours)h \(totalScheduledMinutes % 60)m scheduled")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.textTertiaryColor)
            
            // Category summary
            VStack(spacing: 4) {
                ForEach(categorySummary.prefix(4), id: \.0.id) { category, minutes in
                    HStack(spacing: 8) {
                        Text(category.name.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(categoryColorFor(category))

                        Text(formatMinutes(minutes))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                }
            }
            .padding(.top, 4)
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Category Summary
    
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
    
    private func categoryColorFor(_ category: Category) -> Color {
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
    
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h\(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalScheduledMinutes: Int {
        timeBlocks.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var totalScheduledHours: Int {
        totalScheduledMinutes / 60
    }
    
    // MARK: - Drag Handling
    
    private func handleDrag(_ value: DragGesture.Value) {
        guard var dragged = draggedBlock else { return }
        
        let center = CGPoint(x: size / 2, y: size / 2)
        let location = value.location
        let dx = location.x - center.x
        let dy = location.y - center.y
        
        var angle = atan2(dy, dx) * 180 / .pi
        angle = angle + 90
        if angle < 0 { angle += 360 }
        
        let preferences = UserPreferences.load()
        let snappedAngle = RadialLayoutEngine.snapAngle(angle, toMinutes: preferences.snapInterval)
        
        let (hour, minute) = RadialLayoutEngine.timeComponents(from: snappedAngle)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        
        if let newStart = calendar.date(from: components) {
            let duration = dragged.duration
            let newEnd = newStart.addingTimeInterval(duration)
            
            dragged.startDate = newStart
            dragged.endDate = newEnd
            
            draggedBlock = dragged
            detectConflicts()
        }
    }
    
    private func completeDrag() {
        guard let dragged = draggedBlock else { return }
        
        if let updated = storeContainer.planStore.updateBlock(dragged) {
            if let index = timeBlocks.firstIndex(where: { $0.id == updated.id }) {
                timeBlocks[index] = updated
            }
        }
        
        draggedBlock = nil
        detectConflicts()
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    // MARK: - Conflict Detection
    
    private func detectConflicts() {
        var newConflicts: Set<UUID> = []
        
        for i in 0..<timeBlocks.count {
            for j in (i+1)..<timeBlocks.count {
                let block1 = timeBlocks[i]
                let block2 = timeBlocks[j]
                
                if block1.overlaps(with: block2) {
                    newConflicts.insert(block1.id)
                    newConflicts.insert(block2.id)
                }
            }
        }
        
        conflicts = newConflicts
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        timeBlocks = storeContainer.planStore.fetchBlocksFor(date: date)
        
        let allCategories = storeContainer.categoryStore.fetchAll()
        categories = Dictionary(uniqueKeysWithValues: allCategories.map { ($0.id, $0) })
        
        detectConflicts()
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    // MARK: - Block Actions
    
    private func updateBlock(_ block: TimeBlock) {
        if let updated = storeContainer.planStore.updateBlock(block) {
            if let index = timeBlocks.firstIndex(where: { $0.id == updated.id }) {
                timeBlocks[index] = updated
            }
            detectConflicts()
        }
    }
    
    private func deleteBlock(_ block: TimeBlock) {
        if storeContainer.planStore.deleteBlock(block.id) {
            timeBlocks.removeAll { $0.id == block.id }
            detectConflicts()
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        InteractiveRadialView(date: Date(), size: 360)
    }
    .environmentObject(ThemeManager())
    .environmentObject({
        let container = ModelContainer.createPreview()
        return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
    }())
}
