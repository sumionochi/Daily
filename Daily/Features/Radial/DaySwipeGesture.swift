// Features/Radial/Views/DaySwipeGesture.swift

import SwiftUI

struct DaySwipeGesture: ViewModifier {
    @ObservedObject var viewModel: RadialViewModel
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    private let swipeThreshold: CGFloat = 80
    
    func body(content: Content) -> some View {
        content
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        // Only allow swipe when unfocused
                        guard !viewModel.state.isFocused else { return }
                        
                        if !isDragging {
                            isDragging = true
                            viewModel.setInteractionMode(.swipingDay)
                        }
                        
                        // Apply resistance for better feel
                        let resistance: CGFloat = 0.5
                        dragOffset = value.translation.width * resistance
                    }
                    .onEnded { value in
                        isDragging = false
                        viewModel.setInteractionMode(.idle)
                        
                        // Only allow swipe when unfocused
                        guard !viewModel.state.isFocused else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dragOffset = 0
                            }
                            return
                        }
                        
                        let distance = value.translation.width
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if distance > swipeThreshold {
                                // Swipe right → previous day
                                viewModel.goToPreviousDay()
                            } else if distance < -swipeThreshold {
                                // Swipe left → next day
                                viewModel.goToNextDay()
                            }
                            
                            dragOffset = 0
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
