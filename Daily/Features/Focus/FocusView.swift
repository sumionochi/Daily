//
//  FocusView.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Features/Focus/Views/FocusView.swift

import SwiftUI
import SwiftData

struct FocusView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    @Environment(\.dismiss) var dismiss
    
    let block: TimeBlock
    let onComplete: (TimeBlock) -> Void
    
    @State private var timeRemaining: TimeInterval
    @State private var isPaused = false
    @State private var timer: Timer?
    @State private var actualStartTime: Date?
    @State private var category: Category?
    
    init(block: TimeBlock, onComplete: @escaping (TimeBlock) -> Void) {
        self.block = block
        self.onComplete = onComplete
        _timeRemaining = State(initialValue: block.endDate.timeIntervalSince(Date()))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                topBar
                
                Spacer()
                
                // Main content
                mainContent
                
                Spacer()
                
                // Controls
                controlButtons
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            loadData()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .statusBar(hidden: true)
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.textOnAccentColor)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            if let category = category {
                HStack(spacing: 8) {
                    Text(category.emoji)
                        .font(.system(size: 16))
                    Text(category.name)
                        .font(themeManager.captionFont)
                        .foregroundColor(themeManager.textOnAccentColor.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 32) {
            // Emoji
            if let emoji = block.emoji {
                Text(emoji)
                    .font(.system(size: 80))
            }
            
            // Title
            Text(block.title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.textOnAccentColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Timer
            timerDisplay
            
            // Progress ring
            progressRing
        }
    }
    
    private var timerDisplay: some View {
        Text(timeRemainingFormatted)
            .font(.system(size: 72, weight: .light, design: .rounded))
            .foregroundColor(themeManager.textOnAccentColor)
            .monospacedDigit()
    }
    
    private var progressRing: some View {
        let progress = 1.0 - (timeRemaining / block.duration)
        
        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 8)
                .frame(width: 200, height: 200)
            
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    themeManager.accent,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)
        }
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        HStack(spacing: 40) {
            // Skip
            Button {
                skipBlock()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 28))
                    Text("Skip")
                        .font(themeManager.captionFont)
                }
                .foregroundColor(themeManager.textOnAccentColor.opacity(0.6))
            }
            
            // Pause/Resume
            Button {
                togglePause()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 64))
                    Text(isPaused ? "Resume" : "Pause")
                        .font(themeManager.bodyFont)
                }
                .foregroundColor(themeManager.textOnAccentColor)
            }
            
            // Done
            Button {
                completeBlock()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                    Text("Done")
                        .font(themeManager.captionFont)
                }
                .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var timeRemainingFormatted: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        actualStartTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard !isPaused else { return }
            
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Auto-complete when time runs out
                completeBlock()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func togglePause() {
        isPaused.toggle()
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    // MARK: - Actions
    
    private func loadData() {
        if let categoryID = block.categoryID {
            category = storeContainer.categoryStore.fetchByID(categoryID)
        }
    }
    
    private func completeBlock() {
        var updated = block
        updated.actualStartDate = actualStartTime
        updated.actualEndDate = Date()
        updated.markDone()
        
        onComplete(updated)
        
        // Haptic feedback
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        
        dismiss()
    }
    
    private func skipBlock() {
        // Just dismiss without marking done
        dismiss()
    }
}

#Preview {
    let block = TimeBlock(
        title: "Deep Work Session",
        emoji: "🎯",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )
    
    return FocusView(block: block) { _ in }
        .environmentObject(ThemeManager())
        .environmentObject({
            let container = ModelContainer.createPreview()
            return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
        }())
}
