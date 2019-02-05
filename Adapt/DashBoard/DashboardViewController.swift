//
//  DashboardViewController.swift
//  Adapt
//
//  Created by Josh Altabet on 1/29/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation
import UIKit

class DashboardViewController: UIViewController {
    var playerProfile: Player?

    @IBOutlet weak var playerPicture: UIImageView!
    @IBOutlet weak var playerBanner: UIView!
    @IBOutlet weak var playerDetails: UILabel!
    var pagesViewController: PagesViewController?
    
    @IBOutlet weak var pageView: UIView!
    
    func reloadTrainings() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let playerProfile = self.playerProfile else { return }
        appDelegate.apiController.getTrainings(playerId: playerProfile.id) {
            if let pagesView = self.pagesViewController {
                pagesView.orderedViewControllers.forEach({ (vc) in
                    if let trainingHistoryVC = vc as? TrainingHistoryViewController {
                        if trainingHistoryVC.viewIfLoaded != nil {
                            DispatchQueue.main.async {
                                trainingHistoryVC.updateLabels()
                            }
                        }
                    }
                })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reloadTrainings()
        playerPicture.clipsToBounds = true
        self.view.backgroundColor = Colors.goodLandGreen
        self.navigationController?.navigationBar.barTintColor = Colors.goodLandGreen
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        guard let playerProfile = self.playerProfile else { return }
        
        let weight = Double(round(10*playerProfile.weight)/10)
        let details = "#\(playerProfile.number) | \(playerProfile.name!)\nWT: \(weight)\nHT: \(PlayerUtils.getHeightString(height: playerProfile.height))\nPOS: \(playerProfile.position!)"
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 1.2
        style.paragraphSpacing = 10
        let attributes: [NSAttributedStringKey: Any] = [ NSAttributedStringKey.font: UIFont(name: "NBA Bucks", size: 30)!, NSAttributedStringKey.paragraphStyle: style ]
        let attributedDetails = NSMutableAttributedString(string: details)
        attributedDetails.addAttributes(attributes, range: NSMakeRange(0, details.count))
        self.playerDetails.attributedText = attributedDetails
        if let unwrappedPicture = playerProfile.picture {
            self.playerPicture.image = UIImage(data: unwrappedPicture)
        }
        self.playerPicture.contentMode = UIViewContentMode.scaleAspectFill

        self.pageView.layer.borderWidth = 2
        self.pageView.layer.borderColor = UIColor.black.cgColor
        self.pageView.layer.cornerRadius = 10.0
        
        let gradient = CAGradientLayer()
        gradient.frame = playerBanner.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.init(red: 1, green: 1, blue: 1, alpha: 0.2).cgColor]
        playerBanner.layer.backgroundColor = UIColor.clear.cgColor
        playerBanner.layer.insertSublayer(gradient, at: 0)
        
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.backgroundColor = Colors.goodLandGreen
        self.navigationController?.navigationBar.barTintColor = Colors.goodLandGreen
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is SettingsViewController
        {
            let vc = segue.destination as? SettingsViewController
            vc?.playerProfile = playerProfile
            vc?.playerId = playerProfile?.id ?? -1
        }
        else if segue.destination is TrainingSetupViewController {
            let vc = segue.destination as? TrainingSetupViewController
            vc?.player = playerProfile
        }
        else if segue.destination is PagesViewController {
            let vc = segue.destination as? PagesViewController
            self.pagesViewController = vc
            vc?.playerId = playerProfile?.id ?? -1
        }
    }
}
    

