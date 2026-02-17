import UIKit
import CoreHaptics

class Haptics {
    static let shared = Haptics()
    
    private let supportsHaptics: Bool
    
    private init() {
        // Check if the device actually supports haptics (simulators don't)
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard supportsHaptics else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard supportsHaptics else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
