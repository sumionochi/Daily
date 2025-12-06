//
//  AppCard.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


import SwiftUI

struct AppCard<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    let content: Content
    let padding: CGFloat
    
    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadiusMedium))
            .shadow(
                color: Color.black.opacity(themeManager.shadowOpacity),
                radius: themeManager.shadowRadius,
                x: 0,
                y: 4
            )
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        if themeManager.uiStyle == .liquidGlass {
            ZStack {
                themeManager.cardBackgroundColor
                
                // Blur effect
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)
            }
        } else {
            themeManager.cardBackgroundColor
        }
    }
}

#Preview {
    ZStack {
        AppBackgroundView()
        
        VStack(spacing: 20) {
            AppCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Task Title")
                        .font(.headline)
                    Text("Some description here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            AppCard(padding: 24) {
                Text("Large padding card")
            }
        }
        .padding()
    }
    .environmentObject(ThemeManager())
}