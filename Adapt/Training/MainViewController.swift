//
//  MainViewController.swift
//  Adapt
//
//  Created by Timmy Gouin on 12/13/17.
//  Copyright © 2017 Timmy Gouin. All rights reserved.
//

import UIKit
//import CoreLocation
var trainingString1:String=""
var trainingString2:String=""
var data_base: [CGPoint] = []
var data_chest: [CGPoint] = []
var data_chest_velocity: [CGPoint] = []
var base_time:[Double]=[]
var chest_time:[Double]=[]
var chest_velocity_time:[Double]=[]
var initial_time:Double=0.0
var BiasPoint:[CGPoint]=[CGPoint(x:0,y:0),CGPoint(x:0,y:0),CGPoint(x:0,y:0)]
var penalty:[Double]=[0.0,0.0,0.0]
let scalarK:[Double]=[1.5,1.0,0.5]
var score:Double=100.0

class MainViewController: UIViewController /*, CLLocationManagerDelegate */{
    @IBOutlet weak var bullseyeView: UIImageView!
    @IBOutlet weak var pointView: UIImageView!
    @IBOutlet weak var pointY: NSLayoutConstraint!
    @IBOutlet weak var pointX: NSLayoutConstraint!
    @IBOutlet weak var pointView2: UIImageView!
    @IBOutlet weak var pointY2: NSLayoutConstraint!
    @IBOutlet weak var pointX2: NSLayoutConstraint!
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
    
    var timer = Timer()
    var timerSeconds: Int32 = 0
    var timerRunning = false
    @IBOutlet weak var timerLabel: UILabel!
    
    var countdownTimer = Timer()
    var countdownSeconds: Int32 = 3
    var countdownRunning = false
    @IBOutlet weak var countdownLabel: UILabel!
    
    var totalSamples:[Int32] = [0,0,0];
    @IBAction func tarePressed(_ sender: Any) {
        tareOffsetX = -CGFloat(lastEuler.roll) * MainViewController.EULER_SCALAR
        tareOffsetY = -CGFloat(lastEuler.pitch) * MainViewController.EULER_SCALAR
    }
    
    @IBOutlet weak var debugSensorDataView: UITextView!
    //var locationManager:CLLocationManager = CLLocationManager()
    
    func ScoreUpdate(x: CGFloat, y: CGFloat, Sensor_ID: Int)
    {
        //print("Sensor \(Sensor_ID)");
        let magnitude = sqrt(x * x + y * y)
        penalty[Sensor_ID]=(penalty[Sensor_ID]*Double(totalSamples[Sensor_ID]-1)+(scalarK[Sensor_ID] * Double(magnitude)))/Double(totalSamples[Sensor_ID])
        score = 100 - penalty[0]-penalty[1]-penalty[2]
        self.debugSensorDataView.text = "Score:\(round(score))\nPenalty Base:\(round(penalty[0]))\nPenalty Chest:\(round(penalty[1]))\nPenalty Chest Velocity:\(round(penalty[2]))\n"
    }
    
    func FindBiasPoint()
    {
        var sum:CGPoint=CGPoint(x:0,y:0)
        for i in 0..<data_base.count
        {
            sum.x+=data_base[i].x
            sum.y+=data_base[i].y
        }
        BiasPoint[0].x=sum.x/CGFloat(data_base.count)
        BiasPoint[0].y=sum.y/CGFloat(data_base.count)
        sum=CGPoint(x:0,y:0)
        for i in 0..<data_chest.count
        {
            sum.x+=data_chest[i].x
            sum.y+=data_chest[i].y
        }
        BiasPoint[1].x=sum.x/CGFloat(data_chest.count)
        BiasPoint[1].y=sum.y/CGFloat(data_chest.count)
        sum=CGPoint(x:0,y:0)
        for i in 0..<data_chest_velocity.count
        {
            sum.x+=data_chest_velocity[i].x
            sum.y+=data_chest_velocity[i].y
        }
        BiasPoint[2].x=sum.x/CGFloat(data_chest_velocity.count)
        BiasPoint[2].y=sum.y/CGFloat(data_chest_velocity.count)
    }
    
    /*func getAverage(Sensor_ID: Int) -> CGPoint {
        return CGPoint(x: runningTotal[Sensor_ID].x / CGFloat(totalSamples[Sensor_ID]), y: runningTotal[Sensor_ID].y / CGFloat(totalSamples[Sensor_ID]))
    }*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        //locationManager.delegate = self
        //locationManager.startUpdatingHeading()
        
        timerLabel.text = "\(currentTraining!.duration) Seconds"
        countdownLabel.text = "\(countdownSeconds)"
        countdownLabel.layer.isHidden = true
        let nc = NotificationCenter.default
        nc.addObserver(forName:Notification.Name(rawValue:"Sensor_1"),
                       object:nil, queue:nil) { notification in
                        //guard let quaternion = notification.object as? Quaternion else { return }
                        guard let euler = notification.object as? Euler else { return }
                        
                        
                        
                        if (self.timerRunning) {
                            self.lastEuler = euler
                            let Sensor_ID:Int=0
                            let newX = (-CGFloat(euler.roll) * MainViewController.EULER_SCALAR - self.tareOffsetX) / MainViewController.EULER_SCALAR
                            let newY = -(-CGFloat(euler.pitch) * MainViewController.EULER_SCALAR - self.tareOffsetY) / MainViewController.EULER_SCALAR
                            self.pointX.constant = newX * MainViewController.EULER_SCALAR
                            self.pointY.constant = -newY * MainViewController.EULER_SCALAR
                            self.totalSamples[Sensor_ID] += 1
//                            let rollString1 = String(format: "%.1f", newX)
//                            let pitchString1 = String(format: "%.1f", newY)
                            data_base.append(CGPoint(x: newX, y: newY))
                            base_time.append(CACurrentMediaTime()-initial_time)
                            self.ScoreUpdate(x: newX, y: newY,Sensor_ID:Sensor_ID)
//                            trainingString1 = self.timerRunning ? "\nAverage X1: \(averageXString)\nAverage Y1: \(averageYString)\nScore1: \(score)" : ""
                            
                            
//                            self.debugSensorDataView.text = "Sensor Data\nX1: \(rollString1)°  Y1: \(pitchString1)°\(trainingString1)\nX2: \(rollString2)°  Y2: \(pitchString2)°\(trainingString2)"
                        }
                        
                        //self.lastRoll = -(CGFloat(euler.yaw) * .pi / 160) + self.lastHeading - (.pi/8)
                        //self.setRollPointPosition(angle: self.lastRoll)
                        self.view.layoutIfNeeded()
                        sem_packet.signal();
                        
        }
        nc.addObserver(forName:Notification.Name(rawValue:"Sensor_2"),
                       object:nil, queue:nil) { notification in
                        //guard let quaternion = notification.object as? Quaternion else { return }
                        guard let euler = notification.object as? Euler else { return }


                        if (self.timerRunning) {
                            self.lastEuler = euler
                            let Sensor_ID:Int=1
                            let newX = (-CGFloat(euler.roll) * MainViewController.EULER_SCALAR - self.tareOffsetX) / MainViewController.EULER_SCALAR
                            let newY = -(-CGFloat(euler.pitch) * MainViewController.EULER_SCALAR - self.tareOffsetY) / MainViewController.EULER_SCALAR
                            self.pointX.constant = newX * MainViewController.EULER_SCALAR
                            self.pointY.constant = -newY * MainViewController.EULER_SCALAR
//                            let rollString1 = String(format: "%.1f", newX)
//                            let pitchString1 = String(format: "%.1f", newY)
//                            self.runningTotal[Sensor_ID].x += newX
//                            self.runningTotal[Sensor_ID].y += newY
                            data_chest.append(CGPoint(x: newX, y: newY))
                            chest_time.append(CACurrentMediaTime()-initial_time)
                            self.totalSamples[Sensor_ID] += 1
                            self.ScoreUpdate(x: newX, y: newY,Sensor_ID:Sensor_ID)
//                            trainingString2 = self.timerRunning ? "\nAverage X2: \(averageXString)\nAverage Y2: \(averageYString)\nScore2: \(score)\n" : ""

//                            self.debugSensorDataView.text = "Sensor Data\nX1: \(rollString1)°  Y1: \(pitchString1)°\(trainingString1)\nX2: \(rollString2)°  Y2: \(pitchString2)°\(trainingString2)"
                        }

                        //self.lastRoll = -(CGFloat(euler.yaw) * .pi / 160) + self.lastHeading - (.pi/8)
                        //self.setRollPointPosition(angle: self.lastRoll)
                        self.view.layoutIfNeeded()
                        sem_packet.signal();

        }
        nc.addObserver(forName:Notification.Name(rawValue:"Sensor_3"),
                         object:nil, queue:nil) { notification in
                            //guard let quaternion = notification.object as? Quaternion else { return }
                            guard let euler = notification.object as? Euler else { return }
                            
                            
                            if (self.timerRunning) {
                                //print("velocity caught")
                                self.lastEuler = euler
                                let Sensor_ID:Int=2
                                let newX = (-CGFloat(euler.roll) * MainViewController.EULER_SCALAR - self.tareOffsetX) / MainViewController.EULER_SCALAR
                                let newY = -(-CGFloat(euler.pitch) * MainViewController.EULER_SCALAR - self.tareOffsetY) / MainViewController.EULER_SCALAR
                                self.pointX.constant = newX * MainViewController.EULER_SCALAR
                                self.pointY.constant = -newY * MainViewController.EULER_SCALAR
//                                let rollString1 = String(format: "%.1f", newX)
//                                let pitchString1 = String(format: "%.1f", newY)
//                                self.runningTotal[Sensor_ID].x += newX
//                                self.runningTotal[Sensor_ID].y += newY
                                data_chest_velocity.append(CGPoint(x: newX, y: newY))
                                chest_velocity_time.append(CACurrentMediaTime()-initial_time)
                                self.totalSamples[Sensor_ID] += 1
                                self.ScoreUpdate(x: newX, y: newY,Sensor_ID:Sensor_ID)
//                                trainingString2 = self.timerRunning ? "\nAverage X2: \(averageXString)\nAverage Y2: \(averageYString)\nScore2: \(score)\n" : ""
                                
//                                self.debugSensorDataView.text = "Sensor Data\nX1: \(rollString1)°  Y1: \(pitchString1)°\(trainingString1)\nX2: \(rollString2)°  Y2: \(pitchString2)°\(trainingString2)"
                            }
                            
                            //self.lastRoll = -(CGFloat(euler.yaw) * .pi / 160) + self.lastHeading - (.pi/8)
                            //self.setRollPointPosition(angle: self.lastRoll)
                            self.view.layoutIfNeeded()
                            sem_packet.signal();
                            
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
        data_base = []
        data_chest = []
        data_chest_velocity = []
        totalSamples[0] = 0
        totalSamples[1] = 0
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
        data_base = []
        data_chest = []
        data_chest_velocity = []
        base_time=[]
        chest_time=[]
        chest_velocity_time=[]
        initial_time=0.0
        BiasPoint=[CGPoint(x:0,y:0),CGPoint(x:0,y:0),CGPoint(x:0,y:0)]
        penalty=[0.0,0.0,0.0]
        timerRunning = true
        timerSeconds = currentTraining?.duration ?? 0
        training_started = true
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
            initial_time=CACurrentMediaTime()
            trainingStart()
        }
    }
    
    func trainingEnded() {
        timerRunning = false
        training_started = false
        FindBiasPoint()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        /* I THINK THIS LINE SHOULD BE DELETED *******************************
         if let sensorTile = appDelegate.bleController.sensorTile {
         appDelegate.bleController.centralManager.cancelPeripheralConnection(sensorTile)
         }
         */
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let viewController = storyBoard.instantiateViewController(withIdentifier: "reviewTrainingViewController") as! ReviewTrainingViewController
        currentTraining?.score = Float(round(score))
        //currentTraining?.biasPoint = getAverage(Sensor_ID:0) as NSObject
        //currentTraining?.biasPoint = getAverage(Sensor_ID:1) as NSObject
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
        let circle = renderer.image { ctx in
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
        imageView.image = circle
        imageView.alpha = 0.9
    }
    
    static func drawPoint(imageView: UIImageView) {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let dot = renderer.image { ctx in
            ctx.cgContext.setFillColor(Colors.goodLandGreen.cgColor)
            ctx.cgContext.setShadow(offset: CGSize.init(width: 0, height: 0), blur: 10)
            
            let outerRectangle = CGRect(x: 0, y: 0, width: 10, height: 10)
            ctx.cgContext.addEllipse(in: outerRectangle)
            ctx.cgContext.drawPath(using: .fill)
        }
        imageView.image = dot
    }
    
    static func drawPoint2(imageView: UIImageView) {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let dot = renderer.image { ctx in
            ctx.cgContext.setFillColor(Colors.goodLandGreen.cgColor)
            ctx.cgContext.setShadow(offset: CGSize.init(width: 0, height: 0), blur: 10)
            
            let outerRectangle = CGRect(x: 0, y: 0, width: 10, height: 10)
            ctx.cgContext.addEllipse(in: outerRectangle)
            ctx.cgContext.drawPath(using: .fill)
        }
        imageView.image = dot
    }
    
//    func setPointPosition(magnitude: CGFloat, angle: CGFloat) {
//        self.pointX.constant = 147.5 * magnitude * cos(angle)
//        self.pointY.constant = -147.5 * magnitude * sin(-angle)
//        self.view.layoutIfNeeded()
//    }
//
//    func setRollPointPosition(angle: CGFloat) {
//        self.rollPointX.constant = 325 * cos(-angle)
//        self.rollPointY.constant = 325 * sin(-angle)
//        self.view.layoutIfNeeded()
//    }
    
    @IBAction func unwindToMainViewController(unwindSegue: UIStoryboardSegue) {
        
    }
}
