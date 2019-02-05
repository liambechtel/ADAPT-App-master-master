//
//  TrainingSetupCell.swift
//  Adapt
//
//  Created by Josh Altabet on 2/5/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation
import UIKit

class TrainingSetupCell: UIView{
    

    
    override init(frame: CGRect){
        super.init(frame: frame)


    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 2
        self.layer.cornerRadius = 10.0
        
        self.viewWithTag(1)?.layer.cornerRadius = 10
        
        let glowColor = UIColor.white
        self.viewWithTag(3)?.layer.shadowColor = glowColor.cgColor
        self.viewWithTag(3)?.layer.shadowRadius = 10.0
        self.viewWithTag(3)?.layer.shadowOpacity = 1.0
        self.viewWithTag(3)?.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.viewWithTag(3)?.layer.masksToBounds = false
    }
    
    
}
