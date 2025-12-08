//
//  InnerPlaceUnfocused.swift
//  Daily
//
//  Created by Aaditya Srivastava on 08/12/25.
//


// Features/Radial/Views/InnerPlaceUnfocused.swift

import SwiftUI
import SwiftData

struct InnerPlaceUnfocused: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: RadialViewModel
    
    let innerRadius: CGFloat
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(themeManager.backgroundColor.opacity(0.95))
                .frame(width: innerRadius * 2, height: innerRadius * 2)
            
            VStack(spacing: 0) {
                // Top icon (Sun)
                sunIcon
                    .padding(.top, 16)
                
                Spacer()
                
                // Middle content
                centerContent
                
                Spacer()
                
                // Bottom icon (Moon)
                moonIcon
                    .padding(.bottom, 16)
            }
            .frame(width: innerRadius * 2, height: innerRadius * 2)
        }
    }
    
    // MARK: - Sun Icon
    
    private var sunIcon: some View {
        Image(systemName: "sun.max.fill")
            .font(.system(size: 20))
            .foregroundColor(.orange)
            .symbolEffect(.pulse, options: .repeating)
    }
    
    // MARK: - Moon Icon
    
    private var moonIcon: some View {
        Image(systemName: "moon.stars.fill")
            .font(.system(size: 20))
            .foregroundColor(.blue.opacity(0.8))
    }
    
    // MARK: - Center Content
    
    private var centerContent: some View {
        VStack(spacing: 12) {
            // Day text
            dayText
            
            // Total scheduled time
            scheduledTimeText
            
            // Category stats (scrollable)
            if let stats = viewModel.statistics, !stats.categoryBreakdown.isEmpty {
                categoryStatsList
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Day Text
    
    private var dayText: some View {
        VStack(spacing: 2) {
            Text(dayLabel)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.textPrimaryColor)
            
            Text(dateLabel)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.textSecondaryColor)
        }
    }
    
    // MARK: - Scheduled Time Text
    
    private var scheduledTimeText: some View {
        Text(scheduledTimeLabel)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(themeManager.textSecondaryColor)
    }
    
    // MARK: - Category Stats List
    
    private var categoryStatsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                if let stats = viewModel.statistics {
                    ForEach(Array(stats.categoryBreakdown.prefix(4)), id: \.category.id) { item in
                        CategoryStatRow(
                            category: item.category,
                            duration: item.duration
                        )
                    }
                }
            }
        }
        .frame(maxHeight: 100)
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
            formatter.dateFormat = "EEEE" // Full weekday name
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
        HStack(spacing: 8) {
            // Emoji
            Text(category.emoji)
                .font(.system(size: 14))
            
            // Category name
            Text(category.name)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.textPrimaryColor)
            
            Spacer()
            
            // Duration
            Text(durationFormatted)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(categoryColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(categoryColor.opacity(0.1))
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
        case "blue": return Color(red: 0.4, green: 0.6, blue: 1.0)
        case "purple": return Color(red: 0.7, green: 0.5, blue: 1.0)
        case "pink": return Color(red: 1.0, green: 0.5, blue: 0.7)
        case "orange": return Color(red: 1.0, green: 0.6, blue: 0.4)
        case "green": return Color(red: 0.5, green: 0.9, blue: 0.6)
        case "teal": return Color(red: 0.4, green: 0.8, blue: 0.9)
        default: return .blue
        }
    }
}

#Preview {
    let container = ModelContainer.createPreview()
    let storeContainer = StoreContainer(modelContext: container.mainContext, shouldSeed: true)
    let viewModel = RadialViewModel(date: Date(), storeContainer: storeContainer)
    
    return ZStack {
        Color.black
        InnerPlaceUnfocused(viewModel: viewModel, innerRadius: 110)
            .environmentObject(ThemeManager())
    }
}
