//
//  TrainingType.swift
//  Adapt
//
//  Created by Timmy Gouin on 2/11/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation

enum TrainingType: Int {
    case Target = 0
    case BarFlexion = 1
    case BarVersion = 2
    
    static func toString(trainingType: TrainingType) -> String {
        switch(trainingType) {
        case TrainingType.Target:
            return "Target"
        case TrainingType.BarFlexion:
            return "Bar Front/Back"
        case TrainingType.BarVersion:
            return "Bar Left/Right"
        }
        return "NA"
    }
    
    static func count() -> Int {
        // NOTE: this should be the last enum value and will need to be updated with changes
        return TrainingType.BarVersion.rawValue + 1
//        return 3
    }
}
