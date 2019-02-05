//
//  Euler.swift
//  Target_MB
//
//  Created by Timmy Gouin on 1/15/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation

class Euler: NSObject {
    var yaw: Double
    var pitch: Double
    var roll: Double
    init(yaw: Double, pitch: Double, roll: Double) {
        self.yaw = yaw
        self.pitch = pitch
        self.roll = roll
    }
}

//class EulerCHEST: NSObject {
//    var yaw: Double
//    var pitch: Double
//    var roll: Double
//    init(yaw: Double, pitch: Double, roll: Double) {
//        self.yaw = yaw
//        self.pitch = pitch
//        self.roll = roll
//    }
//}
