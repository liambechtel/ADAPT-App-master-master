//
//  Quaternion.swift
//  Adapt
//
//  Created by Timmy Gouin on 1/15/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation

class Quaternion: NSObject {
    var x: Double
    var y: Double
    var z: Double
    var w: Double
    init(x: Double, y: Double, z: Double, w: Double) {
        self.x = x;
        self.y = y;
        self.z = 0;
        self.w = 0;
    }
}
