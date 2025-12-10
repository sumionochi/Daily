// Features/Radial/Views/DaySwipeGesture.swift

import SwiftUI

struct DaySwipeGesture: ViewModifier {
    @ObservedObject var viewModel: RadialViewModel
    
    @State private var isDragging = false
    
    /// How far (in points) the finger must travel horizontally
    /// before we commit to changing the day.
    private let swipeThreshold: CGFloat = 80
    
    func body(content: Content) -> some View {
        content
            // 👇 No .offset here anymore – inner circle stays fixed.
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        // Only allow swipe when unfocused
                        guard !viewModel.state.isFocused else { return }
                        
                        if !isDragging {
                            isDragging = true
                            viewModel.setInteractionMode(.swipingDay)
                        }
                        // We no longer visually move anything while dragging;
                        // we just wait to see if the swipe passes the threshold.
                    }
                    .onEnded { value in
                        isDragging = false
                        viewModel.setInteractionMode(.idle)
                        
                        // Still block swipes while focused
                        guard !viewModel.state.isFocused else { return }
                        
                        let distance = value.translation.width
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if distance > swipeThreshold {
                                // Swipe right → previous day
                                viewModel.goToPreviousDay()
                            } else if distance < -swipeThreshold {
                                // Swipe left → next day
                                viewModel.goToNextDay()
                            }
                            // No offset reset needed anymore.
                        }
                    }
            )
    }
}

extension View {
    func daySwipeGesture(viewModel: RadialViewModel) -> some View {
        modifier(DaySwipeGesture(viewModel: viewModel))
    }
}
