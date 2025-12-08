// Features/Radial/InteractiveRadialView.swift

import SwiftUI
import SwiftData
import Combine

struct InteractiveRadialView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    @StateObject private var viewModel: RadialViewModel
    
    let size: CGFloat
    
    // Radial dimensions - refined
    private let outerRadius: CGFloat
    private let innerRadius: CGFloat
    private let arcThickness: CGFloat = 32
    
    init(date: Date, size: CGFloat = 360, storeContainer: StoreContainer) {
        self.size = size
        self.outerRadius = size / 2 - 20
        self.innerRadius = outerRadius - 60 // Space for ticks
        
        _viewModel = StateObject(wrappedValue: RadialViewModel(
            date: date,
            storeContainer: storeContainer
        ))
    }
    
    var body: some View {
        ZStack {
            // Clock face with ticks
            RadialClockFace(radius: outerRadius)
            
            // Time blocks as thin arcs
            blocksLayer
            
            // Inner place (state-aware)
            InnerPlace(
                viewModel: viewModel,
                innerRadius: innerRadius
            )
            
            // Current time indicator
            currentTimeIndicator
        }
        .frame(width: size, height: size)
        .onAppear {
            viewModel.loadBlocks()
            viewModel.calculateStatistics()
        }
        .onChange(of: viewModel.currentDate) { _, _ in
            viewModel.loadBlocks()
            viewModel.calculateStatistics()
        }
    }
    
    // MARK: - Blocks Layer

    private var blocksLayer: some View {
        ZStack {
            ForEach(viewModel.blocks) { block in
                InteractiveRadialBlock(
                    viewModel: viewModel,
                    block: block,
                    category: getCategoryForBlock(block),
                    innerRadius: innerRadius,
                    outerRadius: outerRadius
                )
            }
        }
    }

    
    // MARK: - Current Time Indicator
    
    private var currentTimeIndicator: some View {
        CurrentTimeIndicatorView(
            outerRadius: outerRadius,
            currentDate: viewModel.currentDate
        )
    }
    
    // MARK: - Helpers
    
    private func getCategoryForBlock(_ block: TimeBlock) -> Category? {
        guard let categoryID = block.categoryID else { return nil }
        return storeContainer.categoryStore.fetchAll().first { $0.id == categoryID }
    }
}

// MARK: - Current Time Indicator (Simple)

struct CurrentTimeIndicatorView: View {
    let outerRadius: CGFloat
    let currentDate: Date
    
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2,
                                 y: proxy.size.height / 2)
            let angle = RadialGeometry.timeToAngle(currentTime)
            let point = RadialGeometry.angleToPoint(angle,
                                                    radius: outerRadius,
                                                    center: center)
            
            ZStack {
                Path { path in
                    path.move(to: center)
                    path.addLine(to: point)
                }
                .stroke(Color.green, lineWidth: 2)
                .shadow(color: .green.opacity(0.5), radius: 4)
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .position(x: point.x, y: point.y)
                    .shadow(color: .green.opacity(0.5), radius: 4)
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}


#Preview {
    let container = ModelContainer.createPreview()
    let storeContainer = StoreContainer(modelContext: container.mainContext, shouldSeed: true)
    
    return ZStack {
        Color.black
        InteractiveRadialView(
            date: Date(),
            size: 360,
            storeContainer: storeContainer
        )
        .environmentObject(ThemeManager())
        .environmentObject(storeContainer)
    }
}
