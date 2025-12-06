//
//  AppToggle.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
//


import SwiftUI

struct AppToggle: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    init(_ title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(themeManager.bodyFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(themeManager.captionFont)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(themeManager.accent)
        }
        .padding(16)
        .background(themeManager.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadiusMedium))
    }
}

struct AppSegmentedControl<T: Hashable & CaseIterable & RawRepresentable>: View where T.RawValue == String, T.AllCases: RandomAccessCollection {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selection: T
    let displayNameProvider: (T) -> String
    
    init(
        selection: Binding<T>,
        displayNameProvider: @escaping (T) -> String
    ) {
        self._selection = selection
        self.displayNameProvider = displayNameProvider
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(T.allCases), id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = option
                    }
                } label: {
                    Text(displayNameProvider(option))
                        .font(themeManager.captionFont)
                        .foregroundColor(selection == option ? .white : themeManager.textPrimaryColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selection == option ? themeManager.accent : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadiusSmall))
                }
            }
        }
        .padding(4)
        .background(themeManager.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadiusMedium))
    }
}

#Preview {
    ZStack {
        AppBackgroundView()
        
        VStack(spacing: 16) {
            AppToggle(
                "Enable Feature",
                subtitle: "This is a helpful description",
                isOn: .constant(true)
            )
            
            AppSegmentedControl(
                selection: .constant(UIStyle.mono),
                displayNameProvider: { $0.displayName }
            )
        }
        .padding()
    }
    .environmentObject(ThemeManager())
}