//
//  APIController.swift
//  Adapt
//
//  Created by Timmy Gouin on 3/12/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

typealias ServiceResponse = (JSON?, NSError?) -> Void

extension String {
    var url: String { return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! }
}

class APIController: NSObject {
//   static let rootURL = "http://192.168.1.152:3000"
  //   static let rootURL = "http://52.53.90.187"
    static let rootURL = "http://10.0.0.1"
    
    override init() {
        super.init()
    }
    
    func createPlayer(player: Player,onCompletion: @escaping () -> Void) {
        let url = "\(APIController.rootURL)/players/create?name=\(player.name!.url)&number=\(player.number)&position=\(player.position!.url)&height=\(player.height)&weight=\(player.weight)"
        makeHTTPGetRequest(path: url) { (data, error) in
            onCompletion()
            guard error == nil else {
                print("Error creating player")
                return
            }
            print("Player successfully created!")
            
        }
    }
    
    func updatePlayer(player: Player) {
        var url = "\(APIController.rootURL)/players/edit?id=\(player.id)&number=\(player.number)&height=\(player.height)&weight=\(player.weight)"
        if let unwrappedName = player.name {
            url += "&name=\(unwrappedName.url)"
        }
        if let unwrappedPosition = player.position {
            url += "&position=\(unwrappedPosition.url)"
        }
        makeHTTPGetRequest(path: url) { (data, error) in
            guard error == nil else {
                print("Error editing player")
                return
            }
            print("Player successfully edited!")
        }
    }
    
    func deletePlayer(id: Int32) {
        let url = "\(APIController.rootURL)/players/delete?id=\(id)"
        makeHTTPGetRequest(path: url) { (data, error) in
            guard error == nil else {
                print("Error deleting player from server")
                return
            }
            print("Player successfully deleted!")
        }
    }
    
    func getPlayers(onCompletion: @escaping () -> Void) {
        let url = "\(APIController.rootURL)/players"
        print(url)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        makeHTTPGetRequest(path: url) { (data, error) in
            guard let json = data else { return }
            let array = json.array
            var players: [Player] = []
            let allPlayersFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Player")
            let allFetchedPlayers:[Player]
            var newPlayerNames: [String] = []
            do {
                allFetchedPlayers = try appDelegate.dataController.managedObjectContext.fetch(allPlayersFetch) as! [Player]
            } catch {
                fatalError("Failed to fetch players: \(error)")
            }
            array?.forEach({ (jsonPlayer) in
                guard let dict = jsonPlayer.dictionaryObject else { return }
                guard let name = dict["name"] as? String else { return }
                newPlayerNames.append(name)
                let playersFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Player")
                playersFetch.predicate = NSPredicate(format: "name == %@", name)
                let fetchedPlayers:[Player]
                do {
                    fetchedPlayers = try appDelegate.dataController.managedObjectContext.fetch(playersFetch) as! [Player]
                } catch {
                    fatalError("Failed to fetch players: \(error)")
                }
                let player: Player
                if fetchedPlayers.count == 0 {
                    player = NSEntityDescription.insertNewObject(forEntityName: "Player", into: appDelegate.dataController.managedObjectContext) as! Player
                } else if fetchedPlayers.count == 1 {
                    player = fetchedPlayers[0]
                } else {
                    fetchedPlayers.forEach({ (toDelete) in
                        appDelegate.dataController.managedObjectContext.delete(toDelete)
                    })
                    player = NSEntityDescription.insertNewObject(forEntityName: "Player", into: appDelegate.dataController.managedObjectContext) as! Player
                }
                
                player.name = name
               
                if let id = dict["id"] as? Int32 {
                    player.id = id
                }
                if let number = dict["number"] as? Int16 {
                    player.number = number
                }
                if let position = dict["position"] as? String {
                    player.position = position
                }
                if let height = dict["height"] as? Int16 {
                    player.height = height
                }
                if let weight = dict["weight"] as? Double {
                    player.weight = weight
                }
                players.append(player)
            })
            allFetchedPlayers.forEach({ (oldPlayer) in
                var foundName = false
                for i in 0..<newPlayerNames.count {
                    if oldPlayer.name == newPlayerNames[i] {
                        foundName = true
                    }
                }
                if !foundName {
                    appDelegate.dataController.managedObjectContext.delete(oldPlayer)
                }
            })
            do {
                try appDelegate.dataController.managedObjectContext.save()
            } catch {
                print("Unable to save players from server")
            }
            print("got players!!!", players)
            onCompletion()
        }
    }
    
    func createTraining(training: Training, onCompletion: @escaping () -> Void) {
//        var jsonString: String! = ""
//        if let dictionary = training.data as? NSArray {
//            do {
//                let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
//                jsonString = String(data: jsonData, encoding: String.Encoding.utf8) as String!
//            } catch {
//                print("error parsing training as json string")
//                return
//            }
//        }
        guard let dateTime = training.dateTime else { return }
        let dateString = DateUtils.getMySQLDate(date: dateTime)
        guard let biasPoint = training.biasPoint as? CGPoint else { return }
        let notes = training.notes ?? ""
        print("training player ID: \(training.playerId)")
        
        var trainingJSON: [String: Any] = [:];
        trainingJSON["data"] = training.data
        trainingJSON["playerId"] = training.playerId
        trainingJSON["dateTime"] = dateString
        trainingJSON["notes"] = notes
        trainingJSON["score"] = training.score
        trainingJSON["trainingType"] = training.trainingType
        trainingJSON["baseType"] = training.baseType
        trainingJSON["legType"] = training.legType
        trainingJSON["assessmentType"] = training.assessmentType
        trainingJSON["duration"] = training.duration
        trainingJSON["biasPointX"] = biasPoint.x
        trainingJSON["biasPointY"] = biasPoint.y
        
        makeHTTPPostRequest(path: "\(APIController.rootURL)/trainings/create", json: trainingJSON) { (json, error) in
            onCompletion()
            guard error == nil else {
                print("Error creating training")
                return
            }
            print("Training successfully created!")
        }
        
        // TODO: data is too large, need to switch to post instead of get. Comment this out once data is well-formed
//        jsonString = "[]"
//
//        let url = "\(APIController.rootURL)/trainings/create?playerId=\(training.playerId)&dateTime=\(dateString.url)&data=\(jsonString.url)&notes=\(notes.url)&score=\(training.score)&trainingType=\(training.trainingType)&baseType=\(training.baseType)&legType=\(training.legType)&assessmentType=\(training.assessmentType)&duration=\(training.duration)&biasPointX=\(biasPoint.x)&biasPointY=\(biasPoint.y)"
//        makeHTTPGetRequest(path: url) { (data, error) in
//            guard error == nil else {
//                print("Error creating training")
//                return
//            }
//            print("Training successfully created!")
//        }
    }
    
    func getTrainings(playerId: Int32, onCompletion: @escaping () -> Void) {
        let url = "\(APIController.rootURL)/trainings?playerId=\(playerId)"
        print(url)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        makeHTTPGetRequest(path: url) { (data, error) in
            guard let json = data else { return }
            let array = json.array
            var trainings: [Training] = []
            let allTrainingsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Training")
            let allFetchedTrainings:[Training]
            var newDateTimes: [Date] = []
            do {
                allFetchedTrainings = try appDelegate.dataController.managedObjectContext.fetch(allTrainingsFetch) as! [Training]
            } catch {
                fatalError("Failed to fetch trainings: \(error)")
            }
            array?.forEach({ (jsonTraining) in
                guard let dict = jsonTraining.dictionaryObject else { return }
                guard let date = dict["dateTime"] as? String else { return }
                guard let dateTime = DateUtils.parseMySQLDate(date: date) else { return }
                newDateTimes.append(dateTime)
                let trainingsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Training")
                trainingsFetch.predicate = NSPredicate(format: "dateTime == %@", dateTime as CVarArg)
                let fetchedTrainings:[Training]
                do {
                    fetchedTrainings = try appDelegate.dataController.managedObjectContext.fetch(trainingsFetch) as! [Training]
                } catch {
                    fatalError("Failed to fetch trainings: \(error)")
                }
                let training: Training
                if fetchedTrainings.count == 0 {
                    training = NSEntityDescription.insertNewObject(forEntityName: "Training", into: appDelegate.dataController.managedObjectContext) as! Training
                } else if fetchedTrainings.count == 1 {
                    training = fetchedTrainings[0]
                } else {
                    fetchedTrainings.forEach({ (toDelete) in
                        appDelegate.dataController.managedObjectContext.delete(toDelete)
                    })
                    training = NSEntityDescription.insertNewObject(forEntityName: "Training", into: appDelegate.dataController.managedObjectContext) as! Training
                }
                
                training.dateTime = dateTime
                training.playerId = playerId
                if let id = dict["id"] as? Int32 {
                    training.id = id
                }
                if let data = dict["data"] as? String {
                    let json = JSON.init(parseJSON: data)
                    if let nsObject = json.arrayObject as NSObject? {
                        training.data = nsObject
                    }
                }
                if let notes = dict["notes"] as? String {
                    training.notes = notes
                }
                if let score = dict["score"] as? Float {
                    training.score = round(score)
                }
                if let trainingType = dict["trainingType"] as? Int16 {
                    training.trainingType = trainingType
                }
                if let baseType = dict["baseType"] as? Int16 {
                    training.baseType = baseType
                }
                if let assessmentType = dict["assessmentType"] as? Int16 {
                    training.assessmentType = assessmentType
                }
                if let trainingType = dict["trainingType"] as? Int16 {
                    training.trainingType = trainingType
                }
                if let legType = dict["legType"] as? Int16 {
                    training.legType = legType
                }
                if let duration = dict["duration"] as? Int32 {
                    training.duration = duration
                }
                if let biasPointX = dict["biasPointX"] as? Double, let biasPointY = dict["biasPointY"] as? Double {
                    training.biasPoint = CGPoint(x: biasPointX, y: biasPointY) as NSObject
                }
                trainings.append(training)
            })
            allFetchedTrainings.forEach({ (oldTraining) in
                var foundDate = false
                for i in 0..<newDateTimes.count {
                    if oldTraining.dateTime == newDateTimes[i] {
                        foundDate = true
                    }
                }
                if !foundDate {
                    appDelegate.dataController.managedObjectContext.delete(oldTraining)
                }
            })
            do {
                try appDelegate.dataController.managedObjectContext.save()
            } catch {
                print("Unable to save trainings from server")
            }
            print("got trainings!!!", trainings)
            onCompletion()
        }
    }
    
    func deleteTraining(id: Int32) {
        let url = "\(APIController.rootURL)/trainings/delete?id=\(id)"
        makeHTTPGetRequest(path: url) { (data, error) in
            guard error == nil else {
                print("Error deleting training from server")
                return
            }
            print("Training successfully deleted!")
        }
    }
    
    func makeHTTPGetRequest(path: String, onCompletion: @escaping ServiceResponse) {
        let request = URLRequest(url: URL(string: path)!)
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: {data, response, error -> Void in
            guard error == nil else {
                onCompletion(nil, error as! NSError)
                return
            }
            guard let unwrappedData = data else {
                onCompletion(nil, nil)
                return
            }
            let json = try? JSON(data: unwrappedData)
            guard let unwrappedJSON = json else {
                onCompletion(nil, nil)
                return
            }
            onCompletion(unwrappedJSON, nil)
            
        })
        task.resume()
    }
    
    func makeHTTPPostRequest(path: String, json: [String:Any], onCompletion: @escaping ServiceResponse) {
        
        //create post request
        let url = URL(string: path)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json)
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            print("json", jsonString)
            request.httpBody = jsonString?.data(using: .utf8)
        } catch {
            onCompletion(nil, nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                onCompletion(nil, error as NSError?)
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            do {
            try onCompletion(JSON(data:data), nil)
            } catch {
                onCompletion(nil, nil)
            }
            print("responseString = \(responseString)")
        }
        task.resume()
    }
}

