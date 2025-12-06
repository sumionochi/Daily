//
//  AppBackgroundView.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


import SwiftUI

struct AppBackgroundView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            if themeManager.uiStyle == .liquidGlass {
                // Subtle gradient overlay for liquid glass
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.03),
                        Color.clear,
                        themeManager.accent.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    Group {
        AppBackgroundView()
            .environmentObject({
                let tm = ThemeManager()
                tm.uiStyle = .mono
                return tm
            }())
        
        AppBackgroundView()
            .environmentObject({
                let tm = ThemeManager()
                tm.uiStyle = .liquidGlass
                return tm
            }())
    }
}