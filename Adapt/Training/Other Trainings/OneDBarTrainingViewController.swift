//
//  OneDBarTrainingViewController.swift
//  Adapt
//
//  Created by Josh Altabet on 2/14/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class OneDBarTrainingViewController: UIViewController {
    
    @IBOutlet weak var barView: UIImageView!
    @IBOutlet weak var barRectView: UIImageView!
    @IBOutlet weak var pointY: NSLayoutConstraint!
    @IBOutlet weak var pointX: NSLayoutConstraint!
    @IBOutlet weak var sensorDataView: UITextView!
    @IBOutlet weak var barRectWidth: NSLayoutConstraint!
    @IBOutlet weak var barRectHeight: NSLayoutConstraint!
    @IBOutlet weak var barWidth: NSLayoutConstraint!
    @IBOutlet weak var barHeight: NSLayoutConstraint!
    @IBOutlet weak var startTrainingButton: UIButton!
    
    
    static var EULER_SCALAR: CGFloat = 16
    var tareOffset: CGPoint = CGPoint(x: 0, y: 0)
    var tareOffsetX: CGFloat = 0
    var tareOffsetY: CGFloat = 0
    var lastHeading: CGFloat = 0
    var lastEuler = Euler(yaw: 0, pitch: 0, roll: 0)
    
    var currentTraining: Training?
    //var locationManager:CLLocationManager = CLLocationManager()
    var data: [CGPoint] = []
    
    var timer = Timer()
    var timerSeconds: Int32 = 0
    var timerRunning = false
    @IBOutlet weak var timerLabel: UILabel!
    
    var countdownTimer = Timer()
    var countdownSeconds: Int32 = 3
    var countdownRunning = false
    @IBOutlet weak var countdownLabel: UILabel!
    
    var totalSamples:Int32 = 0
    var runningTotal:CGPoint = CGPoint(x: 0, y: 0)
    var runningScore: CGFloat = 0
    
    var flexion: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        //locationManager.delegate = self
        //locationManager.startUpdatingHeading()
        
        timerLabel.text = "\(currentTraining!.duration) Seconds"
        countdownLabel.text = "\(countdownSeconds)"
        countdownLabel.layer.isHidden = true
        
        if self.flexion{
            barRectWidth.constant = 200
            barRectHeight.constant = 700
            barHeight.constant = 10
            barWidth.constant = 200
        }
        else {
            barRectWidth.constant = 700
            barRectHeight.constant = 200
            barHeight.constant = 200
            barWidth.constant = 10
        }
        
        let nc = NotificationCenter.default
        nc.addObserver(forName:Notification.Name(rawValue:"DeviceData"),
                       object:nil, queue:nil) { notification in
                        //guard let quaternion = notification.object as? Quaternion else { return }
                        guard let euler = notification.object as? Euler else { return }
                        
                        
                        
                        if (self.timerRunning) {
                            self.lastEuler = euler
                            var trainingString = ""
                            if self.flexion{
                                let newY = -(-CGFloat(euler.pitch) * MainViewController.EULER_SCALAR - self.tareOffsetY) / MainViewController.EULER_SCALAR
                                self.pointY.constant = -newY * MainViewController.EULER_SCALAR
                                self.runningTotal.y += newY
                                self.runningTotal.x += 0
                                self.data.append(CGPoint(x: 0, y: newY))
   
                                let pitchString = String(format: "%.1f", newY)
                                let average = self.getAverage()
                                let averageString = String(format: "%.1f", average.y)
                                let score = self.getScore(x: 0, y: newY)
                                
                                trainingString = self.timerRunning ? "\nAverage Y: \(averageString)\nScore: \(score)" : ""
                                self.sensorDataView.text = "\nY: \(pitchString)°\(trainingString)"
                            }
                            else{
                                let newX = (-CGFloat(euler.roll) * MainViewController.EULER_SCALAR - self.tareOffsetX) / MainViewController.EULER_SCALAR
                                self.pointX.constant = newX * MainViewController.EULER_SCALAR
                                self.runningTotal.y += 0
                                self.runningTotal.x += newX
                                self.data.append(CGPoint(x: newX, y: 0))
                                
                                let rollString = String(format: "%.1f", newX)
                                let average = self.getAverage()
                                let averageString = String(format: "%.1f", average.x)
                                let score = self.getScore(x: newX, y: 0)
                                
                                trainingString = self.timerRunning ? "\nAverage X: \(averageString)\nScore: \(score)" : ""
                                self.sensorDataView.text = "\nX: \(rollString)°\(trainingString)"
                            }
                            self.totalSamples += 1
                        }
                        
                        self.view.layoutIfNeeded()
                        
        }
            
        OneDBarTrainingViewController.drawBarRect(imageView: barRectView);
        OneDBarTrainingViewController.drawBar(imageView: barView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.countdownSeconds = 3
        timerLabel.text = "\(currentTraining!.duration) Seconds"
        countdownLabel.text = "\(countdownSeconds)"
        
        lastEuler = Euler(yaw: 0, pitch: 0, roll: 0)
        data = []
        totalSamples = 0
        runningTotal = CGPoint(x: 0, y: 0)
        runningScore = 0
        self.pointX.constant = 0
        self.pointY.constant = 0
        self.startTrainingButton.isEnabled = true
    }
    
    
    func getScore(x: CGFloat, y: CGFloat) -> CGFloat {
        let magnitude = sqrt(x * x + y * y)
        var score:CGFloat = 0
        if (magnitude < 5) {
            score = 1.0
            // bullseye
        } else if (magnitude < 10) {
            score = 0.75
        } else if (magnitude < 15) {
            score = 0.5
        } else if (magnitude < 20) {
            score = 0.25
        }
        self.runningScore += score
        var currentScore = CGFloat(round(CGFloat(self.runningScore) * 1000.0 / CGFloat(self.totalSamples))/10.0)
        if (currentScore > 100) {
            currentScore = 100
        }
        return currentScore
    }
    
    func getAverage() -> CGPoint {
        return CGPoint(x: runningTotal.x / CGFloat(totalSamples), y: runningTotal.y / CGFloat(totalSamples))
    }
    
    @IBAction func startTraining(_ sender: Any) {
        countdownRunning = true
        countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(MainViewController.updateCountdownLabel), userInfo: nil, repeats: true)
        countdownLabel.layer.isHidden = false
        self.startTrainingButton.isEnabled = false
    }
    
    func trainingStart(){
        timerRunning = true
        runningTotal.x = 0
        runningTotal.y = 0
        timerSeconds = currentTraining?.duration ?? 0
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(MainViewController.updateTimerLabel), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimerLabel(sender: AnyObject?){
        timerSeconds = timerSeconds - 1
        timerLabel.text = "\(timerSeconds) Seconds"
        if timerSeconds == 0 {
            timer.invalidate()
            trainingEnded()
        }
    }
    
    @objc func updateCountdownLabel(sender: AnyObject?){
        countdownSeconds = countdownSeconds - 1
        countdownLabel.text = "\(countdownSeconds)"
        if countdownSeconds == 0 {
            countdownTimer.invalidate()
            countdownLabel.layer.isHidden = true
            trainingStart()
        }
    }
    
    func trainingEnded() {
        timerRunning = false
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        /*if let sensorTile = appDelegate.bleController.sensorTile {
            appDelegate.bleController.centralManager.cancelPeripheralConnection(sensorTile)
        }*/
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let viewController = storyBoard.instantiateViewController(withIdentifier: "reviewTrainingViewController") as! ReviewTrainingViewController
        let dict = NSMutableArray()
        for i in 0..<data.count {
            dict.add([ "x": data[i].x, "y" : data[i].y ])
        }
        currentTraining?.data = dict as NSObject
        currentTraining?.score = Float(getScore(x: 100, y: 100))
        currentTraining?.biasPoint = getAverage() as NSObject

        if let _ = currentTraining {
            do {
                try appDelegate.dataController.managedObjectContext.save()
            } catch {
                print ("failed to save training data")
            }
        }
        viewController.currentTraining = currentTraining
        self.navigationController?.pushViewController(viewController, animated: true)
    }
  
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func drawBarRect(imageView: UIImageView){
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 174, height: 424))
        let img = renderer.image { ctx in
            ctx.cgContext.setFillColor(Colors.creamCityCream.cgColor)
            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            ctx.cgContext.setLineWidth(0.5)
            
            let offset: CGFloat = 12
            
            let barRectangle  = CGRect(x:offset, y:offset, width: 150, height: 400)
            ctx.cgContext.addRect(barRectangle)
            ctx.cgContext.setShadow(offset: CGSize.init(width: 0, height: 0), blur: 10)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            ctx.cgContext.addLines(between: [CGPoint(x:0+offset, y:200+offset), CGPoint(x:150+offset, y:200+offset)])
            ctx.cgContext.drawPath(using: .fillStroke)
            
        }
        imageView.image = img
        imageView.alpha = 0.9
        
    }
    
    static func drawBar(imageView: UIImageView){
        let renderer = UIGraphicsImageRenderer(size: CGSize(width:150, height: 10 ))
        let img = renderer.image { ctx in
            ctx.cgContext.setFillColor(Colors.goodLandGreen.cgColor)
            ctx.cgContext.setShadow(offset: CGSize.init(width: 0, height: 0), blur: 10)
            
            let offset: CGFloat = 12
            
            let outerRectangle = CGRect(x: 0, y: 0, width: 150, height: 10)
            ctx.cgContext.addRect(outerRectangle)
            ctx.cgContext.drawPath(using: .fill)
        }
        imageView.image = img
    }
    
    func setBarPosition(magnitude: CGFloat, angle: CGFloat) {
        if self.flexion{
            self.pointY.constant = -147.5 * magnitude * sin(-angle)
        }else{
            self.pointX.constant = 147.5 * magnitude * cos(angle)
        }
        self.view.layoutIfNeeded()
        
    }
    
    
}
