//
//  AppSectionHeader.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


import SwiftUI

struct AppSectionHeader: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let action: (() -> Void)?
    let actionLabel: String?
    
    init(
        _ title: String,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.actionLabel = actionLabel
        self.action = action
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(themeManager.subtitleFont)
                .foregroundColor(themeManager.textPrimaryColor)
            
            Spacer()
            
            if let actionLabel = actionLabel, let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(themeManager.captionFont)
                        .foregroundColor(themeManager.accent)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    ZStack {
        AppBackgroundView()
        
        VStack {
            AppSectionHeader("Section Title")
            AppSectionHeader(
                "With Action",
                actionLabel: "See All",
                action: { print("Tapped") }
            )
        }
    }
    .environmentObject(ThemeManager())
}