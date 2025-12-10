// Features/Radial/Views/InnerPlace.swift

import SwiftUI
import SwiftData

struct InnerPlace: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: RadialViewModel
    
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    var body: some View {
        ZStack {
            // State-aware content
            Group {
                switch viewModel.state {
                case .unfocused:
                    InnerPlaceUnfocused(
                        viewModel: viewModel,
                        innerRadius: innerRadius,
                        outerRadius: outerRadius
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
                    
                case .focused(let blockID):
                    if let block = viewModel.getBlock(by: blockID) {
                        InnerPlaceFocused(
                            block: block,
                            viewModel: viewModel,
                            innerRadius: innerRadius,
                            outerRadius: outerRadius
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 1.1).combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        ))
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75),
                       value: viewModel.state)
        }
        .daySwipeGesture(viewModel: viewModel)
        .onTapGesture {
            // When focused: tap inner circle → open edit sheet
            switch viewModel.state {
            case .focused(let blockID):
                viewModel.beginEditingBlock(blockID: blockID)
            case .unfocused:
                break
            }
        }
    }
}

#Preview {
    let container = ModelContainer.createPreview()
    let storeContainer = StoreContainer(modelContext: container.mainContext, shouldSeed: true)
    let viewModel = RadialViewModel(date: Date(), storeContainer: storeContainer)
    
    return ZStack {
        Color.black
        InnerPlace(viewModel: viewModel, innerRadius: 110, outerRadius: 180)
            .environmentObject(ThemeManager())
    }
}
