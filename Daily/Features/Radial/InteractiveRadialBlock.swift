// Features/Radial/Views/InteractiveRadialBlock.swift

import SwiftUI
import SwiftData

struct InteractiveRadialBlock: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: RadialViewModel

    let block: TimeBlock
    let category: Category?
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    @State private var dragMode: DragMode = .none
    @State private var lastSnapAngle: Double?

    private enum DragMode {
        case none
        case dragging
        case resizingStart
        case resizingEnd
    }

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2,
                                 y: proxy.size.height / 2)

            ZStack {
                // Base visual arc
                RadialBlockView(
                    block: block,
                    innerRadius: innerRadius,
                    outerRadius: outerRadius,
                    category: category
                )
                .scaleEffect(viewModel.isBlockFocused(block.id) ? 1.03 : 1.0)
                .shadow(
                    color: viewModel.isBlockFocused(block.id)
                        ? themeManager.accent.opacity(0.35)
                        : .clear,
                    radius: 8
                )

                // Resize handles (visual only)
                ResizeHandlesOverlay(
                    block: block,
                    innerRadius: innerRadius,
                    outerRadius: outerRadius,
                    isInteracting: isInteractingForCurrentBlock
                )

                // Drag / resize feedback (time chip, glow, etc)
                BlockInteractionFeedback(
                    viewModel: viewModel,
                    block: block,
                    innerRadius: innerRadius,
                    outerRadius: outerRadius
                )
                .allowsHitTesting(false)
            }
            // Hit area = the ring around the block
            .contentShape(
                RingHitShape(
                    innerRadius: innerRadius - 20,
                    outerRadius: outerRadius + 20
                )
            )
            // Tap: focus / unfocus
            .highPriorityGesture(
                TapGesture()
                    .onEnded {
                        viewModel.toggleFocus(for: block.id)
                    }
            )
            // Long press: focus + open edit sheet
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        viewModel.beginEditingBlock(blockID: block.id)
                    }
            )
            // Drag: decide once → drag vs resize
            .gesture(
                DragGesture(minimumDistance: 3)
                    .onChanged { value in
                        handleDragChanged(value, center: center)
                    }
                    .onEnded { _ in
                        handleDragEnded()
                    }
            )
        }
    }

    // MARK: - Interaction state

    private var isInteractingForCurrentBlock: Bool {
        switch viewModel.interactionMode {
        case .draggingBlock(let id, _):       return id == block.id
        case .resizingBlockStart(let id):     return id == block.id
        case .resizingBlockEnd(let id):       return id == block.id
        default:                              return false
        }
    }

    // MARK: - Drag handling

    private func handleDragChanged(_ value: DragGesture.Value, center: CGPoint) {
        // Decide drag mode on first move
        if dragMode == .none {
            let distance = RadialGeometry.distanceToCenter(value.startLocation,
                                                           center: center)

            // Only react if drag started inside the ring
            guard distance >= innerRadius - 20,
                  distance <= outerRadius + 20 else {
                return
            }

            let angleAtStart = RadialGeometry.pointToAngle(value.startLocation,
                                                           center: center)
            let startDiff = angleDifference(angleAtStart, block.startAngle)
            let endDiff   = angleDifference(angleAtStart, block.endAngle)
            let edgeThreshold: Double = 8

            if min(startDiff, endDiff) < edgeThreshold {
                // Resize mode
                if startDiff < endDiff {
                    dragMode = .resizingStart
                    viewModel.setInteractionMode(.resizingBlockStart(blockID: block.id))
                } else {
                    dragMode = .resizingEnd
                    viewModel.setInteractionMode(.resizingBlockEnd(blockID: block.id))
                }
            } else {
                // Drag entire block
                dragMode = .dragging
                viewModel.setInteractionMode(
                    .draggingBlock(blockID: block.id,
                                   originalStartTime: block.startDate)
                )
            }

            HapticManager.shared.prepare()
            viewModel.focusBlock(block.id)
        }

        let angle = RadialGeometry.pointToAngle(value.location, center: center)

        switch dragMode {
        case .dragging:
            viewModel.moveBlock(block.id, toAngle: angle)
        case .resizingStart:
            viewModel.resizeBlock(block.id, newStartAngle: angle, newEndAngle: nil)
        case .resizingEnd:
            viewModel.resizeBlock(block.id, newStartAngle: nil, newEndAngle: angle)
        case .none:
            break
        }

        triggerSnapHaptic(for: angle)
    }

    private func handleDragEnded() {
        if dragMode != .none {
            viewModel.saveBlockChanges(block.id)
            viewModel.setInteractionMode(.idle)
            HapticManager.shared.trigger(.blockEdit)
        }
        dragMode = .none
        lastSnapAngle = nil
    }

    // MARK: - Snap haptics

    private func triggerSnapHaptic(for angle: Double) {
        let snappedTime = snapAngleToInterval(angle)
        let snappedAngle = RadialGeometry.timeToAngle(snappedTime)

        if let last = lastSnapAngle {
            if abs(snappedAngle - last) > 0.1 {
                HapticManager.shared.dialTick()
                lastSnapAngle = snappedAngle
            }
        } else {
            lastSnapAngle = snappedAngle
        }
    }

    private func snapAngleToInterval(_ angle: Double) -> Date {
        let time = RadialGeometry.angleToTime(angle, on: block.startDate)
        return snapToInterval(time)
    }

    private func snapToInterval(_ time: Date) -> Date {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: time)

        guard let hour = comps.hour, let minute = comps.minute else {
            return time
        }

        let intervalMinutes = viewModel.timeSnapInterval.rawValue
        let snappedMinute = (minute / intervalMinutes) * intervalMinutes

        var snappedComps = comps
        snappedComps.hour = hour
        snappedComps.minute = snappedMinute
        snappedComps.second = 0

        return calendar.date(from: snappedComps) ?? time
    }

    private func angleDifference(_ a: Double, _ b: Double) -> Double {
        let diff = abs(a - b)
        return min(diff, 360 - diff)
    }
}

// MARK: - Hit area for ring

struct RingHitShape: Shape {
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.addArc(center: center,
                    radius: outerRadius,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360),
                    clockwise: false)

        path.addArc(center: center,
                    radius: innerRadius,
                    startAngle: .degrees(360),
                    endAngle: .degrees(0),
                    clockwise: true)

        path.closeSubpath()
        return path
    }
}
