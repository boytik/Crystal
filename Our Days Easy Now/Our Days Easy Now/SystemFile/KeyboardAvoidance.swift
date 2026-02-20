// KeyboardAvoidance.swift
// Our Days: Easy Now
// Ensures TextFields scroll into view when keyboard appears (iPhone SE, small screens)

import SwiftUI

// MARK: - Keyboard Avoidance Modifier

struct KeyboardAwareModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(.interactively)
    }
}

extension View {
    /// Apply to ScrollView with TextFields — enables interactive keyboard dismiss
    func keyboardAware() -> some View {
        modifier(KeyboardAwareModifier())
    }
}
