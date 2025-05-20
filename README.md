# MotionSynth 

**Map accelerometer/gyroscope patterns to Core Haptics parameters in real-time. Turn device shakes, twists, and taps into rich haptic feedback with no math grind.**

MotionSynth simplifies the process of adding responsive, motion-driven haptic feedback to your iOS applications. It abstracts away the complexities of Core Motion data processing and Core Haptics engine management, allowing you to define intuitive mappings between device movements and haptic responses.

## Features 

*   **Predefined Gesture Detection:**
    *   `.shake(threshold: Double)`: Detects device shakes based on G-force.
    *   `.twist(axis: MotionAxis, rateThreshold: Double)`: Detects quick rotations around X, Y, or Z axes.
    *   `.deviceTap(threshold: Double)`: Detects sharp impacts on the device body.
    *   `.flipOver`: Detects when the device is flipped from face-up to face-down or vice-versa.
*   **Predefined Haptic Effects:**
    *   `.tap(intensity: Float, sharpness: Float)`: A single, transient haptic tap.
    *   `.buzz(intensity: Float, sharpness: Float, duration: TimeInterval)`: A short, continuous haptic buzz.
*   **Simple Mapping API:** Easily link a detected gesture to a haptic effect.
*   **Automatic Core Motion & Core Haptics Management:** Handles sensor data fetching and haptic engine setup/playback internally.
*   **Per-Gesture Debouncing:** Prevents rapid re-triggering of haptics for the same gesture.
*   **Lightweight and Easy to Integrate:** Add meaningful physical feedback with minimal code.

## Requirements

*   iOS 13.0+ (due to Core Haptics)
*   Swift 5.3+

## Installation

MotionSynth is available through Swift Package Manager.

1.  In Xcode, select **File > Add Packages...**
2.  Enter the repository URL: `https://github.com/leekiereloo/MotionSynth.git` 
3.  Choose the version rules (e.g., "Up to Next Major Version" starting from `0.1.0`).
4.  Add the `MotionSynth` library to your app's target.

Or, add it to your `Package.swift` dependencies:
```swift
dependencies: [
    .package(url: "https://github.com/leekiereloo/MotionSynth.git", from: "0.1.0") 
]
```

## Basic Usage

```swift
import UIKit
import MotionSynth

class MyViewController: UIViewController {

    let motionSynth = MotionSynth()
    // Optional: UI for feedback
    // @IBOutlet weak var feedbackLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Map gestures to haptic effects
        motionSynth.mapGesture(
            .shake(threshold: 1.8), // G-force
            toHaptic: .tap(intensity: 0.7, sharpness: 0.7)
        )

        motionSynth.mapGesture(
            .twist(axis: .z, rateThreshold: 3.0), // Radians per second
            toHaptic: .buzz(intensity: 0.8, sharpness: 0.8, duration: 0.15)
        )

        motionSynth.mapGesture(
            .deviceTap(threshold: 3.0), // G-force for tap impact
            toHaptic: .tap(intensity: 1.0, sharpness: 1.0)
        )

        motionSynth.mapGesture(
            .flipOver,
            toHaptic: .buzz(intensity: 0.6, sharpness: 0.5, duration: 0.3)
        )

        // 2. Start MotionSynth
        do {
            try motionSynth.start()
            print("MotionSynth started successfully!")
            // feedbackLabel?.text = "MotionSynth Active. Shake, Twist, Tap, or Flip!"
        } catch MotionSynthError.hapticsNotSupported {
            print("Haptics are not supported on this device.")
            // feedbackLabel?.text = "Haptics not supported."
        } catch {
            print("Failed to start MotionSynth: \(error.localizedDescription)")
            // feedbackLabel?.text = "Error: \(error.localizedDescription)"
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // It's good practice to restart if it might have been stopped,
        // or if your app's logic requires it to be active when this view appears.
        // This depends on how you manage its lifecycle across your app.
        // For simple cases, starting in viewDidLoad and stopping in viewWillDisappear is fine.
        if !motionSynth.isRunning { // Assuming an 'isRunning' public property exists or similar check
             do {
                 try motionSynth.start()
             } catch {
                 print("Failed to restart MotionSynth: \(error)")
             }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 3. Stop MotionSynth when the view is no longer active or feedback isn't needed
        motionSynth.stop()
        print("MotionSynth stopped.")
    }
}
```

Important: Haptic feedback will only work on physical iOS devices that support Core Haptics (generally iPhone 8 or later). It will not work on simulators.

## API Reference
### MotionSynth Class
- `init()`: Creates a new MotionSynth instance.
- `mapGesture(_ gesture: MotionGesture, toHaptic haptic: HapticEffect)`: Maps a specific gesture to trigger a haptic effect.
- `start() throws`: Prepares and starts the motion detection and haptic engine. Throws MotionSynthError on failure (e.g., haptics not supported).
- `stop()`: Stops motion detection and releases haptic engine resources.
- `isRunning: Bool` (Read-only, example of a potential public property for state checking): Indicates if MotionSynth is currently active.

### `MotionGesture` Enum
Defines the detectable motion gestures:
- `.shake(threshold: Double)`
- `.twist(axis: MotionAxis, rateThreshold: Double)`
- `.deviceTap(threshold: Double)`
- `.flipOver`

### `MotionAxis` Enum
Used with .twist gesture:
- .x
- .y
- .z

### `HapticEffect` Enum
Defines the playable haptic effects:
- .tap(intensity: Float, sharpness: Float)
- .buzz(intensity: Float, sharpness: Float, duration: TimeInterval)

### `MotionSynthError` Enum
Possible errors thrown by MotionSynth:
- .hapticsNotSupported
- .engineNotPrepared
- .engineCreationFailed(Error?)
- .engineStartFailed(Error?)
- .patternOrPlayerCreationFailed(Error?)
  
## Background Operation
By default, MotionSynth (like Core Motion and Core Haptics) will cease to function reliably when your app is backgrounded or the device is locked. This is due to iOS power-saving and resource management policies.

If your application requires motion detection or haptics to operate in the background, you must:
- Configure the appropriate Background Modes capability in your app's target settings (e.g., "Location updates," "Audio").
- Provide a clear user-facing justification for this background activity, as per Apple's App Store Review Guidelines.
- Manage the MotionSynth lifecycle (start()/stop()) in your app's lifecycle methods (applicationDidBecomeActive, applicationWillResignActive, etc.) according to your background strategy.
- MotionSynth itself does not manage background execution permissions.

## Future Enhancements (Roadmap Ideas)
- Dynamic Parameter Mapping: Allow motion intensity (e.g., shake strength) to directly control haptic parameters (e.g., tap intensity) in real-time.
- More Predefined Gestures: Such as specific tilts, throws, or circular motions.
- More Predefined Haptics: Rumbles, multi-tap patterns, rhythmic effects.
- Support for Custom AHAP Files: Play Apple Haptic and Audio Pattern files.
- Advanced Configuration: Finer control over detector sensitivity and filtering.

## Contributing
Contributions are welcome! If you have ideas for improvements, new gestures, or bug fixes, please feel free to:

1. Fork the repository.
2. Create a new feature branch (git checkout -b feature/your-feature-name).
3. Commit your changes (git commit -am 'Add some feature').
4. Push to the branch (git push origin feature/your-feature-name).
5. Open a new Pull Request.
Please ensure your code adheres to the existing style and includes tests where appropriate.

## License
MotionSynth is released under the MIT license. See LICENSE for details.
