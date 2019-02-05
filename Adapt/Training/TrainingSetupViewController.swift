//
//  TrainingSetupViewController.swift
//  Adapt
//
//  Created by Josh Altabet on 2/5/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class TrainingSetupViewController: UIViewController, UIPopoverPresentationControllerDelegate, SavingViewControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource{
    
    @IBOutlet weak var testOrTrainingCell: TrainingSetupCell!
    @IBOutlet weak var baseTypeCell: TrainingSetupCell!
    @IBOutlet weak var trainingTypeCell: TrainingSetupCell!
    @IBOutlet weak var legCell: TrainingSetupCell!
    @IBOutlet weak var dateCell: TrainingSetupCell!
    @IBOutlet weak var durationCell: TrainingSetupCell!
    @IBOutlet weak var startTrainingButton: UIButton!
    
    @IBOutlet weak var testOrTrainingSelection: UILabel!
    @IBOutlet weak var baseTypeSelection: UILabel!
    @IBOutlet weak var trainingTypeSelection: UILabel!
    @IBOutlet weak var legTypeSelection: UILabel!
    @IBOutlet weak var dateSelection: UILabel!
    @IBOutlet weak var durationSelection: UITextField!

    var player: Player?
    var baseType: BaseType?
    var trainingType: TrainingType?
    var legType: LegType?
    var assessmentType: AssessmentType?
    let date = Date()
    var duration: Int32?
    
    @IBOutlet weak var pickerView: UIPickerView!
    var pickerViewMinutes:Int = 0
    var pickerViewSeconds:Int = 0
    

    
    @IBAction func startTraining(_ sender: Any) {
        var canContinue = true
        
        if let _ = assessmentType {} else {
            testOrTrainingSelection.text = "Please select"
            testOrTrainingSelection.textColor = UIColor.red
            canContinue = false
        }
        
        if let _ = baseType {} else {
            baseTypeSelection.text = "Please select"
            baseTypeSelection.textColor = UIColor.red
            canContinue = false
        }
        
        if let _ = trainingType {} else {
            trainingTypeSelection.text = "Please select"
            trainingTypeSelection.textColor = UIColor.red
            canContinue = false
        }
        
        if let _ = legType {} else {
            legTypeSelection.text = "Please select"
            legTypeSelection.textColor = UIColor.red
            canContinue = false
        }
        
        if let _ = duration {} else {
            durationSelection.text = "Please select"
            durationSelection.textColor = UIColor.red
            canContinue = false
        }
        
        if !canContinue {
            return
        }
        
        //let newTraining = Training(baseType: baseType!, trainingType: trainingType!, legType: legType!, duration: duration!, dateTime: date)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let newTraining = NSEntityDescription.insertNewObject(forEntityName: "Training", into: appDelegate.dataController.managedObjectContext) as! Training
        if let unwrappedPlayer = player {
            newTraining.playerId = unwrappedPlayer.id
            print("player id: \(newTraining.playerId)")
        }
        newTraining.baseType = Int16(baseType!.rawValue)
        newTraining.legType = Int16(legType!.rawValue)
        newTraining.trainingType = Int16(trainingType!.rawValue)
        newTraining.assessmentType = Int16(assessmentType!.rawValue)
        newTraining.duration = duration!
        newTraining.dateTime = date
        
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let viewController = storyBoard.instantiateViewController(withIdentifier: "calibrationViewController") as! CalibrationViewController
        viewController.currentTraining = newTraining
        
        self.navigationController?.pushViewController(viewController, animated: true)
        //performSegue(withIdentifier: "showCalibration", sender: nil)
        
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer.backgroundColor = Colors.goodLandGreen.cgColor
        self.startTrainingButton.layer.cornerRadius = 10.0
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy 'at' HH:mm"
        let dateString = formatter.string(from: date)
        dateSelection.text = dateString
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.layer.backgroundColor = Colors.goodLandGreen.cgColor
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.layer.backgroundColor = Colors.goodLandGreen.cgColor
        self.navigationController?.navigationBar.barTintColor = Colors.goodLandGreen
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
    }
    
    
    
/* MARK: Popover Controller ****************************************************************/
    func launchPopover(optionType: OptionType, sender: UIButton) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let viewController = storyBoard.instantiateViewController(withIdentifier: "setupPopover") as! TrainingSetupPopoverViewController
        
        viewController.modalPresentationStyle = UIModalPresentationStyle.popover
        viewController.preferredContentSize = CGSize.init(width: 200, height: 200)
        viewController.delegate = self
        
        present(viewController, animated: true, completion: nil)
        
        let popoverPresentationController = viewController.popoverPresentationController
        popoverPresentationController?.sourceView = sender
        popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width, height: sender.frame.size.height)
        popoverPresentationController?.delegate = self
        popoverPresentationController?.permittedArrowDirections = .any
        viewController.optionType = optionType
    }
    
    @IBAction func baseTypePopover(_ sender: UIButton) {
        launchPopover(optionType: OptionType.Base, sender: sender)
    }
    
    @IBAction func trainingTypePopover(_ sender: UIButton) {
        launchPopover(optionType: OptionType.Training, sender: sender)
    }
    
    @IBAction func legTypePopover(_ sender: UIButton) {
        launchPopover(optionType: OptionType.Leg, sender: sender)
    }
    
    @IBAction func testOrTrainingPopover(_ sender: UIButton) {
        launchPopover(optionType: OptionType.Assessment, sender: sender)
    }
    
    func saveBaseType(baseType: BaseType) {
        self.baseType = baseType
        baseTypeSelection.text = BaseType.toString(baseType: baseType)
        baseTypeSelection.textColor = UIColor.white
    }
    
    func saveTrainingType(trainingType: TrainingType) {
        self.trainingType = trainingType
        trainingTypeSelection.text = TrainingType.toString(trainingType: trainingType)
        trainingTypeSelection.textColor = UIColor.white
    }
    
    func saveLegType(legType: LegType) {
        self.legType = legType
        legTypeSelection.text = LegType.toString(legType: legType)
        legTypeSelection.textColor = UIColor.white
    }
    
    func saveAssessmentType(assessmentType: AssessmentType) {
        self.assessmentType = assessmentType
        testOrTrainingSelection.text = AssessmentType.toString(assessmentType: assessmentType)
        testOrTrainingSelection.textColor = UIColor.white
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        
    }
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        
    }
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
    
/* MARK: PickerView *********************************************************************/
    
    @IBAction func durartionButton(_ sender: UIButton) {
        if (pickerView.layer.isHidden){
            pickerView.layer.isHidden = false
            sender.setTitle("Done", for: UIControlState.normal)
        } else {
            pickerView.layer.isHidden = true;
            sender.setTitle("Select", for: UIControlState.normal)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 60
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return pickerView.frame.size.width/2
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let string:String;
        switch component{
        case 0:
            string = "\(row) Minutes"
        case 1:
            string = "\(row) Seconds"
        default:
            string = ""
        }
        return NSAttributedString(string: string, attributes: [NSAttributedStringKey.foregroundColor:UIColor.white])
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            pickerViewMinutes = row
        case 1:
            pickerViewSeconds = row
        default:
            break;
        }
        self.durationSelection.text = "\(pickerViewMinutes < 10 ? "0":"")\(pickerViewMinutes):\(pickerViewSeconds < 10 ? "0":"")\(pickerViewSeconds)"
        self.duration = Int32(pickerViewMinutes * 60 + pickerViewSeconds)
        self.durationSelection.textColor = UIColor.white
    }
    
}
















