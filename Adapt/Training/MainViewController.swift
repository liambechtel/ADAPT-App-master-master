//
//  MainViewController.swift
//  Adapt
//
//  Created by Timmy Gouin on 12/13/17.
//  Copyright © 2017 Timmy Gouin. All rights reserved.
//

import UIKit
//import CoreLocation

class MainViewController: UIViewController /*, CLLocationManagerDelegate */{
    @IBOutlet weak var bullseyeView: UIImageView!
    @IBOutlet weak var pointView: UIImageView!
    @IBOutlet weak var pointY: NSLayoutConstraint!
    @IBOutlet weak var pointX: NSLayoutConstraint!
    @IBOutlet weak var rollPointView: UIImageView!
    @IBOutlet weak var rollPointX: NSLayoutConstraint!
    @IBOutlet weak var rollPointY: NSLayoutConstraint!
    @IBOutlet weak var startTrainingButton: UIButton!
    
    
    // movement sensitivity
    static var EULER_SCALAR: CGFloat = 16
    var tareOffset: CGPoint = CGPoint(x: 0, y: 0)
    var tareOffsetX: CGFloat = 0
    var tareOffsetY: CGFloat = 0
    var lastRoll: CGFloat = 0
    var lastHeading: CGFloat = 0
    var lastEuler = Euler(yaw: 0, pitch: 0, roll: 0)
    var currentTraining: Training?
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
    @IBAction func tarePressed(_ sender: Any) {
        tareOffsetX = -CGFloat(lastEuler.roll) * MainViewController.EULER_SCALAR
        tareOffsetY = -CGFloat(lastEuler.pitch) * MainViewController.EULER_SCALAR
    }
    
    @IBOutlet weak var debugSensorDataView: UITextView!
    //var locationManager:CLLocationManager = CLLocationManager()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white 
        //locationManager.delegate = self
        //locationManager.startUpdatingHeading()
        
        timerLabel.text = "\(currentTraining!.duration) Seconds"
        countdownLabel.text = "\(countdownSeconds)"
        countdownLabel.layer.isHidden = true
        let nc = NotificationCenter.default
        nc.addObserver(forName:Notification.Name(rawValue:"DeviceData"),
                       object:nil, queue:nil) { notification in
                        //guard let quaternion = notification.object as? Quaternion else { return }
                        guard let euler = notification.object as? Euler else { return }
                        
                        
                        
                        if (self.timerRunning) {
                            self.lastEuler = euler
                            let newX = (-CGFloat(euler.roll) * MainViewController.EULER_SCALAR - self.tareOffsetX) / MainViewController.EULER_SCALAR
                            let newY = -(-CGFloat(euler.pitch) * MainViewController.EULER_SCALAR - self.tareOffsetY) / MainViewController.EULER_SCALAR
                            
                            self.pointX.constant = newX * MainViewController.EULER_SCALAR
                            self.pointY.constant = -newY * MainViewController.EULER_SCALAR
                            let rollString = String(format: "%.1f", newX)
                            let pitchString = String(format: "%.1f", newY)
                            var trainingString = ""
                            self.runningTotal.x += newX
                            self.runningTotal.y += newY
                            self.data.append(CGPoint(x: newX, y: newY))
                            let score = self.getScore(x: newX, y: newY)
                            let average = self.getAverage()
                            let averageXString = String(format: "%.1f", average.x)
                            let averageYString = String(format: "%.1f", average.y)
                            trainingString = self.timerRunning ? "\nAverage X: \(averageXString)\nAverage Y: \(averageYString)\nScore: \(score)" : ""
                            self.totalSamples += 1
                            
                            self.debugSensorDataView.text = "\nX: \(rollString)°\nY: \(pitchString)°\(trainingString)"
                        }

                        //self.lastRoll = -(CGFloat(euler.yaw) * .pi / 160) + self.lastHeading - (.pi/8)
                        //self.setRollPointPosition(angle: self.lastRoll)
                        self.view.layoutIfNeeded()
                        
        }
        MainViewController.drawCircle(imageView: bullseyeView)
        MainViewController.drawPoint(imageView: pointView)

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
        /* I THINK THIS LINE SHOULD BE DELETED *******************************
        if let sensorTile = appDelegate.bleController.sensorTile {
            appDelegate.bleController.centralManager.cancelPeripheralConnection(sensorTile)
        }
        */
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let viewController = storyBoard.instantiateViewController(withIdentifier: "reviewTrainingViewController") as! ReviewTrainingViewController
        let dict = NSMutableArray()
        for i in 0..<data.count {
            dict.add([ "x": data[i].x, "y" : data[i].y ])
        }
        currentTraining?.data = dict as NSObject
        currentTraining?.score = Float(getScore(x: 100, y: 100))
        currentTraining?.biasPoint = getAverage() as NSObject
        
        // DO WE STILL WANT TO SAVE TRAININGS AT THIS STAGE???? *************************
        if let _ = currentTraining {
            do {
                try appDelegate.dataController.managedObjectContext.save()
            } catch {
                print ("failed to save training data")
            }
        }
        //***********************************************************************
        viewController.currentTraining = currentTraining
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func tapChooseDevice(_ sender: Any) {
        performSegue(withIdentifier: "connectToSensor2", sender: nil)
    }
    
//    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
//        self.lastHeading = CGFloat(newHeading.magneticHeading) * .pi / 180;
//        print("Roll from iPad: \(newHeading.magneticHeading), Roll from WeSU: \(self.lastRoll)")
//    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func drawCircle(imageView: UIImageView) {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 324, height: 324))
        let img = renderer.image { ctx in
            ctx.cgContext.setFillColor(Colors.creamCityCream.cgColor)
            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            ctx.cgContext.setLineWidth(0.5)
            
            let offset: CGFloat = 12
            
            let outerRectangle = CGRect(x: offset, y: offset, width: 300, height: 300)
            ctx.cgContext.addEllipse(in: outerRectangle)
            ctx.cgContext.setShadow(offset: CGSize.init(width: 0, height: 0), blur: 10)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            
            let midRectangle = CGRect(x: 37.5 + offset, y: 37.5 + offset, width: 225, height: 225)
            ctx.cgContext.addEllipse(in: midRectangle)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            
            let innerRectangle = CGRect(x: 75 + offset, y: 75 + offset, width: 150, height: 150)
            ctx.cgContext.addEllipse(in: innerRectangle)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            let innermostRectangle = CGRect(x: 112.5 + offset, y: 112.5 + offset, width: 75, height: 75)
            ctx.cgContext.addEllipse(in: innermostRectangle)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            ctx.cgContext.addLines(between: [CGPoint(x: 0 + offset, y: 150 + offset), CGPoint(x: 300 + offset, y: 150 + offset)])
            ctx.cgContext.drawPath(using: .fillStroke)
            ctx.cgContext.addLines(between: [CGPoint(x: 150 + offset, y: 0 + offset), CGPoint(x: 150 + offset, y: 300 + offset)])
            ctx.cgContext.drawPath(using: .fillStroke)
            
        }
        imageView.image = img
        imageView.alpha = 0.9
    }
    
    static func drawPoint(imageView: UIImageView) {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let img = renderer.image { ctx in
            ctx.cgContext.setFillColor(Colors.goodLandGreen.cgColor)
            ctx.cgContext.setShadow(offset: CGSize.init(width: 0, height: 0), blur: 10)
            
            let outerRectangle = CGRect(x: 0, y: 0, width: 10, height: 10)
            ctx.cgContext.addEllipse(in: outerRectangle)
            ctx.cgContext.drawPath(using: .fill)
        }
        imageView.image = img
    }
    func drawRollPoint() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let img = renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.blue.cgColor)
            ctx.cgContext.setShadow(offset: CGSize.init(width: 0, height: 0), blur: 10)
            let outerRectangle = CGRect(x: 0, y: 0, width: 10, height: 10)
            ctx.cgContext.addEllipse(in: outerRectangle)
            ctx.cgContext.drawPath(using: .fill)
        }
        rollPointView.image = img
    }
    
    func setPointPosition(magnitude: CGFloat, angle: CGFloat) {
        self.pointX.constant = 147.5 * magnitude * cos(angle)
        self.pointY.constant = -147.5 * magnitude * sin(-angle)
        self.view.layoutIfNeeded()
    }
    
    func setRollPointPosition(angle: CGFloat) {
        self.rollPointX.constant = 325 * cos(-angle)
        self.rollPointY.constant = 325 * sin(-angle)
        self.view.layoutIfNeeded()
    }
    
    @IBAction func unwindToMainViewController(unwindSegue: UIStoryboardSegue) {
        
    }
}
