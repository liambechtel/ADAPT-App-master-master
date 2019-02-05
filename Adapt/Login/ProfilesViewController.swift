//
//  ProfilesViewController.swift
//  Adapt
//
//  Created by Josh Altabet on 1/28/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class ProfilesViewController: UICollectionViewController {
    
    var profilesList = [Player]()
    var selectedPlayer: Player!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        self.collectionView?.addGestureRecognizer(longPressGesture)
        view.backgroundColor = Colors.goodLandGreen
        navigationController?.navigationBar.barTintColor = Colors.goodLandGreen
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        fetchPlayers()
        /*profilesList.append(Player(name: "Giannis Antetokounmpo", number: "34", height: "6'11", weight: "222", position: "Small Forward", picture: #imageLiteral(resourceName: "Antetokounmpo")))
         profilesList.append(Player(name: "Khris Middleton", number: "22", height: "6'8", weight: "234", position: "Small Forward", picture: #imageLiteral(resourceName: "Middleton")))
         profilesList.append(Player(name: "Eric Bledsoe", number: "6", height: "6'1", weight: "205", position: "Guard", picture: #imageLiteral(resourceName: "eric bledsoe")))*/
    }
    
    
    func fetchPlayers() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let playersFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Player")
        
        do {
            let fetchedPlayers = try appDelegate.dataController.managedObjectContext.fetch(playersFetch) as! [Player]
            self.profilesList = fetchedPlayers
            self.collectionView?.reloadData()
        } catch {
            fatalError("Failed to fetch players: \(error)")
        }
    }
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        if gesture.state == .ended {
            return
        }
        
        let p = gesture.location(in: self.collectionView)
        
        if let indexPath = self.collectionView?.indexPathForItem(at: p) {
            // get the cell at indexPath (the one you long pressed)
            let player = profilesList[indexPath.row];
            confirmDeletePlayer(player: player)
            // do stuff with the cell
        } else {
            print("couldn't find index path")
        }
    }
    
    func confirmDeletePlayer(player: Player) {
        let confirmAlert = UIAlertController(title: "Delete", message: "Are you sure you wish to delete \(player.name!)?", preferredStyle: UIAlertControllerStyle.alert)
        
        confirmAlert.addAction(UIAlertAction(title: "Confirm", style: .destructive, handler: { (action: UIAlertAction!) in
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.apiController.deletePlayer(id: player.id)
            appDelegate.dataController.managedObjectContext.delete(player)
            do {
                try appDelegate.dataController.managedObjectContext.save()
                self.fetchPlayers()
            } catch {
                print("failed to save after deleting player")
            }
        }))
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(confirmAlert, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.backgroundColor = Colors.goodLandGreen
        self.navigationController?.navigationBar.barTintColor = Colors.goodLandGreen
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return profilesList.count
    }

    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let profile = collectionView.dequeueReusableCell(withReuseIdentifier: "profile", for: indexPath as IndexPath) as UICollectionViewCell
        
        let label = profile.viewWithTag(1) as! UILabel
        let playerPicture = profile.viewWithTag(2) as! UIImageView
        
        label.text = "#\(profilesList[indexPath.row].number) | \(profilesList[indexPath.row].name!)"
        if let unwrappedPictureData = profilesList[indexPath.row].picture {
            playerPicture.image = UIImage(data: unwrappedPictureData)
        }
        
        let glowColor = UIColor.white
        playerPicture.layer.shadowColor = glowColor.cgColor
        playerPicture.layer.shadowRadius = 5.0
        playerPicture.layer.shadowOpacity = 0.7
        playerPicture.layer.shadowOffset = CGSize(width: 0, height: 0)
        playerPicture.layer.masksToBounds = false
        playerPicture.layer.cornerRadius = playerPicture.frame.width/2
        playerPicture.clipsToBounds = true
        playerPicture.layer.backgroundColor = UIColor.white.cgColor
        playerPicture.contentMode = UIViewContentMode.scaleAspectFill
        
        //playerPicture.image.cornerRadius = 100
        
        //profile.layer.cornerRadius = 100
        
        return profile
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        selectedPlayer = profilesList[indexPath.row]
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Dashboard", bundle:nil)
        let viewController = storyBoard.instantiateViewController(withIdentifier: "dashboardViewController") as! DashboardViewController
        viewController.playerProfile = selectedPlayer
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
}
