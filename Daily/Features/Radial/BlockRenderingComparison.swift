// Features/Radial/Views/BlockRenderingComparison.swift

import SwiftUI

struct BlockRenderingComparison: View {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Text("Block Rendering Comparison")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                // Old style
                comparisonSection(
                    title: "Before (Chunk 3)",
                    subtitle: "Solid color, label outside",
                    style: .old
                )
                
                // New style
                comparisonSection(
                    title: "After (Chunk 4)",
                    subtitle: "Transparent fill, opaque border, label inside",
                    style: .new
                )
                
                featuresList
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .environmentObject(themeManager)
    }
    
    // MARK: - Comparison Section
    
    private func comparisonSection(title: String, subtitle: String, style: BlockStyle) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Sample blocks
            HStack(spacing: 20) {
                blockSample(
                    title: "Deep Work",
                    emoji: "🎯",
                    color: .blue,
                    angle: 60,
                    style: style
                )
                
                blockSample(
                    title: "Meeting",
                    emoji: "💼",
                    color: .purple,
                    angle: 45,
                    style: style
                )
                
                blockSample(
                    title: "Break",
                    emoji: "☕",
                    color: .orange,
                    angle: 30,
                    style: style
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
    }
    
    // MARK: - Block Sample
    
    private func blockSample(
        title: String,
        emoji: String,
        color: Color,
        angle: Double,
        style: BlockStyle
    ) -> some View {
        VStack(spacing: 8) {
            // Visual representation
            ZStack {
                if style == .old {
                    // Old: Solid fill
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color)
                        .frame(width: 80, height: 80)
                    
                    VStack(spacing: 4) {
                        Text(emoji)
                            .font(.system(size: 20))
                        Text(title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                    }
                } else {
                    // New: Transparent fill + border
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.35))
                        .frame(width: 80, height: 80)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color, lineWidth: 2)
                        .frame(width: 80, height: 80)
                    
                    VStack(spacing: 4) {
                        Text(emoji)
                            .font(.system(size: 20))
                        Text(title)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            
            Text("\(Int(angle))°")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Features List
    
    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Improvements")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.bottom, 8)
            
            featureItem(
                icon: "paintbrush.fill",
                title: "Transparent Fill",
                description: "35% opacity for better layering"
            )
            
            featureItem(
                icon: "rectangle.on.rectangle",
                title: "Opaque Border",
                description: "2pt border for clear definition"
            )
            
            featureItem(
                icon: "textformat.size",
                title: "Adaptive Sizing",
                description: "Text/emoji scale with arc size"
            )
            
            featureItem(
                icon: "arrow.up.and.down.text.horizontal",
                title: "Inside Layout",
                description: "Content centered in arc"
            )
            
            featureItem(
                icon: "eye.fill",
                title: "Better Readability",
                description: "High contrast on all backgrounds"
            )
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
    }
    
    private func featureItem(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

enum BlockStyle {
    case old, new
}

#Preview {
    BlockRenderingComparison()
}
