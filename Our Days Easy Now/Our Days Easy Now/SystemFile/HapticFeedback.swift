// HapticFeedback.swift
// Our Days: Easy Now
// Tactile feedback for logging, gratitude, and key interactions

import SwiftUI

// MARK: - Haptic Feedback Utility

enum NestHaptics {

    /// Light tap — deed button press, selection
    static func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Medium tap — moment logged, confirmation
    static func mediumTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Success — gratitude sent, badge unlocked
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// Selection changed — picker, tab switch
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    /// Soft tap — gentle nudge dismiss, minor actions
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }
}
