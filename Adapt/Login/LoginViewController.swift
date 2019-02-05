//
//  LoginViewController.swift
//  Adapt
//
//  Created by Timmy Gouin on 1/15/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet weak var adaptLabel: UILabel!
    @IBOutlet weak var adaptImage: UIImageView!
    @IBOutlet weak var welcomeButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let glowColor = UIColor.white
//        self.adaptLabel.layer.shadowColor = glowColor.cgColor
//        self.adaptLabel.layer.shadowRadius = 10.0
//        self.adaptLabel.layer.shadowOpacity = 1.0
//        self.adaptLabel.layer.shadowOffset = CGSize(width: 0, height: 0)
//        self.adaptLabel.layer.masksToBounds = false
//
//        self.adaptImage.layer.shadowColor = glowColor.cgColor
//        self.adaptImage.layer.shadowRadius = 8.0
//        self.adaptImage.layer.shadowOpacity = 0.8
//        self.adaptImage.layer.shadowOffset = CGSize(width: 0, height: 0)
//        self.adaptImage.layer.masksToBounds = false
        
        self.welcomeButton.layer.shadowColor = glowColor.cgColor
        self.welcomeButton.layer.shadowRadius = 7.0
        self.welcomeButton.layer.shadowOpacity = 0.8
        self.welcomeButton.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.welcomeButton.layer.masksToBounds = false
        
    }
}


