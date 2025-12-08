// Features/Inbox/Views/NewTaskSheet.swift

import SwiftUI
import SwiftData

struct NewTaskSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    @Environment(\.dismiss) var dismiss
    
    let onSave: (Task) -> Void
    
    @State private var title = ""
    @State private var notes = ""
    @State private var estimatedDuration = 30
    @State private var selectedCategory: UUID?
    @State private var priority: TaskPriority = .medium
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var categories: [Category] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title
                        titleSection
                        
                        // Duration
                        durationSection
                        
                        // Category
                        categorySection
                        
                        // Priority
                        prioritySection
                        
                        // Due date
                        dueDateSection
                        
                        // Notes
                        notesSection
                    }
                    .padding()
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
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
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                TextField("What needs to be done?", text: $title)
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textPrimaryColor)
            }
        }
    }
    
    private var durationSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Estimated Duration")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                Picker("Duration", selection: $estimatedDuration) {
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
    
    private var prioritySection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Priority")
                    .font(themeManager.captionFont)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                Picker("Priority", selection: $priority) {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        Text(priority.displayName).tag(priority)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private var dueDateSection: some View {
        AppCard {
            VStack(spacing: 12) {
                Toggle("Set Due Date", isOn: $hasDueDate)
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                if hasDueDate {
                    DatePicker(
                        "Due Date",
                        selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
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
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveTask() {
        let task = Task(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            estimatedDuration: estimatedDuration,
            categoryID: selectedCategory,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil
        )
        
        onSave(task)
        dismiss()
    }
}

#Preview {
    NewTaskSheet { _ in }
        .environmentObject(ThemeManager())
        .environmentObject({
            let container = ModelContainer.createPreview()
            return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
        }())
}
