//
//  SignUpViewController.swift
//  Adapt
//
//  Created by Josh Altabet on 1/29/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class SignUpViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate{
    var newPlayer: Player?
    

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var numberTextField: UITextField!
    @IBOutlet weak var weightTextField: UITextField!
    @IBOutlet weak var heightTextField: UITextField!
    @IBOutlet weak var positionTextField: UITextField!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var playerImage: UIImageView!
    @IBOutlet weak var pictureLabel: UILabel!
    var isDismissed = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        numberTextField.delegate = self
        weightTextField.delegate = self
        heightTextField.delegate = self
        positionTextField.delegate = self
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            nameLabel.textColor = UIColor.black
        }
        
        if textField == numberTextField {
            numberLabel.textColor = UIColor.black
        }
        
        if textField == heightTextField {
            heightLabel.textColor = UIColor.black
        }
        
        if textField == weightTextField {
            weightLabel.textColor = UIColor.black
        }
        
        if textField == positionTextField {
            positionLabel.textColor = UIColor.black
        }
        
        return true
    }
    
    @IBAction func chooseImage(_ sender: UIButton) {
        pictureLabel.textColor = UIColor.black
        isDismissed = false
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        playerImage.image = image
        if !self.isDismissed {
            dismiss(animated: true, completion: nil)
        }
        self.isDismissed = true
    }
    
    @IBAction func createNewProfile(_ sender: UIButton) {
        
        playerImage.image = nameToImage(name: nameTextField.text!)
        
        var canContinue = true
        if nameTextField.text == "" {
            nameLabel.textColor = UIColor.red
            canContinue = false
        }
        
        if numberTextField.text == "" {
            numberLabel.textColor = UIColor.red
            canContinue = false
        }
        
        if weightTextField.text == "" {
            weightLabel.textColor = UIColor.red
            canContinue = false
        }
        
        if heightTextField.text == "" {
            heightLabel.textColor = UIColor.red
            canContinue = false
        }
        
        if positionTextField.text == "" {
            positionLabel.textColor = UIColor.red
            canContinue = false
        }
        
        if playerImage.image == nil {
            pictureLabel.textColor = UIColor.red
            canContinue = false
        }
        
        if !canContinue {
            return
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let newPlayer = NSEntityDescription.insertNewObject(forEntityName: "Player", into: appDelegate.dataController.managedObjectContext) as! Player
        
        newPlayer.name = nameTextField.text!
        let playerNumber = Int16(numberTextField.text!)
        newPlayer.number = playerNumber ?? 0
        newPlayer.height = PlayerUtils.parseHeight(heightString: heightTextField.text!)
        let playerWeight = Double(weightTextField.text!.trimmingCharacters(in: CharacterSet(charactersIn: "01234567890.").inverted))
        newPlayer.weight = playerWeight ?? 0
        newPlayer.position = positionTextField.text!
        if let unwrappedImage = playerImage.image {
            if let resizedImage = PlayerUtils.resizeImage(image: unwrappedImage, targetSize: CGSize(width: PlayerUtils.MAX_IMAGE_SIZE, height: PlayerUtils.MAX_IMAGE_SIZE)) {
                newPlayer.picture = UIImagePNGRepresentation(resizedImage)
            }
        }
        appDelegate.apiController.createPlayer(player: newPlayer) {
            appDelegate.apiController.getPlayers() {}
        }
        do {
            try appDelegate.dataController.managedObjectContext.save()
        } catch {
            print("save player failed")
        }
        self.newPlayer = newPlayer
        navigationController?.viewControllers.forEach({vc in
            if vc is ProfilesViewController {
                navigationController?.popToViewController(vc, animated: true)
                if let pvc = vc as? ProfilesViewController {
                    pvc.fetchPlayers()
                }
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is DashboardViewController
        {
            let vc = segue.destination as? DashboardViewController
            vc?.playerProfile = newPlayer
        }
    }
    
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    func changeWhiteColorTransparent(image: UIImage) -> UIImage? {
        let rawImageRef = image.cgImage!
        let colorMasking: [CGFloat] = [222, 255, 222, 255, 222, 255]
        UIGraphicsBeginImageContext(image.size)
        let maskedImageRef: CGImage = rawImageRef.copy(maskingColorComponents: colorMasking)!
        do {
            //if in iphone
            UIGraphicsGetCurrentContext()?.translateBy(x: 0.0, y: image.size.height)
            UIGraphicsGetCurrentContext()?.scaleBy(x: 1.0, y: -1.0)
        }

        UIGraphicsGetCurrentContext()?.draw(maskedImageRef, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        let result: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result ?? UIImage()
    }
    
    func nameToImage(name: String) -> UIImage{
        switch name{
        case "Giannis Antetokounmpo":
            return #imageLiteral(resourceName: "giannis antetokounmpo")
        case "Eric Bledsoe":
            return #imageLiteral(resourceName: "eric bledsoe")
        case "Malcolm Brogdon":
            return #imageLiteral(resourceName: "malcom brogdon")
        case "Sterling Brown":
            return #imageLiteral(resourceName: "sterling brown")
        case "Matthew Dellavedova":
            return #imageLiteral(resourceName: "matt dellavedova")
        case "John Henson":
            return #imageLiteral(resourceName: "john henson")
        case "Sean Kilpatrick":
            return #imageLiteral(resourceName: "sean kilpatrick")
        case "Thon Maker":
            return #imageLiteral(resourceName: "thon maker")
        case "Khris Middleton":
            return #imageLiteral(resourceName: "khris middleton")
        case "Xavier Munford":
            return #imageLiteral(resourceName: "xavier munford")
        case "Jabari Parker":
            return #imageLiteral(resourceName: "jabari parker")
        case "Marshall Plumlee":
            return #imageLiteral(resourceName: "marshall plumlee")
        case "Tony Snell":
            return #imageLiteral(resourceName: "tony snell")
        case "Mirza Teletovic":
            return #imageLiteral(resourceName: "mirza teletovic")
        case "Jason Terry":
            return #imageLiteral(resourceName: "jason terry")
        case "D.J. Wilson":
            return #imageLiteral(resourceName: "dj wilson")
        case "Tyler Zeller":
            return #imageLiteral(resourceName: "tyler zeller")
        default:
            return #imageLiteral(resourceName: "milwaukeebuckslogo")
        }
    }
}
