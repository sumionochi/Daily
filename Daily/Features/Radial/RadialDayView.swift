//
//  RadialDayView.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Features/Radial/RadialDayView.swift

import SwiftUI
import SwiftData

struct RadialDayView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    let date: Date
    let size: CGFloat
    
    @State private var timeBlocks: [TimeBlock] = []
    @State private var categories: [UUID: Category] = [:]
    @State private var currentTime = Date()
    
    // Radial dimensions
    private let innerRadius: CGFloat
    private let outerRadius: CGFloat
    private let ringThickness: CGFloat = 50
    
    init(date: Date, size: CGFloat = 300) {
        self.date = date
        self.size = size
        self.outerRadius = size / 2 - 20
        self.innerRadius = outerRadius - ringThickness
    }
    
    var body: some View {
        ZStack {
            // Clock face with hour markers
            RadialClockFace(radius: outerRadius)
            
            // Time blocks
            ForEach(timeBlocks) { block in
                RadialBlockView(
                    block: block,
                    innerRadius: innerRadius,
                    outerRadius: outerRadius,
                    category: block.categoryID != nil ? categories[block.categoryID!] : nil
                )
            }
            
            // Current time indicator (only for today)
            if Calendar.current.isDateInToday(date) {
                RadialCurrentTimeIndicator(
                    currentTime: currentTime,
                    innerRadius: innerRadius,
                    outerRadius: outerRadius
                )
            }
            
            // Center info
            centerInfo
        }
        .frame(width: size, height: size)
        .onAppear {
            loadData()
            startTimer()
        }
        .onChange(of: date) { _, _ in
            loadData()
        }
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
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        timeBlocks = storeContainer.planStore.fetchBlocksFor(date: date)
        
        // Load categories
        let allCategories = storeContainer.categoryStore.fetchAll()
        categories = Dictionary(uniqueKeysWithValues: allCategories.map { ($0.id, $0) })
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            currentTime = Date()
        }
    }
}

#Preview {
    ZStack {
        AppBackgroundView()
        
        VStack(spacing: 30) {
            Text("Today")
                .font(.title)
            
            RadialDayView(date: Date(), size: 300)
        }
    }
    .environmentObject(ThemeManager())
    .environmentObject({
        let container = ModelContainer.createPreview()
        return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
    }())
}
