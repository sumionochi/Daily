// Features/Radial/Views/InnerPlaceUnfocused.swift

import SwiftUI
import SwiftData

struct InnerPlaceUnfocused: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: RadialViewModel

    let innerRadius: CGFloat
    let outerRadius: CGFloat

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(themeManager.backgroundColor.opacity(0.95))

            // Center content
            centerContent
                .padding(.horizontal, 16)

            // Moon at 00 / 24 (fixed to dial)
            moonIcon
                .offset(y: -(outerRadius - 65))

            // Sun at 12 (fixed to dial)
            sunIcon
                .offset(y: (outerRadius - 65))
        }
        .frame(width: innerRadius * 2,
               height: innerRadius * 2)
    }

    // MARK: - Moon Icon

    private var moonIcon: some View {
        Image(systemName: "moon.stars.fill")
            .font(.system(size: 14))
            .foregroundColor(.blue.opacity(0.8))
    }

    // MARK: - Sun Icon

    private var sunIcon: some View {
        Image(systemName: "sun.max.fill")
            .font(.system(size: 14))
            .foregroundColor(.orange.opacity(0.9))
    }

    // MARK: - Center Content

    private var centerContent: some View {
        VStack(spacing: 4) {
            dayText
            scheduledTimeText

            if let stats = viewModel.statistics,
               !stats.categoryBreakdown.isEmpty {
                categoryStatsList
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }

    // MARK: - Day Text

    private var dayText: some View {
        VStack(spacing: 2) {
            Text(dayLabel)
                .font(.system(size: 16,
                              weight: .semibold,
                              design: .rounded))
                .foregroundColor(themeManager.textPrimaryColor)

            Text(dateLabel)
                .font(.system(size: 12,
                              weight: .medium,
                              design: .rounded))
                .foregroundColor(themeManager.textSecondaryColor)
        }
    }

    // MARK: - Scheduled Time Text

    private var scheduledTimeText: some View {
        Text(scheduledTimeLabel)
            .font(.system(size: 13,
                          weight: .medium,
                          design: .rounded))
            .foregroundColor(themeManager.textSecondaryColor)
    }

    // MARK: - Category Stats List

    private var categoryStatsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 3) {
                if let stats = viewModel.statistics {
                    ForEach(stats.categoryBreakdown.prefix(4), id: \.category.id) { item in
                        CategoryStatRow(
                            category: item.category,
                            duration: item.duration
                        )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxHeight: 70)
    }

    // MARK: - Computed Properties

    private var dayLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(viewModel.currentDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(viewModel.currentDate) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(viewModel.currentDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: viewModel.currentDate)
        }
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: viewModel.currentDate)
    }

    private var scheduledTimeLabel: String {
        if let stats = viewModel.statistics {
            return "\(stats.totalScheduledFormatted) scheduled"
        } else {
            return "0h 0m scheduled"
        }
    }
}

// MARK: - Category Stat Row

struct CategoryStatRow: View {
    @EnvironmentObject var themeManager: ThemeManager

    let category: Category
    let duration: TimeInterval

    var body: some View {
        HStack(spacing: 6) {
            Text(category.emoji)
                .font(.system(size: 12))

            Text(category.name)
                .font(.system(size: 11,
                              weight: .medium,
                              design: .rounded))
                .foregroundColor(themeManager.textPrimaryColor)

            Spacer()

            Text(durationFormatted)
                .font(.system(size: 11,
                              weight: .semibold,
                              design: .rounded))
                .foregroundColor(categoryColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(categoryColor.opacity(0.12))
        )
    }

    private var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private var categoryColor: Color {
        switch category.colorID {
        case "blue":   return Color(red: 0.4, green: 0.6, blue: 1.0)
        case "purple": return Color(red: 0.7, green: 0.5, blue: 1.0)
        case "pink":   return Color(red: 1.0, green: 0.5, blue: 0.7)
        case "orange": return Color(red: 1.0, green: 0.6, blue: 0.4)
        case "green":  return Color(red: 0.5, green: 0.9, blue: 0.6)
        case "teal":   return Color(red: 0.4, green: 0.8, blue: 0.9)
        default:       return .blue
        }
    }
}

#Preview {
    let container = ModelContainer.createPreview()
    let storeContainer = StoreContainer(
        modelContext: container.mainContext,
        shouldSeed: true
    )
    let viewModel = RadialViewModel(date: Date(), storeContainer: storeContainer)

    return ZStack {
        Color.black
        InnerPlaceUnfocused(viewModel: viewModel, innerRadius: 96, outerRadius: 180)
            .environmentObject(ThemeManager())
            .environmentObject(storeContainer)
    }
}
