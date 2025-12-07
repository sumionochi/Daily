//
//  QuickTaskSheet.swift
//  Daily
//
//  Created by Aaditya Srivastava on 07/12/25.
//


// Features/Today/Views/QuickTaskSheet.swift

import SwiftUI
import SwiftData

struct QuickTaskSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    @Environment(\.dismiss) var dismiss
    
    let date: Date
    let onSave: (TimeBlock) -> Void
    
    @State private var title = ""
    @State private var emoji = ""
    @State private var selectedCategory: UUID?
    @State private var duration = 30
    @State private var startHour = 9
    @State private var startMinute = 0
    @State private var categories: [Category] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title & Emoji
                        AppCard {
                            HStack(spacing: 12) {
                                TextField("Emoji", text: $emoji)
                                    .font(.system(size: 32))
                                    .frame(width: 50)
                                    .multilineTextAlignment(.center)
                                
                                TextField("Block title", text: $title)
                                    .font(themeManager.bodyFont)
                                    .foregroundColor(themeManager.textPrimaryColor)
                            }
                        }
                        
                        // Start Time
                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Start Time")
                                    .font(themeManager.captionFont)
                                    .foregroundColor(themeManager.textSecondaryColor)
                                
                                HStack {
                                    Picker("Hour", selection: $startHour) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text(String(format: "%02d", hour))
                                                .tag(hour)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 80)
                                    
                                    Text(":")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    
                                    Picker("Minute", selection: $startMinute) {
                                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                                            Text(String(format: "%02d", minute))
                                                .tag(minute)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 80)
                                }
                                .frame(height: 120)
                            }
                        }
                        
                        // Duration
                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Duration")
                                    .font(themeManager.captionFont)
                                    .foregroundColor(themeManager.textSecondaryColor)
                                
                                Picker("Duration", selection: $duration) {
                                    Text("15 min").tag(15)
                                    Text("30 min").tag(30)
                                    Text("45 min").tag(45)
                                    Text("1 hour").tag(60)
                                    Text("1.5 hours").tag(90)
                                    Text("2 hours").tag(120)
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        
                        // Category
                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Category")
                                    .font(themeManager.captionFont)
                                    .foregroundColor(themeManager.textSecondaryColor)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        categoryButton(category: nil)
                                        
                                        ForEach(categories) { category in
                                            categoryButton(category: category)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("New Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveBlock()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                categories = storeContainer.categoryStore.fetchAll()
                setDefaultTime()
            }
        }
    }
    
    // MARK: - Category Button
    
    private func categoryButton(category: Category?) -> some View {
        Button {
            selectedCategory = category?.id
        } label: {
            HStack(spacing: 6) {
                Text(category?.emoji ?? "⚪️")
                    .font(.system(size: 16))
                
                Text(category?.name ?? "None")
                    .font(themeManager.captionFont)
                    .foregroundColor(
                        selectedCategory == category?.id ?
                        themeManager.textOnAccentColor : themeManager.textPrimaryColor
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                selectedCategory == category?.id ?
                    themeManager.accent : themeManager.secondaryBackgroundColor
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Actions
    
    private func setDefaultTime() {
        let calendar = Calendar.current
        let now = Date()
        
        // Default to current hour + 1
        var hour = calendar.component(.hour, from: now) + 1
        if hour >= 24 { hour = 0 }
        
        startHour = hour
        startMinute = 0
    }
    
    private func saveBlock() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = startHour
        components.minute = startMinute
        
        guard let startDate = calendar.date(from: components) else { return }
        let endDate = startDate.addingTimeInterval(TimeInterval(duration * 60))
        
        let block = TimeBlock(
            title: title,
            emoji: emoji.isEmpty ? nil : emoji,
            startDate: startDate,
            endDate: endDate,
            categoryID: selectedCategory,
            sourceType: .manual
        )
        
        onSave(block)
        dismiss()
    }
}

#Preview {
    QuickTaskSheet(date: Date()) { _ in }
        .environmentObject(ThemeManager())
        .environmentObject({
            let container = ModelContainer.createPreview()
            return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
        }())
}
