//
//  RoutineSheet.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Features/Routines/Views/RoutineSheet.swift

import SwiftUI
import SwiftData

struct RoutineSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    @Environment(\.dismiss) var dismiss
    
    let routine: Routine?
    let onSave: (Routine) -> Void
    let onDelete: (() -> Void)?
    
    @State private var title: String
    @State private var emoji: String
    @State private var duration: Int
    @State private var selectedCategory: UUID?
    @State private var frequency: RecurrenceFrequency
    @State private var hasStartTime: Bool
    @State private var startHour: Int
    @State private var startMinute: Int
    @State private var notes: String
    @State private var categories: [Category] = []
    
    init(
        routine: Routine?,
        onSave: @escaping (Routine) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.routine = routine
        self.onSave = onSave
        self.onDelete = onDelete
        
        _title = State(initialValue: routine?.title ?? "")
        _emoji = State(initialValue: routine?.emoji ?? "")
        _duration = State(initialValue: routine?.duration ?? 30)
        _selectedCategory = State(initialValue: routine?.categoryID)
        _frequency = State(initialValue: routine?.recurrenceRule.frequency ?? .daily)
        _hasStartTime = State(initialValue: routine?.preferredStartTime != nil)
        _startHour = State(initialValue: routine?.preferredStartTime?.hour ?? 9)
        _startMinute = State(initialValue: routine?.preferredStartTime?.minute ?? 0)
        _notes = State(initialValue: routine?.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title & Emoji
                        titleSection
                        
                        // Duration
                        durationSection
                        
                        // Category
                        categorySection
                        
                        // Recurrence
                        recurrenceSection
                        
                        // Start Time
                        startTimeSection
                        
                        // Notes
                        notesSection
                        
                        // Delete button (if editing)
                        if routine != nil, let onDelete = onDelete {
                            deleteButton(action: onDelete)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(routine == nil ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRoutine()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
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
                    
                    TextField("Routine name", text: $title)
                        .font(themeManager.bodyFont)
                        .foregroundColor(themeManager.textPrimaryColor)
                }
            }
        }
    }
    
    private var durationSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Duration")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                Picker("Duration", selection: $duration) {
                    Text("15 min").tag(15)
                    Text("30 min").tag(30)
                    Text("45 min").tag(45)
                    Text("60 min").tag(60)
                    Text("90 min").tag(90)
                    Text("2 hours").tag(120)
                }
                .pickerStyle(.segmented)
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
                        categoryButton(category: nil)
                        
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
    
    private var recurrenceSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Repeats")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                Picker("Frequency", selection: $frequency) {
                    ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                        Text(freq.displayName).tag(freq)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private var startTimeSection: some View {
        AppCard {
            VStack(spacing: 12) {
                Toggle("Set Preferred Start Time", isOn: $hasStartTime)
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                if hasStartTime {
                    HStack(spacing: 16) {
                        Text("Start at")
                            .font(themeManager.bodyFont)
                            .foregroundColor(themeManager.textSecondaryColor)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Picker("Hour", selection: $startHour) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(String(format: "%02d", hour))
                                        .tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 60)
                            
                            Text(":")
                                .foregroundColor(themeManager.textPrimaryColor)
                            
                            Picker("Minute", selection: $startMinute) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text(String(format: "%02d", minute))
                                        .tag(minute)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 60)
                        }
                    }
                }
            }
        }
    }
    
    private var notesSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                TextEditor(text: $notes)
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
            }
        }
    }
    
    private func deleteButton(action: @escaping () -> Void) -> some View {
        Button(role: .destructive) {
            action()
            dismiss()
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Routine")
            }
            .font(themeManager.buttonFont)
            .foregroundColor(themeManager.textOnAccentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadiusMedium))
        }
    }
    
    // MARK: - Actions
    
    private func saveRoutine() {
        let preferredTime: DateComponents? = hasStartTime ? {
            var components = DateComponents()
            components.hour = startHour
            components.minute = startMinute
            return components
        }() : nil
        
        let rule = RecurrenceRule(frequency: frequency)
        
        let newRoutine = Routine(
            id: routine?.id ?? UUID(),
            title: title,
            emoji: emoji.isEmpty ? nil : emoji,
            categoryID: selectedCategory,
            duration: duration,
            preferredStartTime: preferredTime,
            recurrenceRule: rule,
            isEnabled: routine?.isEnabled ?? true,
            notes: notes.isEmpty ? nil : notes
        )
        
        onSave(newRoutine)
        dismiss()
    }
}

#Preview {
    RoutineSheet(
        routine: nil,
        onSave: { _ in }
    )
    .environmentObject(ThemeManager())
    .environmentObject({
        let container = ModelContainer.createPreview()
        return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
    }())
}
