//
//  BaseType.swift
//  Adapt
//
//  Created by Timmy Gouin on 2/11/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation

enum BaseType: Int {
    case Easy = 0
    case Medium = 1
    case Hard = 2
    case Measurement = 3
    
    static func toString(baseType: BaseType) -> String {
        switch(baseType) {
        case BaseType.Easy:
            return "Easy"
        case BaseType.Medium:
            return "Medium"
        case BaseType.Hard:
            return "Hard"
        case BaseType.Measurement:
            return "Measurement"
        }
    }
    
    static func count() -> Int {
        // NOTE: this should be the last enum value and will need to be updated with changes
//        print("HASHVALUE:")
//        print(BaseType.Measurement.rawValue + 1)
        return BaseType.Measurement.rawValue + 1
//        return 4
    
    }
}
