//
//  trainingPagedViewController.swift
//  Adapt
//
//  Created by Josh Altabet on 2/12/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class TrainingHistoryViewController: UIViewController{
    var trainingsList = [Training]()
    var playerId: Int32 = -1
    @IBOutlet weak var target: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var targetWidth: NSLayoutConstraint!
    @IBOutlet weak var targetHeight: NSLayoutConstraint!
    var trainingType: TrainingType?
    var titleText: String?
    
    @IBOutlet weak var biasAverageLabel: UILabel!
    @IBOutlet weak var scoreAverageLabel: UILabel!
    @IBOutlet weak var trainingCount: UILabel!
    
    func updateLabels() {
        trainingsList = fetchTrainings(playerID: playerId, trainingType: trainingType)
        if let unwrappedTitle = titleText {
            titleLabel.text = unwrappedTitle
        }
        if (trainingsList.count == 0) {
            scoreAverageLabel.text = "No Trainings"
            biasAverageLabel.text = ""
            trainingCount.text = ""
            return
        }
        scoreAverageLabel.text = "Average Score: \(round(averageScore()*100)/100)"
        let biasAverage = averageBiasPoint()
        biasAverageLabel.text = "Bias Average X: \(round(biasAverage.x*100)/100), Y: \(round(biasAverage.y*100)/100)"
        trainingCount.text = "Total Trainings: \(trainingsList.count)"
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        NotificationCenter.default.addObserver(forName:Notification.Name(rawValue:"TrainingsRetrieved"),
                       object:nil, queue:nil) { notification in
            DispatchQueue.main.async {
                self.updateLabels()
            }
        }
        if let trainType = trainingType {
            if trainType == .Target{
                MainViewController.drawCircle(imageView: target)
            }
            else if trainType == .BarFlexion{
                OneDBarTrainingViewController.drawBarRect(imageView: target)
                
            } else if trainType == .BarVersion {
                OneDBarTrainingViewController.drawBarRect(imageView: target)
                self.target.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
            }
        } else {
            // overall
            self.target.isHidden = true
        }
        

//        for training in trainingsList {
//            let pointView = UIImageView(frame: CGRect(x: target.frame.midX, y: target.frame.midY, width: 5, height: 5))
//            let pointConstraintX = NSLayoutConstraint(item: pointView, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: target, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
//            let pointConstraintY = NSLayoutConstraint(item: pointView, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: target, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
//
//            if let biasPoint = training.biasPoint as? CGPoint{
//                pointConstraintX.constant = biasPoint.x * MainViewController.EULER_SCALAR * 0.445714285714286
//                pointConstraintY.constant = biasPoint.y * MainViewController.EULER_SCALAR * 0.445714285714286
//            }
//            
//            self.view.addSubview(pointView)
//            self.view.addConstraint(pointConstraintX)
//            self.view.addConstraint(pointConstraintY)
//            MainViewController.drawPoint(imageView: pointView)
//        }
        self.view.layoutIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func fetchTrainings(playerID: Int32, trainingType: TrainingType?) -> [Training] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let trainingsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Training")
        if let unwrappedTrainingType = trainingType {
            trainingsFetch.predicate = NSPredicate(format: "playerId == %@ AND trainingType == %@", NSNumber(value: playerID), NSNumber(value: unwrappedTrainingType.rawValue))
        } else {
            trainingsFetch.predicate = NSPredicate(format: "playerId == %@", NSNumber(value: playerID))
        }
        do {
            let fetchedTrainings = try appDelegate.dataController.managedObjectContext.fetch(trainingsFetch) as! [Training]
            return fetchedTrainings
        } catch {
            fatalError("Failed to fetch players: \(error)")
        }
    }
    
    func averageScore() -> Double {
        if trainingsList.count == 0{
            return 0.0
        }
        var runningScore:Float = 0
        for training in trainingsList {
            runningScore += training.score
        }
        return Double(runningScore)/Double(trainingsList.count)
    }
    
    func averageBiasPoint() -> CGPoint {
        var runningX: CGFloat = 0.0, runningY: CGFloat = 0.0, count = 0
        for training in trainingsList {
            if let biasPoint = training.biasPoint as? CGPoint {
                count += 1
                runningX += biasPoint.x
                runningY += biasPoint.y
            }
        }
        return CGPoint(x: runningX/CGFloat(count), y: runningY/CGFloat(count))
    }
}
