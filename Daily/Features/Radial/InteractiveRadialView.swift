//
//  InteractiveRadialView.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


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
    @State private var dragOffset: CGSize = .zero
    @State private var selectedBlock: TimeBlock?
    @State private var showBlockDetail = false
    @State private var conflicts: Set<UUID> = []
    
    // Radial dimensions
    private let innerRadius: CGFloat
    private let outerRadius: CGFloat
    private let ringThickness: CGFloat = 50
    
    init(date: Date, size: CGFloat = 320) {
        self.date = date
        self.size = size
        self.outerRadius = size / 2 - 20
        self.innerRadius = outerRadius - ringThickness
    }
    
    var body: some View {
        ZStack {
            // Clock face
            RadialClockFace(radius: outerRadius)
            
            // Time blocks
            ForEach(timeBlocks) { block in
                if block.id != draggedBlock?.id {
                    blockView(for: block)
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
                blockView(for: dragged)
                    .opacity(0.8)
                    .scaleEffect(1.05)
            }
            
            // Current time indicator
            if Calendar.current.isDateInToday(date) {
                RadialCurrentTimeIndicator(
                    currentTime: currentTime,
                    innerRadius: innerRadius,
                    outerRadius: outerRadius
                )
            }
            
            // Center info
            centerInfo
            
            // Over-scheduled warning
            if isOverScheduled {
                overScheduledWarning
            }
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
    
    // MARK: - Block View
    
    private func blockView(for block: TimeBlock) -> some View {
        let hasConflict = conflicts.contains(block.id)
        
        return RadialBlockView(
            block: block,
            innerRadius: innerRadius,
            outerRadius: outerRadius,
            category: block.categoryID != nil ? categories[block.categoryID!] : nil
        )
        .overlay(
            hasConflict ?
                ArcShape(
                    startAngle: RadialLayoutEngine.swiftUIAngle(block.startAngle),
                    endAngle: RadialLayoutEngine.swiftUIAngle(block.endAngle),
                    innerRadius: innerRadius,
                    outerRadius: outerRadius
                )
                .stroke(Color.red, lineWidth: 3)
                .shadow(color: .red.opacity(0.5), radius: 8)
            : nil
        )
    }
    
    private var centerInfo: some View {
        VStack(spacing: 4) {
            Text(date, format: .dateTime.weekday(.abbreviated))
                .font(themeManager.captionFont)
                .foregroundColor(themeManager.textSecondaryColor)
            
            Text(date, format: .dateTime.day())
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.textPrimaryColor)
            
            Text(date, format: .dateTime.month(.abbreviated))
                .font(themeManager.captionFont)
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .allowsHitTesting(false)
    }
    
    private var overScheduledWarning: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Circle Full")
                    .font(themeManager.captionFont)
            }
            .foregroundColor(.red)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Drag Handling
    
    private func handleDrag(_ value: DragGesture.Value) {
        guard var dragged = draggedBlock else { return }
        
        // Calculate angle from drag location
        let center = CGPoint(x: size / 2, y: size / 2)
        let location = value.location
        let dx = location.x - center.x
        let dy = location.y - center.y
        
        var angle = atan2(dy, dx) * 180 / .pi
        angle = angle + 90 // Adjust for our coordinate system
        if angle < 0 { angle += 360 }
        
        // Snap to interval
        let preferences = UserPreferences.load()
        let snappedAngle = RadialLayoutEngine.snapAngle(angle, toMinutes: preferences.snapInterval)
        
        // Calculate new times
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
        
        // Update block in store
        if let updated = storeContainer.planStore.updateBlock(dragged) {
            if let index = timeBlocks.firstIndex(where: { $0.id == updated.id }) {
                timeBlocks[index] = updated
            }
        }
        
        draggedBlock = nil
        detectConflicts()
        
        // Haptic feedback
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
    
    private var isOverScheduled: Bool {
        let totalMinutes = timeBlocks.reduce(0) { $0 + $1.durationMinutes }
        return totalMinutes > 24 * 60
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
        AppBackgroundView()
        
        InteractiveRadialView(date: Date(), size: 320)
    }
    .environmentObject(ThemeManager())
    .environmentObject({
        let container = ModelContainer.createPreview()
        return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
    }())
}
