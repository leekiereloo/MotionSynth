//
//  File.swift
//  MotionSynth
//
//  Created by Anastasiia Bespalova on 19.05.25.
//

import Foundation
import CoreMotion

internal class MotionDetector {
    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()

    var onSignificantMotion: ((DeviceMotionData) -> Void)?

    init() {
        operationQueue.name = "com.motionsynth.motiondetectorqueue"
        operationQueue.maxConcurrentOperationCount = 1 // Process updates serially
    }

    func startMonitoring(updateInterval: TimeInterval = 0.05) { // 20 Hz
        guard motionManager.isDeviceMotionAvailable else {
            print("MotionSynth: Device Motion not available.")
            // Consider throwing an error or notifying the main class
            return
        }

        motionManager.deviceMotionUpdateInterval = updateInterval

        // Using CMDeviceMotion as it provides userAcceleration, rotationRate, and attitude
        motionManager.startDeviceMotionUpdates(to: operationQueue) { [weak self] (deviceMotion, error) in
            guard let self = self, let motion = deviceMotion else {
                if let error = error {
                    print("MotionSynth: Error receiving device motion data: \(error.localizedDescription)")
                    // Potentially stop monitoring or attempt to recover
                }
                return
            }

            let motionSynthData = DeviceMotionData(
                userAcceleration: motion.userAcceleration,
                rotationRate: motion.rotationRate,
                attitude: motion.attitude
            )
            self.onSignificantMotion?(motionSynthData)
        }
    }

    func stopMonitoring() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }

    deinit {
        stopMonitoring()
    }
}
