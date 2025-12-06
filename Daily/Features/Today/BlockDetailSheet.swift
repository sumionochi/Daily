//
//  BlockDetailSheet.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Features/Today/Views/BlockDetailSheet.swift

import SwiftUI
import SwiftData

struct BlockDetailSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    @Environment(\.dismiss) var dismiss
    
    let block: TimeBlock
    let onSave: (TimeBlock) -> Void
    let onDelete: () -> Void
    
    @State private var title: String
    @State private var emoji: String
    @State private var selectedCategory: UUID?
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String
    @State private var categories: [Category] = []
    
    init(
        block: TimeBlock,
        onSave: @escaping (TimeBlock) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.block = block
        self.onSave = onSave
        self.onDelete = onDelete
        
        _title = State(initialValue: block.title)
        _emoji = State(initialValue: block.emoji ?? "")
        _selectedCategory = State(initialValue: block.categoryID)
        _startDate = State(initialValue: block.startDate)
        _endDate = State(initialValue: block.endDate)
        _notes = State(initialValue: block.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title & Emoji
                        titleSection
                        
                        // Category
                        categorySection
                        
                        // Time
                        timeSection
                        
                        // Duration display
                        durationDisplay
                        
                        // Notes
                        notesSection
                        
                        // Delete button
                        deleteButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBlock()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                categories = storeContainer.categoryStore.fetchAll()
            }
        }
    }
    
    // MARK: - Sections
    
    private var titleSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Title")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
                
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
        }
    }
    
    private var categorySection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Category")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // None option
                        categoryButton(category: nil)
                        
                        // Categories
                        ForEach(categories) { category in
                            categoryButton(category: category)
                        }
                    }
                }
            }
        }
    }
    
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
                            .white : themeManager.textPrimaryColor
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
    
    private var timeSection: some View {
        AppCard {
            VStack(spacing: 16) {
                // Start time
                HStack {
                    Text("Start")
                        .font(themeManager.bodyFont)
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    Spacer()
                    
                    DatePicker("", selection: $startDate, displayedComponents: [.hourAndMinute])
                        .labelsHidden()
                }
                
                Divider()
                
                // End time
                HStack {
                    Text("End")
                        .font(themeManager.bodyFont)
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    Spacer()
                    
                    DatePicker("", selection: $endDate, displayedComponents: [.hourAndMinute])
                        .labelsHidden()
                }
            }
        }
    }
    
    private var durationDisplay: some View {
        AppCard {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(themeManager.accent)
                
                Text("Duration")
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Spacer()
                
                Text(durationText)
                    .font(themeManager.subtitleFont)
                    .foregroundColor(themeManager.accent)
            }
        }
    }
    
    private var notesSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Notes")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                TextEditor(text: $notes)
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
            }
        }
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            onDelete()
            dismiss()
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Block")
            }
            .font(themeManager.buttonFont)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadiusMedium))
        }
    }
    
    // MARK: - Computed Properties
    
    private var durationText: String {
        let duration = endDate.timeIntervalSince(startDate)
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Actions
    
    private func saveBlock() {
        var updated = block
        updated.title = title
        updated.emoji = emoji.isEmpty ? nil : emoji
        updated.categoryID = selectedCategory
        updated.startDate = startDate
        updated.endDate = endDate
        updated.notes = notes.isEmpty ? nil : notes
        
        onSave(updated)
        dismiss()
    }
}

#Preview {
    let block = TimeBlock(
        title: "Deep Work",
        emoji: "🎯",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )
    
    return BlockDetailSheet(
        block: block,
        onSave: { _ in },
        onDelete: { }
    )
    .environmentObject(ThemeManager())
    .environmentObject({
        let container = ModelContainer.createPreview()
        return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
    }())
}
