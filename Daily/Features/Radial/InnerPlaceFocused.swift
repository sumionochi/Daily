// Features/Radial/Views/InnerPlaceFocused.swift

import SwiftUI
import SwiftData

struct InnerPlaceFocused: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    let block: TimeBlock
    @ObservedObject var viewModel: RadialViewModel
    let innerRadius: CGFloat
    
    @State private var category: Category?
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Background circle with subtle gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            themeManager.backgroundColor.opacity(0.98),
                            themeManager.backgroundColor.opacity(0.92)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: innerRadius
                    )
                )
                .frame(width: innerRadius * 2, height: innerRadius * 2)
            
            VStack(spacing: 0) {
                // Top icon (Sun)
                sunIcon
                    .padding(.top, 20)
                
                Spacer()
                
                // Main content
                mainContent
                
                Spacer()
                
                // Bottom icon (Moon)
                moonIcon
                    .padding(.bottom, 20)
            }
            .frame(width: innerRadius * 2, height: innerRadius * 2)
        }
        .onAppear {
            loadCategory()
            startPulseAnimation()
        }
        .onChange(of: block.id) { _, _ in
            loadCategory()
        }
    }
    
    // MARK: - Sun Icon
    
    private var sunIcon: some View {
        Image(systemName: "sun.max.fill")
            .font(.system(size: 18))
            .foregroundColor(.orange.opacity(0.6))
    }
    
    // MARK: - Moon Icon
    
    private var moonIcon: some View {
        Image(systemName: "moon.stars.fill")
            .font(.system(size: 18))
            .foregroundColor(.blue.opacity(0.6))
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 16) {
            // Large Emoji with pulse effect
            emojiDisplay
            
            // Block title
            titleDisplay
            
            // Time range
            timeRangeDisplay
            
            // Category tag
            if let cat = category {
                categoryTag(cat)
            }
            
            // Completion status
            if block.isDone {
                completionBadge
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Emoji Display
    
    private var emojiDisplay: some View {
        Group {
            if let emoji = block.emoji {
                Text(emoji)
                    .font(.system(size: 56))
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
            } else {
                Image(systemName: "square.dashed")
                    .font(.system(size: 48))
                    .foregroundColor(themeManager.textTertiaryColor)
            }
        }
    }
    
    // MARK: - Title Display
    
    private var titleDisplay: some View {
        Text(block.title)
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(themeManager.textPrimaryColor)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Time Range Display
    
    private var timeRangeDisplay: some View {
        HStack(spacing: 8) {
            // Start time
            timeChip(time: block.startDate, icon: "clock")
            
            // Arrow
            Image(systemName: "arrow.right")
                .font(.system(size: 12))
                .foregroundColor(themeManager.textTertiaryColor)
            
            // End time
            timeChip(time: block.endDate, icon: "clock.fill")
        }
    }
    
    private func timeChip(time: Date, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            
            Text(time, format: .dateTime.hour().minute())
                .font(.system(size: 14, weight: .medium, design: .rounded))
        }
        .foregroundColor(themeManager.textSecondaryColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(themeManager.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Category Tag
    
    private func categoryTag(_ category: Category) -> some View {
        HStack(spacing: 6) {
            // Color indicator
            Circle()
                .fill(categoryColor)
                .frame(width: 8, height: 8)
            
            // Category name
            Text(category.name)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.textPrimaryColor)
            
            // Duration
            Text("·")
                .foregroundColor(themeManager.textTertiaryColor)
            
            Text("\(block.durationMinutes)m")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(categoryColor.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(categoryColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Completion Badge
    
    private var completionBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
            
            Text("Completed")
                .font(.system(size: 13, weight: .medium, design: .rounded))
        }
        .foregroundColor(.green)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.15))
        )
    }
    
    // MARK: - Computed Properties
    
    private var categoryColor: Color {
        guard let category = category else {
            return themeManager.accent
        }
        
        switch category.colorID {
        case "blue": return Color(red: 0.4, green: 0.6, blue: 1.0)
        case "purple": return Color(red: 0.7, green: 0.5, blue: 1.0)
        case "pink": return Color(red: 1.0, green: 0.5, blue: 0.7)
        case "orange": return Color(red: 1.0, green: 0.6, blue: 0.4)
        case "green": return Color(red: 0.5, green: 0.9, blue: 0.6)
        case "teal": return Color(red: 0.4, green: 0.8, blue: 0.9)
        default: return themeManager.accent
        }
    }
    
    // MARK: - Helpers
    
    private func loadCategory() {
        guard let categoryID = block.categoryID else {
            category = nil
            return
        }
        
        category = storeContainer.categoryStore.fetchAll()
            .first { $0.id == categoryID }
    }
    
    private func startPulseAnimation() {
        pulseAnimation = true
    }
}

#Preview {
    let container = ModelContainer.createPreview()
    let storeContainer = StoreContainer(modelContext: container.mainContext, shouldSeed: true)
    let viewModel = RadialViewModel(date: Date(), storeContainer: storeContainer)
    
    let block = TimeBlock(
        title: "Deep Work Session",
        emoji: "🎯",
        startDate: Date(),
        endDate: Date().addingTimeInterval(7200),
        categoryID: nil
    )
    
    return ZStack {
        Color.black
        InnerPlaceFocused(
            block: block,
            viewModel: viewModel,
            innerRadius: 110
        )
        .environmentObject(ThemeManager())
        .environmentObject(storeContainer)
    }
}
