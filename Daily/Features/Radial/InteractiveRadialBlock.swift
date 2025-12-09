// Features/Radial/Views/InteractiveRadialBlock.swift

import SwiftUI
import SwiftData

struct InteractiveRadialBlock: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: RadialViewModel

    let block: TimeBlock
    let category: Category?
    let innerRadius: CGFloat      // inner edge of the block ring
    let outerRadius: CGFloat      // outer radius of the whole radial (ticks)

    // Local preview state
    @State private var previewBlock: TimeBlock? = nil
    @State private var dragMode: DragMode = .none
    @State private var lastSnapAngle: Double?
    @State private var originalDuration: TimeInterval = 0
    @State private var dragAngleOffset: Double = 0

    // Drag visuals
    @State private var dragSwellProgress: CGFloat = 0      // 0 → 1 swell amount during long press
    @State private var dragArmed: Bool = false             // true after 1s press, enables drag

    // Tracks the gesture state specifically for the swell animation logic
    @GestureState private var isPressingForDrag = false

    // Geometry constants
    private let blockThickness: CGFloat = 32
    private let secondsInDay: TimeInterval = 24 * 60 * 60

    private enum DragMode {
        case none
        case dragging
        case resizingStart
        case resizingEnd
    }

    // Convenience: block we actually draw
    private var activeBlock: TimeBlock {
        previewBlock ?? block
    }

    // Convenience: is THIS block currently focused?
    private var isFocused: Bool {
        viewModel.isBlockFocused(block.id)
    }

    // Final scale used for the block (focus + swell)
    private var blockScale: CGFloat {
        let base: CGFloat = isFocused ? 1.03 : 1.0
        // Swell adds up to 8% scale when fully pressed
        let extra: CGFloat = 0.08 * dragSwellProgress
        return base + extra
    }

    var body: some View {
        GeometryReader { proxy in
            let center    = CGPoint(x: proxy.size.width / 2,
                                    y: proxy.size.height / 2)
            let arcInner  = innerRadius
            let arcOuter  = innerRadius + blockThickness

            // 1. Long-press (1s) then drag logic (only meaningful when focused)
            let longPressThenDrag = LongPressGesture(minimumDuration: 1.0)
                .sequenced(before: DragGesture(minimumDistance: 0))
                .updating($isPressingForDrag) { value, state, _ in
                    switch value {
                    case .first(true):
                        // User is holding down
                        state = true
                    case .second(true, _):
                        // Long press finished, now dragging
                        state = true
                    default:
                        state = false
                    }
                }
                .onChanged { value in
                    guard isFocused else { return }

                    switch value {
                    case .first(true):
                        // Still pressing, waiting for 1s threshold...
                        break

                    case .second(true, let drag?):
                        // 1s threshold passed. We are now officially dragging.
                        if !dragArmed {
                            dragArmed = true
                            HapticManager.shared.selection()
                        }
                        handleLongPressDragChanged(
                            drag,
                            center: center,
                            arcInner: arcInner,
                            arcOuter: arcOuter
                        )
                    default:
                        break
                    }
                }
                .onEnded { _ in
                    guard isFocused else { return }
                    commitPreviewBlockAndReset()
                }

            // 2. Shorter long-press just to open edit when NOT focused
            let editLongPress = LongPressGesture(minimumDuration: 0.6)
                .onEnded { _ in
                    if !isFocused {
                        viewModel.focusBlock(block.id)
                        viewModel.beginEditingBlock(blockID: block.id)
                    }
                }

            ZStack {
                // --- Layer 1: Base Block ---
                RadialBlockView(
                    block: activeBlock,
                    innerRadius: arcInner,
                    outerRadius: arcOuter,
                    category: category
                )
                .scaleEffect(blockScale)
                .shadow(
                    color: dragArmed
                        ? themeManager.accent.opacity(0.6)
                        : (isFocused ? themeManager.accent.opacity(0.3) : .clear),
                    radius: dragArmed ? 15 : (isFocused ? 8 : 0)
                )

                // --- Layer 2: Energy Flow Overlay (Only when Armed) ---
                if dragArmed {
                    EnergyFlowArcOverlay(
                        startAngle: activeBlock.startAngle,
                        endAngle: activeBlock.endAngle,
                        innerRadius: arcInner,
                        outerRadius: arcOuter,
                        color: themeManager.accent,
                        isActive: dragArmed
                    )
                    .scaleEffect(blockScale)
                    .allowsHitTesting(false)
                }

                // --- Layer 3: Resize Handles (Visual Only) ---
                ResizeHandlesOverlay(
                    block: activeBlock,
                    innerRadius: arcInner,
                    outerRadius: arcOuter,
                    isInteracting: isInteractingForCurrentBlock
                )

                // --- Layer 4: Feedback Text ---
                BlockInteractionFeedback(
                    viewModel: viewModel,
                    block: activeBlock,
                    innerRadius: arcInner,
                    outerRadius: arcOuter
                )
                .allowsHitTesting(false)
            }
            // 🔑 Hit area = this block’s arc only
            .contentShape(
                ArcHitShape(
                    startAngle: activeBlock.startAngle,
                    endAngle: activeBlock.endAngle,
                    innerRadius: arcInner - 6,
                    outerRadius: arcOuter + 6
                )
            )
            // Double-tap: cycle overlapping
            .highPriorityGesture(
                TapGesture(count: 2)
                    .onEnded {
                        viewModel.focusNextOverlappingBlock(from: block.id)
                    }
            )
            // Long Press + Drag (focused only)
            .highPriorityGesture(longPressThenDrag)
            // Long press on NOT-focused block → open edit
            .simultaneousGesture(editLongPress)
            // Single Tap: Toggle Focus
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        viewModel.toggleFocus(for: block.id)
                    }
            )
            // Short Drag (Resize)
            .gesture(
                DragGesture(minimumDistance: 3)
                    .onChanged { value in
                        handleResizeDragChanged(
                            value,
                            center: center,
                            arcInner: arcInner,
                            arcOuter: arcOuter
                        )
                    }
                    .onEnded { _ in
                        handleDragEnded()
                    }
            )
            // 🔁 Animation Logic for Swell
            .onChange(of: isPressingForDrag) { _, isPressing in
                if isPressing && isFocused {
                    // Start Swell with a slight delay so quick resize drags don't trigger it
                    withAnimation(.easeInOut(duration: 0.85).delay(0.15)) {
                        dragSwellProgress = 1.0
                    }
                } else {
                    // User let go or gesture failed/ended
                    if !dragArmed {
                        // Deflate quickly if we never reached armed state
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragSwellProgress = 0
                        }
                    }
                }
            }
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

    // MARK: - Long-press drag (move whole block)

    private func handleLongPressDragChanged(
        _ drag: DragGesture.Value,
        center: CGPoint,
        arcInner: CGFloat,
        arcOuter: CGFloat
    ) {
        guard isFocused else { return }

        // First time initialization
        if dragMode == .none {
            previewBlock     = block
            originalDuration = normalizedDuration(from: block.startDate,
                                                  to: block.endDate)
            dragMode = .dragging

            // Calculate offset so the block doesn't jump to finger center
            let pressAngle     = normalizeAngle(
                RadialGeometry.pointToAngle(drag.startLocation, center: center)
            )
            let startAngleNorm = normalizeAngle(block.startAngle)
            dragAngleOffset    = normalizeAngle(pressAngle - startAngleNorm)

            viewModel.setInteractionMode(
                .draggingBlock(blockID: block.id,
                               originalStartTime: block.startDate)
            )
            HapticManager.shared.prepare()
        }

        guard var current = previewBlock else { return }

        let angle = RadialGeometry.pointToAngle(drag.location, center: center)
        current   = movedPreview(current, toAngle: angle)
        previewBlock = current

        triggerSnapHaptic(for: angle)
    }

    // MARK: - Resize drag (short drag without long-press)

    private func handleResizeDragChanged(
        _ value: DragGesture.Value,
        center: CGPoint,
        arcInner: CGFloat,
        arcOuter: CGFloat
    ) {
        // If we are pressing for a long-drag, ignore resize logic
        guard !isPressingForDrag else { return }

        // Only focused block resizes
        guard isFocused else { return }

        if dragMode == .none {
            let distance = RadialGeometry.distanceToCenter(value.startLocation,
                                                           center: center)
            guard distance >= arcInner - 20,
                  distance <= arcOuter + 20 else {
                return
            }

            previewBlock     = block
            originalDuration = normalizedDuration(from: block.startDate,
                                                  to: block.endDate)

            let angleAtStart = RadialGeometry.pointToAngle(value.startLocation,
                                                           center: center)

            // Split into halves: firstHalf = resize start, secondHalf = resize end
            let half = halfForAngle(
                angleAtStart,
                startAngle: block.startAngle,
                endAngle: block.endAngle
            )

            switch half {
            case .firstHalf:
                dragMode = .resizingStart
                viewModel.setInteractionMode(.resizingBlockStart(blockID: block.id))
            case .secondHalf:
                dragMode = .resizingEnd
                viewModel.setInteractionMode(.resizingBlockEnd(blockID: block.id))
            }

            HapticManager.shared.prepare()
        }

        guard var current = previewBlock else { return }

        let angle = RadialGeometry.pointToAngle(value.location, center: center)

        switch dragMode {
        case .dragging:
            current = movedPreview(current, toAngle: angle)
        case .resizingStart:
            current = resizedPreview(current, newStartAngle: angle, newEndAngle: nil)
        case .resizingEnd:
            current = resizedPreview(current, newStartAngle: nil, newEndAngle: angle)
        case .none:
            return
        }

        previewBlock = current
        triggerSnapHaptic(for: angle)
    }

    private func handleDragEnded() {
        commitPreviewBlockAndReset()
    }

    // MARK: - Commit + reset

    private func commitPreviewBlockAndReset() {
        defer {
            // Reset visuals with animation
            withAnimation(.easeOut(duration: 0.3)) {
                dragSwellProgress = 0
                dragArmed         = false
            }
            // Reset logic
            dragMode         = .none
            lastSnapAngle    = nil
            previewBlock     = nil
            dragAngleOffset  = 0
            viewModel.setInteractionMode(.idle)
        }

        guard let finalBlock = previewBlock else { return }

        viewModel.commitBlock(finalBlock)
        HapticManager.shared.trigger(.blockEdit)
    }

    // MARK: - Block half classification

    private enum BlockHalf {
        case firstHalf
        case secondHalf
    }

    private func halfForAngle(
        _ angle: Double,
        startAngle: Double,
        endAngle: Double
    ) -> BlockHalf {
        let start = startAngle
        var end   = endAngle

        if end <= start { end += 360 }

        var pos = angle
        if pos < start { pos += 360 }

        let mid = (start + end) / 2

        return pos <= mid ? .firstHalf : .secondHalf
    }

    // MARK: - Preview block math

    private func movedPreview(_ block: TimeBlock, toAngle angle: Double) -> TimeBlock {
        var updated = block
        let normalizedAngle = normalizeAngle(angle)
        let adjustedAngle   = normalizeAngle(normalizedAngle - dragAngleOffset)

        let newStartTime = angleToTime(adjustedAngle, for: viewModel.currentDate)
        let snappedStart = snapToInterval(newStartTime)

        let duration = originalDuration
        updated.startDate = snappedStart
        updated.endDate   = snappedStart.addingTimeInterval(duration)

        return updated
    }

    private func resizedPreview(
        _ block: TimeBlock,
        newStartAngle: Double?,
        newEndAngle: Double?
    ) -> TimeBlock {
        var updated = block

        if let startAngle = newStartAngle {
            let newStart     = angleToTime(startAngle, for: viewModel.currentDate)
            let snappedStart = snapToInterval(newStart)
            updated.startDate = snappedStart
        }

        if let endAngle = newEndAngle {
            let endTOD     = angleToTime(endAngle, for: viewModel.currentDate)
            let snappedTOD = snapToInterval(endTOD)

            let calendar   = Calendar.current
            let sameDayEnd = snappedTOD
            let nextDayEnd = calendar.date(byAdding: .day, value: 1, to: sameDayEnd)!

            let diffSame = abs(sameDayEnd.timeIntervalSince(updated.endDate))
            let diffNext = abs(nextDayEnd.timeIntervalSince(updated.endDate))

            let chosenEnd = (diffSame <= diffNext) ? sameDayEnd : nextDayEnd
            updated.endDate = chosenEnd
        }

        let minDuration = viewModel.timeSnapInterval.seconds
        var duration = normalizedDuration(from: updated.startDate,
                                          to: updated.endDate)

        if duration < minDuration {
            if newStartAngle != nil && newEndAngle == nil {
                updated.startDate = updated.endDate.addingTimeInterval(-minDuration)
            } else {
                updated.endDate = updated.startDate.addingTimeInterval(minDuration)
            }
            duration = minDuration
        }

        if duration > secondsInDay {
            updated.endDate = updated.startDate.addingTimeInterval(secondsInDay)
        }

        return updated
    }

    // MARK: - Snap haptics

    private func triggerSnapHaptic(for angle: Double) {
        let snappedTime  = snapAngleToInterval(angle)
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

    // MARK: - Helpers

    private func angleToTime(_ angle: Double, for date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)

        let normalizedAngle = angle.truncatingRemainder(dividingBy: 360)
        let positiveAngle   = normalizedAngle < 0 ? normalizedAngle + 360 : normalizedAngle

        let hours       = (positiveAngle / 360.0) * 24.0
        let hoursPart   = Int(hours)
        let minutesPart = Int((hours - Double(hoursPart)) * 60)

        components.hour   = hoursPart
        components.minute = minutesPart
        components.second = 0

        return calendar.date(from: components) ?? date
    }

    private func snapToInterval(_ time: Date) -> Date {
        let calendar   = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute],
                                                 from: time)

        guard let year   = components.year,
              let month  = components.month,
              let day    = components.day,
              let hour   = components.hour,
              let minute = components.minute else {
            return time
        }

        let intervalMinutes = viewModel.timeSnapInterval.rawValue
        let snappedMinute   = (minute / intervalMinutes) * intervalMinutes

        var snappedComponents = DateComponents()
        snappedComponents.year   = year
        snappedComponents.month  = month
        snappedComponents.day    = day
        snappedComponents.hour   = hour
        snappedComponents.minute = snappedMinute
        snappedComponents.second = 0

        return calendar.date(from: snappedComponents) ?? time
    }

    private func normalizedDuration(from start: Date, to end: Date) -> TimeInterval {
        let raw = end.timeIntervalSince(start)
        return raw >= 0 ? raw : raw + secondsInDay
    }

    private func normalizeAngle(_ a: Double) -> Double {
        var angle = a.truncatingRemainder(dividingBy: 360)
        if angle < 0 { angle += 360 }
        return angle
    }
}

// MARK: - Arc hit shape

struct ArcHitShape: Shape {
    let startAngle: Double
    let endAngle: Double
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path   = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        let start = RadialLayoutEngine.swiftUIAngle(startAngle)
        let end   = RadialLayoutEngine.swiftUIAngle(endAngle)

        // Outer arc
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: start,
            endAngle: end,
            clockwise: false
        )

        // Inner arc back
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: end,
            endAngle: start,
            clockwise: true
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Energy Flow Overlay that fills the whole pill

struct EnergyFlowArcOverlay: View {
    let startAngle: Double   // 0° at top, clockwise
    let endAngle: Double
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let color: Color
    let isActive: Bool

    @State private var phase: Double = 0.0

    var body: some View {
        GeometryReader { _ in
            // Match the pill exactly: use the centre radius + full thickness
            let radius    = (innerRadius + outerRadius) / 2
            let thickness = max(outerRadius - innerRadius, 0)

            let shape = BubblyArcShape(
                startAngle: startAngle,
                endAngle: endAngle,
                radius: radius,
                lineWidth: thickness
            )

            AngularGradient(
                gradient: Gradient(stops: [
                    // Soft glow across the whole pill, with a bright moving core
                    .init(color: color.opacity(0.20), location: 0.0),
                    .init(color: color.opacity(0.45), location: 0.25),
                    .init(color: color.opacity(0.95), location: 0.50),
                    .init(color: color.opacity(0.45), location: 0.75),
                    .init(color: color.opacity(0.20), location: 1.0)
                ]),
                center: .center,
                angle: .degrees(currentAngle())
            )
            .mask(shape)
            .blendMode(.plusLighter)
            .opacity(0.3)
            .drawingGroup()
        }
        .onAppear {
            if isActive {
                startEnergyAnimation()
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                startEnergyAnimation()
            } else {
                withAnimation(.linear(duration: 0.2)) {
                    phase = 0.0
                }
            }
        }
    }

    private func startEnergyAnimation() {
        phase = 0.0
        withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
            phase = 1.0
        }
    }

    /// Rotate the angular gradient smoothly, so the bright core sweeps
    /// from one end of the block to the other.
    private func currentAngle() -> Double {
        // Just spin around the circle; the pill mask ensures we only
        // see the band across this block.
        return phase * 360.0
    }
}
