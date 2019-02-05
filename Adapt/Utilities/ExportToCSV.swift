//
//  trainingToCSV.swift
//  Adapt
//
//  Created by Josh Altabet on 2/7/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class ExportToCSV{
    
    static func trainingToCSV(training: Training) -> String {
        var csvText: String!
        csvText = "Assesment Type,Base Type,Training Type,Leg Used,Training Duration,Training Date\n"
        csvText.append("\(AssessmentType.toString(assessmentType: AssessmentType(rawValue: Int(training.assessmentType))!)),\(BaseType.toString(baseType: BaseType(rawValue: Int(training.baseType))!)),\(TrainingType.toString(trainingType: TrainingType(rawValue: Int(training.trainingType))!)),\(LegType.toString(legType: LegType(rawValue: Int(training.legType))!)),\(training.duration) seconds,\(training.dateTime!)\n")
        if let biasPoint = training.biasPoint as? CGPoint {
            csvText.append("Bias X Angle,Bias Y Angle,Score\n")
            csvText.append("\(biasPoint.x),\(biasPoint.y),\(training.score)\n")
        }
        if let notes = training.notes {
            csvText.append("Trainer Notes\n")
            csvText.append("\(training.notes!)\n")
        }
        if let data = training.data as? NSArray {
            csvText.append("X Angle,Y Angle\n")
            for dataPoint in data{
                
                let newLine = "\(dataPoint)\n"
                csvText.append(contentsOf: newLine)
            }
        }
        else {
            csvText.append("No Training Data availible\n")
        }
        
        return csvText
        
    }
    
    static func playerToCSV(player:Player) -> String {
        var csvText: String!
        let trainingsList = fetchTrainingsList(playerID: player.id)
        
        csvText = "Name, Number,Height,Weight,Position,Player ID\n"
        csvText.append("\(player.name!),\(player.number),\(player.height),\(player.weight),\(player.position!),\(player.id)\n")
        
        if trainingsList.count == 0 {
            csvText.append("No trainings recorded for player# \(player.id)\n")
        }
        else {
            for training in trainingsList {
                let trainingID = training.id
                csvText.append("TRAINING # \(trainingID)\n")
                csvText.append(trainingToCSV(training: training))
            }
        }

        return csvText
    }
    
    static func fetchTrainingsList(playerID: Int32) -> [Training] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let trainingsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Training")
        trainingsFetch.predicate = NSPredicate(format: "playerId == %@", NSNumber(value: playerID))
        do {
            let fetchedTrainings = try appDelegate.dataController.managedObjectContext.fetch(trainingsFetch) as! [Training]
            return fetchedTrainings
        } catch {
            fatalError("Failed to fetch players: \(error)")
        }
    }
    
    
}
