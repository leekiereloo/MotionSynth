//
//  File.swift
//  MotionSynth
//
//  Created by Anastasiia Bespalova on 19.05.25.
//

import Foundation
import CoreHaptics // For CHHaptic types

/// Defines the types of haptic effects that can be played.
public enum HapticEffect {
    /// A single, brief haptic tap.
    /// - Parameter intensity: How strong the tap feels (0.0 to 1.0).
    /// - Parameter sharpness: How "crisp" or "dull" the tap feels (0.0 to 1.0).
    case tap(intensity: Float = 0.7, sharpness: Float = 0.7)

    /// A short, continuous haptic buzz.
    /// - Parameter intensity: How strong the buzz feels (0.0 to 1.0).
    /// - Parameter sharpness: How "crisp" or "dull" the buzz feels (0.0 to 1.0).
    /// - Parameter duration: The length of the buzz in seconds.
    case buzz(intensity: Float = 0.7, sharpness: Float = 0.7, duration: TimeInterval = 0.1)

    // Internal helper to get Core Haptics parameters
    internal var coreHapticEventParameters: [CHHapticEventParameter] { // Corrected type to CHHapticEventParameter
        switch self {
        case .tap(let intensity, let sharpness):
            return [
                // CHHapticEventParameter class is initialized directly
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity), // .hapticIntensity is CHHapticEvent.ParameterID
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness) // .hapticSharpness is CHHapticEvent.ParameterID
            ]
        case .buzz(let intensity, let sharpness, _): // Duration is handled by the event itself
            return [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ]
        }
    }

    internal var duration: TimeInterval {
        switch self {
        case .tap:
            return 0.05
        case .buzz(_, _, let duration):
            return duration
        }
    }
}
