// ReduceMotionModifier.swift
// Our Days: Easy Now
// Respects @Environment(\.accessibilityReduceMotion) — disables particles, spring animations

import SwiftUI

// MARK: - Reduce Motion Animation Helper

extension Animation {
    /// Returns reduced animation when Reduce Motion is enabled
    static func nestReduceMotion(_ preferred: Animation, reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : preferred
    }
}

// MARK: - Conditional Particle View

struct ConditionalParticlesView<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if !reduceMotion {
            content()
        }
    }
}
