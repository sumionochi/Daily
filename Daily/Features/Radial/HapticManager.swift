// Features/Radial/Utilities/HapticManager.swift

import UIKit

class HapticManager {
    
    // MARK: - Singleton
    
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Generators
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    // MARK: - Prepare (for low latency)
    
    func prepare() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactRigid.prepare()
        selectionGenerator.prepare()
    }
    
    // MARK: - Radial-specific Haptics
    
    func trigger(_ type: RadialHapticType) {
        switch type.style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .rigid:
            impactRigid.impactOccurred()
        case .soft:
            impactLight.impactOccurred(intensity: 0.5)
        @unknown default:
            impactMedium.impactOccurred()
        }
    }
    
    // MARK: - Mechanical Dial Tick
    
    /// Creates a precise "tick" feeling like rotating a mechanical dial
    func dialTick() {
        impactRigid.impactOccurred(intensity: 0.7)
    }
    
    // MARK: - Selection Change
    
    func selection() {
        selectionGenerator.selectionChanged()
    }
}
