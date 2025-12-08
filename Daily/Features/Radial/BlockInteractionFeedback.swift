// Features/Radial/Views/BlockInteractionFeedback.swift

import SwiftUI
import SwiftData
struct BlockInteractionFeedback: View {
    @ObservedObject var viewModel: RadialViewModel
    let block: TimeBlock
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    
    var body: some View {
        Group {
            switch viewModel.interactionMode {
            case .draggingBlock(let blockID, _):
                if blockID == block.id {
                    draggingFeedback
                }
                
            case .resizingBlockStart(let blockID):
                if blockID == block.id {
                    resizeHandleFeedback(edge: .start)
                }
                
            case .resizingBlockEnd(let blockID):
                if blockID == block.id {
                    resizeHandleFeedback(edge: .end)
                }
                
            default:
                EmptyView()
            }
        }
    }
    
    // MARK: - Dragging Feedback
    
    private var draggingFeedback: some View {
        ZStack {
            // Pulsing glow
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: (innerRadius + outerRadius) / 2, height: (innerRadius + outerRadius) / 2)
                .scaleEffect(1.1)
                .opacity(0.6)
            
            // Time display at center
            if let snappedTime = getSnappedTime() {
                timeLabel(snappedTime)
            }
        }
    }
    
    // MARK: - Resize Handle Feedback
    
    private func resizeHandleFeedback(edge: ResizeEdge) -> some View {
        let angle = edge == .start ? block.startAngle : block.endAngle
        let angleRadians = (angle - 90) * .pi / 180
        
        let handleRadius = (innerRadius + outerRadius) / 2
        let x = handleRadius * cos(angleRadians)
        let y = handleRadius * sin(angleRadians)
        
        return ZStack {
            // Handle indicator
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
                .shadow(color: .blue, radius: 8)
            
            Circle()
                .stroke(Color.blue, lineWidth: 2)
                .frame(width: 20, height: 20)
        }
        .offset(x: x, y: y)
    }
    
    // MARK: - Time Label
    
    private func timeLabel(_ time: Date) -> some View {
        Text(time, format: .dateTime.hour().minute())
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
    
    // MARK: - Helpers
    
    private func getSnappedTime() -> Date? {
        return block.startDate
    }
}

enum ResizeEdge {
    case start
    case end
}

// MARK: - Resize Handles Overlay

struct ResizeHandlesOverlay: View {
    let block: TimeBlock
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let isInteracting: Bool
    
    var body: some View {
        if isInteracting {
            ZStack {
                // Start handle
                handleIndicator(at: block.startAngle, color: .green)
                
                // End handle
                handleIndicator(at: block.endAngle, color: .red)
            }
        }
    }
    
    private func handleIndicator(at angle: Double, color: Color) -> some View {
        let angleRadians = (angle - 90) * .pi / 180
        let handleRadius = (innerRadius + outerRadius) / 2
        let x = handleRadius * cos(angleRadians)
        let y = handleRadius * sin(angleRadians)
        
        return Circle()
            .fill(color.opacity(0.8))
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 1)
            )
            .offset(x: x, y: y)
    }
}

#Preview {
    let container = ModelContainer.createPreview()
    let storeContainer = StoreContainer(modelContext: container.mainContext, shouldSeed: true)
    let viewModel = RadialViewModel(date: Date(), storeContainer: storeContainer)
    
    let block = TimeBlock(
        title: "Deep Work",
        emoji: "🎯",
        startDate: Date(),
        endDate: Date().addingTimeInterval(7200),
        categoryID: nil
    )
    
    return ZStack {
        Color.black
        
        BlockInteractionFeedback(
            viewModel: viewModel,
            block: block,
            innerRadius: 140,
            outerRadius: 180
        )
    }
}
