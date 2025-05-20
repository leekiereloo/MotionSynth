//
//  File.swift
//  MotionSynth
//
//  Created by Anastasiia Bespalova on 19.05.25.
//

import Foundation

/// Defines the types of motion gestures that can be detected.
public enum MotionGesture: Equatable, Hashable { // Added Hashable
    /// A shake gesture, detected when the magnitude of user acceleration exceeds a threshold.
    /// - Parameter threshold: The G-force threshold for user acceleration (gravity compensated). E.g., 1.5 means 1.5G.
    case shake(threshold: Double = 1.8)

    /// A quick rotation around a specified axis.
    /// - Parameter axis: The axis of rotation (`.x`, `.y`, or `.z`).
    /// - Parameter rateThreshold: The angular velocity threshold in radians per second.
    case twist(axis: MotionAxis, rateThreshold: Double = 2.5)

    /// A sharp tap or impact on the device body.
    /// This is sensitive and may require tuning.
    /// - Parameter threshold: The G-force threshold for the impact's acceleration.
    case deviceTap(threshold: Double = 2.5)

    /// Detects when the device is flipped over (e.g., from face up to face down, or vice-versa).
    case flipOver
}
