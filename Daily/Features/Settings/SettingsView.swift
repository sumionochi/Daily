// Features/Settings/Views/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var preferences = UserPreferences.load()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Appearance Section
                        appearanceSection
                        
                        // Planning Defaults Section
                        planningSection
                        
                        // About Section
                        aboutSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        VStack(spacing: 12) {
            AppSectionHeader("Appearance")
            
            VStack(spacing: 12) {
                // UI Style Toggle
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("UI Style")
                            .font(themeManager.bodyFont)
                            .foregroundColor(themeManager.textPrimaryColor)
                        
                        AppSegmentedControl(
                            selection: $themeManager.uiStyle,
                            displayNameProvider: { $0.displayName }
                        )
                    }
                }
                
                // Color Scheme
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theme")
                            .font(themeManager.bodyFont)
                            .foregroundColor(themeManager.textPrimaryColor)
                        
                        AppSegmentedControl(
                            selection: $themeManager.colorSchemePreference,
                            displayNameProvider: { $0.displayName }
                        )
                    }
                }
                
                // Accent Color
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Accent Color")
                            .font(themeManager.bodyFont)
                            .foregroundColor(themeManager.textPrimaryColor)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(AccentColor.allCases, id: \.self) { color in
                                Button {
                                    themeManager.accentColor = color
                                } label: {
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: themeManager.accentColor == color ? 3 : 0)
                                        )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Planning Section
    
    private var planningSection: some View {
        VStack(spacing: 12) {
            AppSectionHeader("Planning Defaults")
            
            VStack(spacing: 12) {
                // Wake Time
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Wake Time")
                                    .font(themeManager.bodyFont)
                                    .foregroundColor(themeManager.textPrimaryColor)
                                
                                Text("When your day typically starts")
                                    .font(themeManager.captionFont)
                                    .foregroundColor(themeManager.textSecondaryColor)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Picker("Hour", selection: $preferences.wakeHour) {
                                    ForEach(0..<24, id: \.self) { hour in
                                        Text(String(format: "%02d", hour))
                                            .tag(hour)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 60)
                                
                                Text(":")
                                    .foregroundColor(themeManager.textPrimaryColor)
                                
                                Picker("Minute", selection: $preferences.wakeMinute) {
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
                .onChange(of: preferences.wakeHour) { _, _ in preferences.save() }
                .onChange(of: preferences.wakeMinute) { _, _ in preferences.save() }
                
                // Sleep Time
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sleep Time")
                                    .font(themeManager.bodyFont)
                                    .foregroundColor(themeManager.textPrimaryColor)
                                
                                Text("When your day typically ends")
                                    .font(themeManager.captionFont)
                                    .foregroundColor(themeManager.textSecondaryColor)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Picker("Hour", selection: $preferences.sleepHour) {
                                    ForEach(0..<24, id: \.self) { hour in
                                        Text(String(format: "%02d", hour))
                                            .tag(hour)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 60)
                                
                                Text(":")
                                    .foregroundColor(themeManager.textPrimaryColor)
                                
                                Picker("Minute", selection: $preferences.sleepMinute) {
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
                .onChange(of: preferences.sleepHour) { _, _ in preferences.save() }
                .onChange(of: preferences.sleepMinute) { _, _ in preferences.save() }
                
                // Working Hours Display
                AppCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Working Hours")
                                .font(themeManager.bodyFont)
                                .foregroundColor(themeManager.textPrimaryColor)
                            
                            Text("Based on wake and sleep times")
                                .font(themeManager.captionFont)
                                .foregroundColor(themeManager.textSecondaryColor)
                        }
                        
                        Spacer()
                        
                        Text("\(preferences.workingHours)h")
                            .font(themeManager.subtitleFont)
                            .foregroundColor(themeManager.accent)
                    }
                }
                
                // Default Block Duration
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Default Block Duration")
                                    .font(themeManager.bodyFont)
                                    .foregroundColor(themeManager.textPrimaryColor)
                                
                                Text("New time blocks will use this duration")
                                    .font(themeManager.captionFont)
                                    .foregroundColor(themeManager.textSecondaryColor)
                            }
                            
                            Spacer()
                        }
                        
                        Picker("Duration", selection: $preferences.defaultBlockDuration) {
                            Text("15 min").tag(15)
                            Text("30 min").tag(30)
                            Text("45 min").tag(45)
                            Text("60 min").tag(60)
                            Text("90 min").tag(90)
                            Text("120 min").tag(120)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .onChange(of: preferences.defaultBlockDuration) { _, _ in preferences.save() }
                
                // Snap Interval
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time Snap Interval")
                                    .font(themeManager.bodyFont)
                                    .foregroundColor(themeManager.textPrimaryColor)
                                
                                Text("Blocks snap to this interval when dragging")
                                    .font(themeManager.captionFont)
                                    .foregroundColor(themeManager.textSecondaryColor)
                            }
                            
                            Spacer()
                        }
                        
                        Picker("Interval", selection: $preferences.snapInterval) {
                            Text("5 min").tag(5)
                            Text("10 min").tag(10)
                            Text("15 min").tag(15)
                            Text("30 min").tag(30)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .onChange(of: preferences.snapInterval) { _, _ in preferences.save() }
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(spacing: 12) {
            AppSectionHeader("About")
            
            AppCard {
                HStack {
                    Text("Version")
                        .font(themeManager.bodyFont)
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    Spacer()
                    
                    Text("1.0.0 (Phase 2)")
                        .font(themeManager.bodyFont)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
