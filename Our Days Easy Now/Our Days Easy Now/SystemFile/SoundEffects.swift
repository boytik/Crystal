// SoundEffects.swift
// Our Days: Easy Now
// System sounds for logging, gratitude — respects nestPreferences.sparkSoundEnabled

import AudioToolbox

enum NestSounds {

    /// Light tap sound — moment logged
    static func playLog() {
        guard HearthVault.shared.nestPreferences.sparkSoundEnabled else { return }
        AudioServicesPlaySystemSound(1104)  // Tink
    }

    /// Success chime — gratitude, badge
    static func playSuccess() {
        guard HearthVault.shared.nestPreferences.sparkSoundEnabled else { return }
        AudioServicesPlaySystemSound(1057)  // Success
    }
}
