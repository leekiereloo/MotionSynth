//
//  ViewController.swift
//  MotionSynthDemo
//
//  Created by Anastasiia Bespalova on 19.05.25.
//

import UIKit
import MotionSynth // Import your package

class ViewController: UIViewController {

    // Optional: UI element to give some feedback
    @IBOutlet weak var statusLabel: UILabel!

    let motionSynth = MotionSynth()

    override func viewDidLoad() {
            super.viewDidLoad()
            setupStatusLabel()

            // --- Shake ---
            motionSynth.mapGesture(
                .shake(threshold: 1.8),
                toHaptic: .tap(intensity: 0.7, sharpness: 0.7)
            )

            // --- Twist ---
            // Twist around Z-axis (like spinning a plate flat on a table)
            motionSynth.mapGesture(
                .twist(axis: .z, rateThreshold: 3.0), // 3.0 rad/s is a moderate twist
                toHaptic: .buzz(intensity: 0.8, sharpness: 0.8, duration: 0.15)
            )
            // Twist around Y-axis (like turning a doorknob, or phone rotating screen up/down quickly while portrait)
             motionSynth.mapGesture(
                 .twist(axis: .y, rateThreshold: 3.5),
                 toHaptic: .tap(intensity: 0.6, sharpness: 1.0)
             )

            // --- Device Tap ---
            // This is sensitive and might trigger from setting the phone down firmly.
            motionSynth.mapGesture(
                .deviceTap(threshold: 0.5), 
                toHaptic: .tap(intensity: 1.0, sharpness: 1.0)
            )

            // --- Flip Over ---
            motionSynth.mapGesture(
                .flipOver,
                toHaptic: .buzz(intensity: 0.6, sharpness: 0.5, duration: 0.3)
            )

            do {
                try motionSynth.start()
                statusLabel?.text = "MotionSynth Active!\nShake, Twist, Tap, or Flip."
            } catch MotionSynthError.hapticsNotSupported {
                statusLabel?.text = "Haptics not supported."
            } catch {
                statusLabel?.text = "Error: \(error.localizedDescription)"
            }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            motionSynth.stop()
        }


    // --- Optional UI Setup ---
    func setupStatusLabel() {
        if statusLabel == nil { // If not connected via Storyboard
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 18)
            view.addSubview(label)

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
            ])
            self.statusLabel = label
        }
        statusLabel?.text = "Initializing MotionSynth..."
    }
}
