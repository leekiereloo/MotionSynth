//
//  File.swift
//  MotionSynth
//
//  Created by Anastasiia Bespalova on 19.05.25.
//

import Foundation

public enum MotionSynthError: LocalizedError {
    case hapticsNotSupported
    case engineNotPrepared
    case engineCreationFailed(Error?)
    case engineStartFailed(Error?)
    case patternOrPlayerCreationFailed(Error?)
    case motionMonitoringFailed(Error?) // For future use if MotionDetector throws

    public var errorDescription: String? {
        switch self {
        case .hapticsNotSupported:
            return "Haptics are not supported on this device."
        case .engineNotPrepared:
            return "The haptic engine has not been prepared or has been stopped."
        case .engineCreationFailed(let underlyingError):
            return "Failed to create haptic engine. \(underlyingError?.localizedDescription ?? "")"
        case .engineStartFailed(let underlyingError):
            return "Failed to start haptic engine. \(underlyingError?.localizedDescription ?? "")"
        case .patternOrPlayerCreationFailed(let underlyingError):
            return "Failed to create haptic pattern or player. \(underlyingError?.localizedDescription ?? "")"
        case .motionMonitoringFailed(let underlyingError):
            return "Failed to start motion monitoring. \(underlyingError?.localizedDescription ?? "")"
        }
    }
}
