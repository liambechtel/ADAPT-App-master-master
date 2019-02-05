//
//  ReviewTrainingViewController.swift
//  Adapt
//
//  Created by Josh Altabet on 2/7/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation
import UIKit

class ReviewTrainingViewController: UIViewController, UITextViewDelegate{
    var currentTraining: Training?
    
    @IBOutlet weak var biasPointView: UIImageView!
    @IBOutlet weak var pointView: UIImageView!
    @IBOutlet weak var pointViewX: NSLayoutConstraint!
    @IBOutlet weak var pointViewY: NSLayoutConstraint!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var scoreImage: UIImageView!
    @IBOutlet weak var trainerNotes: UITextView!
    @IBOutlet weak var biasPointLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let training = currentTraining {
            if (training.score == 100) {
                scoreLabel.text = "100"
            } else {
                scoreLabel.text = String(training.score)
            }
            drawScore(score: CGFloat(training.score))
            
            /*self.navigationController?.viewControllers.forEach({ (vc) in
                if (vc is MainViewController) {
                    MainViewController.drawCircle(imageView: biasPointView)
                    MainViewController.drawPoint(imageView: pointView)
                }
                if (vc is OneDBarTrainingViewController) {
                    OneDBarTrainingViewController.drawBarRect(imageView: biasPointView)
                    OneDBarTrainingViewController.drawBar(imageView: pointView)
                }
            })*/
            
            MainViewController.drawCircle(imageView: biasPointView)
            MainViewController.drawPoint(imageView: pointView)
            if let biasPoint = training.biasPoint as? CGPoint {
                let roundedX = Double(round(biasPoint.x * 10) / 10)
                let roundedY = Double(round(biasPoint.y * 10) / 10)
                biasPointLabel.text = "Bias Point X: \(roundedX) Y: \(roundedY)"
                pointViewX.constant = biasPoint.x * MainViewController.EULER_SCALAR * 0.445714285714286
                pointViewY.constant = -biasPoint.y * MainViewController.EULER_SCALAR * 0.445714285714286
                view.layoutIfNeeded()
            }
        }
        self.trainerNotes.delegate = self
        self.trainerNotes.layer.cornerRadius = 10.0
        self.trainerNotes.layer.borderColor = UIColor.black.cgColor
        self.trainerNotes.layer.borderWidth = 2
        self.trainerNotes.textColor = UIColor.lightGray
        self.trainerNotes.text = "Type Trainer Notes Here"
        
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func drawScore(score: CGFloat) {
        // round view
        let roundView = UIView(frame: CGRect(x: 5, y: 5, width: 140, height: 140))
        roundView.backgroundColor = UIColor.white
        roundView.layer.cornerRadius = roundView.frame.size.width / 2
        
        // bezier path
        let circlePath = UIBezierPath(arcCenter: CGPoint (x: roundView.frame.size.width / 2, y: roundView.frame.size.height / 2),
                                      radius: roundView.frame.size.width / 2,
                                      startAngle: CGFloat(-0.5 * Double.pi),
                                      endAngle: CGFloat(1.5 * Double.pi),
                                      clockwise: true)
        // circle shape
        let circleShape = CAShapeLayer()
        circleShape.path = circlePath.cgPath
        circleShape.strokeColor = Colors.goodLandGreen.cgColor
        circleShape.fillColor = UIColor.clear.cgColor
        circleShape.lineWidth = 10
        // set start and end values
        circleShape.strokeStart = 0.0
        circleShape.strokeEnd = score / 100.0
        
        // add sublayer
        roundView.layer.addSublayer(circleShape)
        // add subview
        scoreImage.addSubview(roundView)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Type Trainer Notes Here"
            textView.textColor = UIColor.lightGray
        }
        else {
            self.currentTraining?.notes = self.trainerNotes.text
        }
    }
    
    @IBAction func exportToCSV(_ sender: Any) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy'_'HH:mm"
        let date = formatter.string(from: (currentTraining?.dateTime)!)
        let player = currentTraining?.playerId
        let fileName = "Player#\(player!)_Training_\(date).csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        if let unwrappedTraining = currentTraining {
            let csvText = ExportToCSV.trainingToCSV(training: unwrappedTraining)
            
            do {
                try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
                
                let vc = UIActivityViewController(activityItems: [path], applicationActivities: nil)
                vc.popoverPresentationController?.sourceView = self.view
                vc.excludedActivityTypes = [
                    UIActivityType.assignToContact,
                    UIActivityType.saveToCameraRoll,
                    UIActivityType.postToFlickr,
                    UIActivityType.postToVimeo,
                    UIActivityType.postToTencentWeibo,
                    UIActivityType.postToTwitter,
                    UIActivityType.postToFacebook,
                    UIActivityType.openInIBooks
                ]
                present(vc, animated: true, completion: nil)
            } catch {
                print("Failed to create file")
                print("\(error)")
            }
        } else {
            print("no training data")
        }
    }

    
    @IBAction func backToDashboard(_ sender: Any) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let training = currentTraining else { return }
        training.notes = trainerNotes.text
        appDelegate.apiController.createTraining(training: training) {
            appDelegate.apiController.getTrainings(playerId: training.playerId) {
                let nc = NotificationCenter.default
                nc.post(name:Notification.Name(rawValue:"TrainingsRetrieved"), object: nil)
            }
        }
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.viewControllers.forEach({ (vc) in
            if (vc is DashboardViewController) {
                self.navigationController?.popToViewController(vc, animated: true)
            }
        })
    }
    
    @IBAction func restartTraining(_ sender: Any) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.viewControllers.forEach({ (vc) in
            if (vc is MainViewController) {
                self.navigationController?.popToViewController(vc, animated: true)
            }
            if (vc is OneDBarTrainingViewController) {
                self.navigationController?.popToViewController(vc, animated: true)
            }
        })
    }
    
}
