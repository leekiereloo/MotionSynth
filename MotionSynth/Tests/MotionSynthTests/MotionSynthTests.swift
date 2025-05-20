
import XCTest
@testable import MotionSynth // @testable to access internal members if needed for testing

final class MotionSynthTests: XCTestCase {

    var motionSynth: MotionSynth!

    override func setUpWithError() throws {
        try super.setUpWithError()
        motionSynth = MotionSynth()
        // Note: For full testing of haptics and motion, you'd need a physical device
        // or more complex mocking of CMMotionManager and CHHapticEngine.
        // These MVP tests will focus on the API and internal state logic where possible.
    }

    override func tearDownWithError() throws {
        motionSynth.stop() // Ensure it's stopped
        motionSynth = nil
        try super.tearDownWithError()
    }

    func testInitialization() {
        XCTAssertNotNil(motionSynth, "MotionSynth instance should be created.")
    }

    func testMapGesture() {
        // Accessing internal activeMappings directly is not ideal for black-box testing,
        // but for an MVP and initial tests, it can verify mapping storage.
        // A better approach would be to simulate motion and check if the correct haptic *would* play.

        motionSynth.mapGesture(.shake(threshold: 2.0), toHaptic: .tap(intensity: 0.5, sharpness: 0.5))
        // How to verify? If activeMappings was public or testable, we could check its count.
        // For now, this test mainly ensures the method doesn't crash.
        // To truly test, you'd need to inject a mock MotionDetector and HapticPlayer.
    }

    func testStartAndStop() {
        // This test is limited without mocking. It checks if methods can be called.
        do {
            // On a simulator or device without haptics, prepare() in HapticPlayer will throw.
            // So, this test might only pass on a haptic-capable device or if HapticPlayer
            // gracefully handles non-support in prepare (which it does by throwing).
            // We can't easily assert internal `isRunning` state without making it testable.

            // To make this testable without a device, you'd inject mock haptic player
            // that doesn't throw. For now, we just call it.
            // On CI, this test might fail if it tries to use real haptics.
            // Consider conditional compilation for tests or robust mocking.
            XCTAssertNoThrow(try motionSynth.start(), "Start should not throw if haptics are supported and motion available.")
            motionSynth.stop()
        } catch MotionSynthError.hapticsNotSupported {
            print("Skipping start/stop test: Haptics not supported on this test environment.")
        } catch {
            XCTFail("Starting MotionSynth failed with unexpected error: \(error)")
        }
    }

    static var allTests = [
        ("testInitialization", testInitialization),
        ("testMapGesture", testMapGesture),
        ("testStartAndStop", testStartAndStop),
    ]
}
