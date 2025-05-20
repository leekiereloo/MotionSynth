//
//  File.swift
//  MotionSynth
//
//  Created by Anastasiia Bespalova on 19.05.25.
//

import Foundation

/// Represents the primary axes of motion for the device.
public enum MotionAxis: Equatable, Hashable { // Added Hashable
    case x, y, z
}
