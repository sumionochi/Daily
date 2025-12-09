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
    private let blockRingThickness: CGFloat = 40       // same as above
    private let blockGapToDial: CGFloat = 8
    
    init(date: Date, size: CGFloat = 360, storeContainer: StoreContainer) {
        self.size = size
        self.outerRadius = size / 2 - 20
        self.innerRadius = outerRadius - blockGapToDial - blockRingThickness

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
        Group {
            if Calendar.current.isDateInToday(viewModel.currentDate) {
                CurrentTimeIndicatorView(
                    innerRadius: innerRadius,
                    outerRadius: outerRadius
                )
                .allowsHitTesting(false)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func getCategoryForBlock(_ block: TimeBlock) -> Category? {
        guard let categoryID = block.categoryID else { return nil }
        return storeContainer.categoryStore.fetchAll().first { $0.id == categoryID }
    }
}

// MARK: - Current Time Indicator (Watch-style)

struct CurrentTimeIndicatorView: View {
    @EnvironmentObject var themeManager: ThemeManager

    let innerRadius: CGFloat
    let outerRadius: CGFloat

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2,
                                 y: proxy.size.height / 2)

            let angle = RadialGeometry.timeToAngle(currentTime)

            // Needle from inner edge of ring to outer edge
            let needleStart = RadialGeometry.angleToPoint(
                angle,
                radius: innerRadius,
                center: center
            )
            let needleEnd = RadialGeometry.angleToPoint(
                angle,
                radius: outerRadius,
                center: center
            )

            // Time label just inside the ring, slightly offset
            let capsuleRadialOffset: CGFloat = 6

            let labelRadius = outerRadius + capsuleRadialOffset
            let labelPoint = RadialGeometry.angleToPoint(
                angle,
                radius: labelRadius,
                center: center
            )

            ZStack {
                // Glowing needle
                Path { path in
                    path.move(to: needleStart)
                    path.addLine(to: needleEnd)
                }
                .stroke(
                    themeManager.accent,
                    style: StrokeStyle(
                        lineWidth: 3.5,
                        lineCap: .round
                    )
                )
                .shadow(color: themeManager.accent.opacity(0.7), radius: 6)

                // Tip dot
//                Circle()
//                    .fill(themeManager.accent)
//                    .frame(width: 10, height: 10)
//                    .position(needleEnd)
//                    .shadow(color: themeManager.accent.opacity(0.8), radius: 8)

                // Time capsule
                Text(Self.timeFormatter.string(from: currentTime))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(themeManager.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(themeManager.backgroundColor.opacity(0.92))
                    )
                    .overlay(
                        Capsule()
                            .stroke(themeManager.accent.opacity(0.8), lineWidth: 0.6)
                    )
                    .position(labelPoint)
                    .offset(x: -8, y: -16)
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
