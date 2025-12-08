//
//  InnerPlace.swift
//  Daily
//
//  Created by Aaditya Srivastava on 08/12/25.
//


// Features/Radial/Views/InnerPlace.swift

import SwiftUI
import SwiftData

struct InnerPlace: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: RadialViewModel
    
    let innerRadius: CGFloat
    
    var body: some View {
        ZStack {
            // State-aware content
            Group {
                switch viewModel.state {
                case .unfocused:
                    InnerPlaceUnfocused(
                        viewModel: viewModel,
                        innerRadius: innerRadius
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    
                case .focused(let blockID):
                    if let block = viewModel.getBlock(by: blockID) {
                        InnerPlaceFocused(
                            block: block,
                            viewModel: viewModel,
                            innerRadius: innerRadius
                        )
                        .transition(.opacity.combined(with: .scale(scale: 1.05)))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.state)
        }
        .daySwipeGesture(viewModel: viewModel)
        .onTapGesture {
            // Tap inner place when focused → unfocus
            if viewModel.state.isFocused {
                viewModel.unfocus()
            }
        }
    }
}

// MARK: - Focused State (Placeholder for Chunk 3)

struct InnerPlaceFocused: View {
    let block: TimeBlock
    @ObservedObject var viewModel: RadialViewModel
    let innerRadius: CGFloat
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(themeManager.backgroundColor.opacity(0.95))
                .frame(width: innerRadius * 2, height: innerRadius * 2)
            
            VStack(spacing: 12) {
                // Placeholder for Chunk 3
                // This will be fully implemented in next chunk
                
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                
                Spacer()
                
                // Emoji (large)
                if let emoji = block.emoji {
                    Text(emoji)
                        .font(.system(size: 48))
                }
                
                // Title
                Text(block.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(themeManager.textPrimaryColor)
                    .multilineTextAlignment(.center)
                
                // Time range
                Text(timeRangeFormatted)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.textSecondaryColor)
                
                Spacer()
                
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue.opacity(0.8))
            }
            .padding(.vertical, 16)
            .frame(width: innerRadius * 2, height: innerRadius * 2)
        }
    }
    
    private var timeRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let start = formatter.string(from: block.startDate)
        let end = formatter.string(from: block.endDate)
        return "\(start) – \(end)"
    }
}

#Preview {
    let container = ModelContainer.createPreview()
    let storeContainer = StoreContainer(modelContext: container.mainContext, shouldSeed: true)
    let viewModel = RadialViewModel(date: Date(), storeContainer: storeContainer)
    
    return ZStack {
        Color.black
        InnerPlace(viewModel: viewModel, innerRadius: 110)
            .environmentObject(ThemeManager())
    }
}
