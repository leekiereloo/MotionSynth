//
//  File.swift
//  MotionSynth
//
//  Created by Anastasiia Bespalova on 19.05.25.
//

import Foundation
import CoreHaptics

internal class HapticPlayer {
    private var engine: CHHapticEngine?
    
    init() {}
    
    func prepare() throws {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            throw MotionSynthError.hapticsNotSupported
        }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            // Optional: Set up engine reset handler
            engine?.resetHandler = { [weak self] in
                print("MotionSynth: Haptic engine reset. Attempting to restart.")
                do {
                    try self?.engine?.start()
                } catch {
                    print("MotionSynth: Failed to restart haptic engine: \(error)")
                    // Mark as unprepared or handle appropriately
                }
            }
            
            // Optional: Set up engine stopped handler
            engine?.stoppedHandler = { [weak self] reason in
                print("MotionSynth: Haptic engine stopped for reason: \(reason.rawValue).")
            }
            
        } catch let error {
            throw MotionSynthError.engineCreationFailed(error)
        }
    }
    
    func play(_ effect: HapticEffect) throws {
        guard let engine = engine else {
            // This case should ideally be prevented by ensuring prepare() is called and successful
            // and that MotionSynth doesn't try to play if preparation failed.
            print("MotionSynth Error: Haptic engine is nil. Was prepare() called and successful?")
            throw MotionSynthError.engineNotPrepared
        }
        
        // If the engine stopped or reset, the resetHandler should have attempted a restart.
        // If that failed, or if the engine is in a bad state for other reasons,
        // the calls to makePlayer or player.start() below should throw.
        
        var events: [CHHapticEvent] = []
        let hapticEventParameters = effect.coreHapticEventParameters
        let duration = effect.duration
        
        switch effect {
        case .tap:
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: hapticEventParameters, relativeTime: 0)
            events.append(event)
        case .buzz:
            let event = CHHapticEvent(eventType: .hapticContinuous, parameters: hapticEventParameters, relativeTime: 0, duration: duration)
            events.append(event)
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: []) // No pattern-level dynamic parameters for MVP
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch let error {
            print("MotionSynth: Error creating/playing haptic pattern: \(error)")
            throw MotionSynthError.patternOrPlayerCreationFailed(error)
        }
    }
    
    func stop() {
        engine?.stop(completionHandler: { error in
            if let error = error {
                print("MotionSynth: Error stopping haptic engine: \(error.localizedDescription)")
            }
        })
        engine = nil // Release the engine
    }
    
    deinit {
        stop()
    }
}
