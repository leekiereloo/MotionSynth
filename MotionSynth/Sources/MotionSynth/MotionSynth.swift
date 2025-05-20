// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import CoreMotion // For motion data types if needed directly, though mostly encapsulated



internal struct DeviceMotionData {
    let userAcceleration: CMAcceleration
    let rotationRate: CMRotationRate
    let attitude: CMAttitude // For orientation, e.g., flip detection
}

// (DeviceMotionData struct defined earlier here or in a separate internal file)

public class MotionSynth {

    private let motionDetector: MotionDetector
    private let hapticPlayer: HapticPlayer

    private var activeMappings: [(gesture: MotionGesture, effect: HapticEffect)] = []
    private var isRunning: Bool = false

    // Debounce mechanism
    private var lastHapticPlayTime: [MotionGesture: Date] = [:] // Per-gesture debounce
    private let hapticDebounceInterval: TimeInterval = 0.5 // Default debounce

    // State for flipOver detection
    private var previousIsFaceUp: Bool? = nil
    private let flipDetectionPitchThreshold: Double = .pi / 4.0 // 45 degrees

    public init() {
        self.motionDetector = MotionDetector()
        self.hapticPlayer = HapticPlayer()

        self.motionDetector.onSignificantMotion = { [weak self] motionData in
            self?.handleSignificantMotion(motionData)
        }
    }

    public func mapGesture(_ gesture: MotionGesture, toHaptic haptic: HapticEffect) {
        activeMappings.append((gesture, haptic))
        if case .flipOver = gesture, previousIsFaceUp == nil, isRunning {
             // Initialize flip state if mapping is added while running
            // This requires access to initial motion data, might be better to do on first motion update
            // For now, we'll initialize it on the first relevant motion data received.
        }
    }

    public func start() throws {
        guard !isRunning else { return }
        try hapticPlayer.prepare()
        motionDetector.startMonitoring(updateInterval: 0.05) // 20Hz, good for gestures
        isRunning = true
        previousIsFaceUp = nil // Reset flip state on start
    }

    public func stop() {
        guard isRunning else { return }
        motionDetector.stopMonitoring()
        hapticPlayer.stop()
        isRunning = false
        previousIsFaceUp = nil // Clear state
    }

    private func handleSignificantMotion(_ motionData: DeviceMotionData) {
        guard isRunning else { return }

        // Initialize flip state on first valid motion data if a flipOver mapping exists
        if previousIsFaceUp == nil && activeMappings.contains(where: { $0.gesture == .flipOver }) {
            previousIsFaceUp = motionData.attitude.pitch < flipDetectionPitchThreshold && motionData.attitude.pitch > -flipDetectionPitchThreshold
        }


        for mapping in activeMappings {
            // Per-gesture debouncing
            if let lastPlay = lastHapticPlayTime[mapping.gesture],
               Date().timeIntervalSince(lastPlay) < debounceInterval(for: mapping.gesture) {
                continue // Still in debounce period for this specific gesture
            }

            if checkMatch(for: mapping.gesture, with: motionData) {
                do {
                    try hapticPlayer.play(mapping.effect)
                    lastHapticPlayTime[mapping.gesture] = Date()
                    break // Play first match
                } catch {
                    print("MotionSynth: Error playing haptic effect: \(error)")
                }
            }
        }
    }
    
    private func debounceInterval(for gesture: MotionGesture) -> TimeInterval {
        switch gesture {
        case .deviceTap:
            return 0.2 // Shorter debounce for taps
        case .flipOver:
            return 1.0 // Longer debounce for flips
        default:
            return hapticDebounceInterval // Default debounce
        }
    }


    private func checkMatch(for gesture: MotionGesture, with data: DeviceMotionData) -> Bool {
        switch gesture {
        case .shake(let threshold):
            let magnitudeSquared = (data.userAcceleration.x * data.userAcceleration.x) +
                                   (data.userAcceleration.y * data.userAcceleration.y) +
                                   (data.userAcceleration.z * data.userAcceleration.z)
            return magnitudeSquared > (threshold * threshold)

        case .twist(let axis, let rateThreshold):
            let rate: Double
            switch axis {
            case .x: rate = data.rotationRate.x
            case .y: rate = data.rotationRate.y
            case .z: rate = data.rotationRate.z
            }
            return abs(rate) > rateThreshold

        case .deviceTap(let threshold):
            // Tap detection is tricky. This is a very basic implementation.
            // It looks for a sharp spike in user acceleration.
            // More robust detection might involve analyzing the signal over a very short window,
            // looking for a specific waveform (sharp rise, quick fall).
            let magnitudeSquared = (data.userAcceleration.x * data.userAcceleration.x) +
                                   (data.userAcceleration.y * data.userAcceleration.y) +
                                   (data.userAcceleration.z * data.userAcceleration.z)
            // For taps, we are interested in high magnitude, not sustained.
            // User acceleration is already gravity compensated.
            return magnitudeSquared > (threshold * threshold)

        case .flipOver:
            // Pitch: Rotation around the device's X-axis (earpiece to bottom).
            // 0 when flat face up/down. +/- PI/2 when vertical. +/- PI when upside down relative to start.
            // Assuming "face up" is roughly pitch between -PI/4 and PI/4
            // And "face down" is roughly pitch > PI * 3/4 or < -PI * 3/4 (or |pitch| > some value like 2.5 radians)
            // Let's define face up as pitch within +/- 45 deg (PI/4) from horizontal.
            // And face down as pitch beyond +/- 135 deg (3PI/4) from horizontal.
            // More simply: track if it crosses the "mostly flat" threshold significantly.

            let currentPitch = data.attitude.pitch // Radians. Ranges roughly -PI/2 (portrait top up) to PI/2 (portrait bottom up) when device is vertical. When flat, near 0.
                                                // When flipped completely over on a table, pitch goes towards +/- PI.

            let isCurrentlyFaceUp = currentPitch < flipDetectionPitchThreshold && currentPitch > -flipDetectionPitchThreshold // e.g. within +/- 45 degrees from flat

            guard let wasFaceUp = previousIsFaceUp else {
                // State not initialized yet, or just initialized in handleSignificantMotion
                // We will initialize it there based on the first reading.
                // For the first checkMatch call, if previousIsFaceUp is still nil, don't trigger.
                // The actual initialization happens in handleSignificantMotion on the first data packet.
                return false
            }

            var didFlip = false
            // Check for transition from face up to face down OR face down to face up
            if wasFaceUp && !isCurrentlyFaceUp && abs(currentPitch) > (.pi / 2 + flipDetectionPitchThreshold) { // Transitioned from face up to significantly not face up (e.g. past vertical, towards face down)
                didFlip = true
            } else if !wasFaceUp && isCurrentlyFaceUp { // Transitioned from face down (or significantly not face up) to face up
                didFlip = true
            }
            
            if didFlip {
                self.previousIsFaceUp = isCurrentlyFaceUp // Update state *after* detecting the flip
                return true
            }
            // Update state if no flip detected, but stable state changed slightly
            // (e.g. from very face up to slightly less face up but still face up)
            if self.previousIsFaceUp != isCurrentlyFaceUp {
                 self.previousIsFaceUp = isCurrentlyFaceUp
            }
            return false
        }
    }

    deinit {
        stop()
    }
}
