// Features/Radial/InteractiveRadialViewiPad.swift

import SwiftUI
import SwiftData

struct InteractiveRadialViewiPad: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer

    @StateObject private var viewModel: RadialViewModel

    let size: CGFloat
    let onBlockTapped: (TimeBlock) -> Void

    // Radial dimensions – slightly thicker ring for iPad
    private let outerRadius: CGFloat
    private let innerRadius: CGFloat
    private let arcThickness: CGFloat = 40

    init(
        date: Date,
        size: CGFloat = 450,
        storeContainer: StoreContainer,
        onBlockTapped: @escaping (TimeBlock) -> Void
    ) {
        self.size = size
        self.onBlockTapped = onBlockTapped

        self.outerRadius = size / 2 - 24
        self.innerRadius = outerRadius - 80   // more room: ticks + inner place

        _viewModel = StateObject(
            wrappedValue: RadialViewModel(
                date: date,
                storeContainer: storeContainer
            )
        )
    }

    var body: some View {
        ZStack {
            // Clock face with ticks
            RadialClockFace(radius: outerRadius)

            // Time blocks
            blocksLayer

            // Inner place (state-aware)
            InnerPlace(
                viewModel: viewModel,
                innerRadius: innerRadius
            )

            // Current time indicator (only for today)
            if Calendar.current.isDateInToday(viewModel.currentDate) {
                CurrentTimeIndicatorView(
                    innerRadius: innerRadius,
                    outerRadius: outerRadius
                )
                .allowsHitTesting(false)
            }
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
        // When editing starts (long-press on a block), propagate to host
        .onChange(of: viewModel.editingBlockID) { _, newID in
            guard let id = newID,
                  let block = viewModel.getBlock(by: id) else { return }
            onBlockTapped(block)
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
                // Slightly larger scale on iPad for visual weight
                .scaleEffect(1.02)
            }
        }
    }

    // MARK: - Helpers

    private func getCategoryForBlock(_ block: TimeBlock) -> Category? {
        guard let categoryID = block.categoryID else { return nil }
        return storeContainer.categoryStore
            .fetchAll()
            .first { $0.id == categoryID }
    }
}

#Preview {
    let container = ModelContainer.createPreview()
    let storeContainer = StoreContainer(
        modelContext: container.mainContext,
        shouldSeed: true
    )

    return ZStack {
        AppBackgroundView()

        InteractiveRadialViewiPad(
            date: Date(),
            size: 450,
            storeContainer: storeContainer,
            onBlockTapped: { _ in }
        )
    }
    .environmentObject(ThemeManager())
    .environmentObject(storeContainer)
}
