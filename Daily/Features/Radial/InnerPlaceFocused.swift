// Features/Radial/Views/InnerPlaceFocused.swift

import SwiftUI
import SwiftData

struct InnerPlaceFocused: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer

    let block: TimeBlock          // original block (for id)
    @ObservedObject var viewModel: RadialViewModel
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    @State private var category: Category?
    @State private var pulseAnimation = false   // kept in case you want to re-enable later

    // Small static formatter for compact time range
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    /// Block that should be shown in the UI:
    /// if there is a live preview while dragging, use that,
    /// otherwise fall back to the original block.
    private var displayedBlock: TimeBlock {
        if let live = viewModel.liveEditingBlock,
           live.id == block.id {
            return live
        } else {
            return block
        }
    }

    var body: some View {
        ZStack {
            // Minimal flat circle
            Circle()
                .fill(themeManager.backgroundColor.opacity(0.96))

            // Center content (emoji, title, time, tag)
            mainContent
                .padding(.horizontal, 20)

            // Moon at 00 / 24 (top, fixed to dial)
            topIcon
                .offset(y: -(outerRadius - 65))

            // Sun at 12 (bottom, fixed to dial)
            bottomIcon
                .offset(y: (outerRadius - 65))
        }
        .frame(width: innerRadius * 2,
               height: innerRadius * 2)
        .onAppear {
            loadCategory()
            startPulseAnimation()
        }
        .onChange(of: block.id) { _, _ in
            loadCategory()
        }
    }

    // MARK: - Top / bottom icons

    private var topIcon: some View {
        Image(systemName: "moon.stars.fill")
            .font(.system(size: 14))
            .foregroundColor(.blue.opacity(0.8))
    }

    private var bottomIcon: some View {
        Image(systemName: "sun.max.fill")
            .font(.system(size: 14))
            .foregroundColor(.orange.opacity(0.9))
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 10) {
            emojiDisplay
            titleDisplay
            timeRangeLabel

            if let cat = category {
                tagPill(cat)
                    .scaleEffect(0.7)
            }
        }
    }

    // MARK: - Emoji

    private var emojiDisplay: some View {
        Group {
            if let emoji = displayedBlock.emoji {
                Text(emoji)
                    .font(.system(size: 40))   // static, no pulsing / up-down
            } else {
                Image(systemName: "square.dashed")
                    .font(.system(size: 32))
                    .foregroundColor(themeManager.textTertiaryColor)
            }
        }
    }

    // MARK: - Title

    private var titleDisplay: some View {
        Text(displayedBlock.title)
            .font(.system(size: 18,
                          weight: .semibold,
                          design: .rounded))
            .foregroundColor(themeManager.textPrimaryColor)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Time Range (single line, minimal)

    private var timeRangeLabel: some View {
        Text(timeRangeText)
            .font(.system(size: 14,
                          weight: .medium,
                          design: .rounded))
            .foregroundColor(themeManager.textSecondaryColor)
    }

    private var timeRangeText: String {
        let f = Self.timeFormatter
        let start = f.string(from: displayedBlock.startDate)
        let end   = f.string(from: displayedBlock.endDate)
        return "\(start) – \(end)"
    }

    // MARK: - Tag pill (“Focus”, “Creative”, …)

    private func tagPill(_ category: Category) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(categoryColor)
                .frame(width: 6, height: 6)

            Text(category.name)        // short tag like “Focus”
                .font(.system(size: 14,
                              weight: .medium,
                              design: .rounded))
        }
        .foregroundColor(themeManager.textPrimaryColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(themeManager.cardBackgroundColor.opacity(0.95))
        )
        .overlay(
            Capsule()
                .stroke(categoryColor.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)
    }

    // MARK: - Category / Helpers

    private var categoryColor: Color {
        guard let category = category else {
            return themeManager.accent
        }

        switch category.colorID {
        case "blue":   return Color(red: 0.4, green: 0.6, blue: 1.0)
        case "purple": return Color(red: 0.7, green: 0.5, blue: 1.0)
        case "pink":   return Color(red: 1.0, green: 0.5, blue: 0.7)
        case "orange": return Color(red: 1.0, green: 0.6, blue: 0.4)
        case "green":  return Color(red: 0.5, green: 0.9, blue: 0.6)
        case "teal":   return Color(red: 0.4, green: 0.8, blue: 0.9)
        default:       return themeManager.accent
        }
    }

    private func loadCategory() {
        guard let categoryID = displayedBlock.categoryID else {
            category = nil
            return
        }

        category = storeContainer.categoryStore.fetchAll()
            .first { $0.id == categoryID }
    }

    private func startPulseAnimation() {
        // currently just flips the flag; you can remove it
        // or re-use it later for subtle effects
        pulseAnimation = true
    }
}

#Preview {
    let container = ModelContainer.createPreview()
    let storeContainer = StoreContainer(
        modelContext: container.mainContext,
        shouldSeed: true
    )
    let viewModel = RadialViewModel(date: Date(), storeContainer: storeContainer)

    let block = TimeBlock(
        title: "Deep Work Session",
        emoji: "💻",
        startDate: Date(),
        endDate: Date().addingTimeInterval(7200),
        categoryID: nil
    )

    return ZStack {
        Color.black
        InnerPlaceFocused(
            block: block,
            viewModel: viewModel,
            innerRadius: 96,
            outerRadius: 180
        )
        .environmentObject(ThemeManager())
        .environmentObject(storeContainer)
    }
}
