//
//  SettingsView.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


// Features/Settings/Views/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Appearance Section
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
                        
                        // About Section
                        VStack(spacing: 12) {
                            AppSectionHeader("About")
                            
                            AppCard {
                                HStack {
                                    Text("Version")
                                        .font(themeManager.bodyFont)
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    
                                    Spacer()
                                    
                                    Text("1.0.0")
                                        .font(themeManager.bodyFont)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}