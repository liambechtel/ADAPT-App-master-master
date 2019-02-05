//
//  CalibrationViewController.swift
//  Adapt
//
//  Created by Josh Altabet on 1/31/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import CoreBluetooth

class CalibrationViewController: UIViewController, CLLocationManagerDelegate {
    
    var currentTraining: Training?
    var lastEuler: Euler = Euler(yaw: 0, pitch: 0, roll: 0)
    var hasReceivedData = false
    var locationManager:CLLocationManager = CLLocationManager()
    var tareOffsetX: CGFloat = 0
    var tareOffsetY: CGFloat = 0
    @IBOutlet weak var sensorAnglesLabel: UILabel!
    static var EULER_SCALAR: CGFloat = 16
    
    @IBOutlet weak var calibrateDescription: UILabel!
    @IBOutlet weak var calibrateButton: UIButton!
    @IBOutlet weak var calibrateImage: UIImageView!
    
    @IBAction func calibrateButtonFunc(_ sender: UIButton) {
        calibrate_flag = 1
        tareOffsetX = -CGFloat(lastEuler.roll) * CalibrationViewController.EULER_SCALAR
        tareOffsetY = -CGFloat(lastEuler.pitch) * CalibrationViewController.EULER_SCALAR
        
       if (!hasReceivedData) {
            let noDeviceAlert = UIAlertController(title: "Not Connected", message: "Please turn on the device and make sure Bluetooth is enabled", preferredStyle: UIAlertControllerStyle.alert)
            noDeviceAlert.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.default, handler: { (alertAction) in
                noDeviceAlert.dismiss(animated: true, completion: nil)
            }))
            present(noDeviceAlert, animated: true, completion: nil)
            return
        }
        
        switch currentTraining?.trainingType {
        case Int16(TrainingType.Target.rawValue)?: //Target
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let viewController = storyBoard.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
            viewController.tareOffsetX = tareOffsetX
            viewController.tareOffsetY = tareOffsetY
            viewController.currentTraining = currentTraining
            self.navigationController?.pushViewController(viewController, animated: true)
        case Int16(TrainingType.BarFlexion.rawValue)?: //Bar Front/Back
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let viewController = storyBoard.instantiateViewController(withIdentifier: "OneDBarTrainingViewController") as! OneDBarTrainingViewController
            viewController.tareOffsetX = tareOffsetX
            viewController.tareOffsetY = tareOffsetY
            viewController.currentTraining = currentTraining
            viewController.flexion = true
            self.navigationController?.pushViewController(viewController, animated: true)
        case Int16(TrainingType.BarVersion.rawValue)?: //Bar Left/Right
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let viewController = storyBoard.instantiateViewController(withIdentifier: "OneDBarTrainingViewController") as! OneDBarTrainingViewController
            viewController.tareOffsetX = tareOffsetX
            viewController.tareOffsetY = tareOffsetY
            viewController.currentTraining = currentTraining
            viewController.flexion = false
            self.navigationController?.pushViewController(viewController, animated: true)
        default:
            break
        }
        
        

        
        //performSegue(withIdentifier: "startTraining", sender: nil)
        
    }
    
    override func viewDidLoad() {
        super .viewDidLoad()
        self.calibrateButton.layer.cornerRadius = 10.0
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        if let _ = UserDefaults.standard.string(forKey: BLEController.PERIPHERAL_UUID) {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.bleController.startScan()
            }
        } else {
            performSegue(withIdentifier: "bleDevicesViewController", sender: nil)
        }
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
        let nc = NotificationCenter.default
        nc.addObserver(forName:Notification.Name(rawValue:"SavedDeviceConnecting"),
                       object:nil, queue:nil) { notification in
            self.sensorAnglesLabel.text = "Device found, connecting..."
        }
        
        nc.addObserver(forName:Notification.Name(rawValue:"DeviceData"),
                       object:nil, queue:nil) { notification in
                        //guard let quaternion = notification.object as? Quaternion else { return }
                        guard let euler = notification.object as? Euler else { return }
                        self.hasReceivedData = true
                        self.lastEuler = euler
                        let newX = -CGFloat(euler.roll) * MainViewController.EULER_SCALAR
                        let newY = -CGFloat(euler.pitch) * MainViewController.EULER_SCALAR
                        let rollString = String(format: "%.1f", newX / MainViewController.EULER_SCALAR)
                        let pitchString = String(format: "%.1f", newY / MainViewController.EULER_SCALAR)
                        self.sensorAnglesLabel.text = "Sensor Data\nX: \(rollString)°\nY: \(pitchString)°"
                        //self.lastRoll = -(CGFloat(euler.yaw) * .pi / 160) + self.lastHeading - (.pi/8)
                        //self.setRollPointPosition(angle: self.lastRoll)
                        self.view.layoutIfNeeded()
                        
        }
        
    }
    
}
