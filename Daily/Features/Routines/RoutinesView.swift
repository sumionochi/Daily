// Features/Routines/Views/RoutinesView.swift

import SwiftUI
import SwiftData

struct RoutinesView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var storeContainer: StoreContainer
    
    @State private var routines: [Routine] = []
    @State private var showingNewRoutine = false
    @State private var selectedRoutine: Routine?
    @State private var showingEditRoutine = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                
                Group {
                    if routines.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(routines) { routine in
                                    RoutineRow(
                                        routine: routine,
                                        onTap: {
                                            selectedRoutine = routine
                                            showingEditRoutine = true
                                        },
                                        onToggle: {
                                            toggleRoutine(routine)
                                        }
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Routines")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewRoutine = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(themeManager.accent)
                    }
                }
            }
            .sheet(isPresented: $showingNewRoutine) {
                RoutineSheet(
                    routine: nil,
                    onSave: { routine in
                        createRoutine(routine)
                    }
                )
            }
            .sheet(isPresented: $showingEditRoutine) {
                if let routine = selectedRoutine {
                    RoutineSheet(
                        routine: routine,
                        onSave: { updated in
                            updateRoutine(updated)
                        },
                        onDelete: {
                            deleteRoutine(routine)
                        }
                    )
                }
            }
            .onAppear {
                loadRoutines()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "repeat.circle")
                .font(.system(size: 60))
                .foregroundColor(themeManager.textTertiaryColor)
            
            Text("No Routines Yet")
                .font(themeManager.titleFont)
                .foregroundColor(themeManager.textPrimaryColor)
            
            Text("Create recurring activities that appear automatically on your schedule")
                .font(themeManager.bodyFont)
                .foregroundColor(themeManager.textSecondaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showingNewRoutine = true
            } label: {
                Text("Create Your First Routine")
                    .font(themeManager.buttonFont)
                    .foregroundColor(themeManager.textOnAccentColor)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(themeManager.accent)
                    .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadiusMedium))
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func loadRoutines() {
        routines = storeContainer.routineStore.fetchAll()
    }
    
    private func createRoutine(_ routine: Routine) {
        if let created = storeContainer.routineStore.create(routine) {
            routines.append(created)
            storeContainer.routineEngine.generateBlocksForNextDays(30)
        }
    }
    
    private func updateRoutine(_ routine: Routine) {
        if let updated = storeContainer.routineStore.update(routine) {
            if let index = routines.firstIndex(where: { $0.id == routine.id }) {
                routines[index] = updated
            }
            storeContainer.routineEngine.updateFutureBlocks(for: updated)
        }
    }
    
    private func toggleRoutine(_ routine: Routine) {
        if let updated = storeContainer.routineStore.toggleEnabled(routine.id) {
            if let index = routines.firstIndex(where: { $0.id == routine.id }) {
                routines[index] = updated
            }
            
            if updated.isEnabled {
                storeContainer.routineEngine.generateBlocksForNextDays(30)
            } else {
                storeContainer.routineEngine.removeFutureBlocks(for: updated)
            }
        }
    }
    
    private func deleteRoutine(_ routine: Routine) {
        storeContainer.routineEngine.removeFutureBlocks(for: routine)
        
        if storeContainer.routineStore.delete(routine.id) {
            routines.removeAll { $0.id == routine.id }
        }
    }
}

// MARK: - Routine Row

struct RoutineRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let routine: Routine
    let onTap: () -> Void
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            AppCard(padding: 16) {
                HStack(spacing: 12) {
                    // Emoji
                    if let emoji = routine.emoji {
                        Text(emoji)
                            .font(.system(size: 32))
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        Text(routine.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(themeManager.textPrimaryColor)
                        
                        HStack(spacing: 12) {
                            // Duration
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                Text("\(routine.duration)m")
                                    .font(themeManager.captionFont)
                            }
                            .foregroundColor(themeManager.textTertiaryColor)
                            
                            // Recurrence
                            HStack(spacing: 4) {
                                Image(systemName: "repeat")
                                    .font(.system(size: 12))
                                Text(routine.recurrenceRule.frequency.displayName)
                                    .font(themeManager.captionFont)
                            }
                            .foregroundColor(themeManager.textTertiaryColor)
                            
                            // Time
                            if let startTime = routine.preferredStartTime {
                                HStack(spacing: 4) {
                                    Image(systemName: "alarm")
                                        .font(.system(size: 12))
                                    Text(String(format: "%02d:%02d", startTime.hour ?? 0, startTime.minute ?? 0))
                                        .font(themeManager.captionFont)
                                }
                                .foregroundColor(themeManager.textTertiaryColor)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Toggle
                    Toggle("", isOn: Binding(
                        get: { routine.isEnabled },
                        set: { _ in onToggle() }
                    ))
                    .labelsHidden()
                    .tint(themeManager.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RoutinesView()
        .environmentObject(ThemeManager())
        .environmentObject({
            let container = ModelContainer.createPreview()
            return StoreContainer(modelContext: container.mainContext, shouldSeed: true)
        }())
}
