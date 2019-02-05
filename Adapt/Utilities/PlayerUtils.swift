//
//  Player.swift
//  Adapt
//
//  Created by Timmy Gouin on 2/11/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation
import UIKit

class PlayerUtils {
    static var MAX_IMAGE_SIZE = 600;
    
    static func parseHeight(heightString: String) -> Int16 {
        var height: Int16 = 0
        let containsFeetSymbol = heightString.contains("'")
        let containsInchesSymbol = heightString.contains("\"")
        if containsFeetSymbol {
            let feetSplit = heightString.split(separator: "'");
            if (feetSplit.count > 0) {
                let feet = Int16(feetSplit[0])
                if let unwrappedFeet = feet {
                    height += 12 * unwrappedFeet
                }
                if containsInchesSymbol && feetSplit.count > 1 {
                    let inchesSplit = feetSplit[1].split(separator: "\"")
                    if (inchesSplit.count > 0) {
                        let inches = Int16(inchesSplit[0])
                        if let unwrappedInches = inches {
                            height += unwrappedInches
                        }
                    }
                }
            }
        } else {
            let inches = Int16(heightString)
            if let unwrappedInches = inches {
                height += unwrappedInches
            }
        }
        return height
    }
    
    static func getHeightString(height: Int16) -> String {
        let feet = height / 12;
        let inches = height - (feet * 12)
        return "\(feet)'\(inches)\""
    }
    
    static func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect( x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
