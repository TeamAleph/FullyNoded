//
//  CoreDataService.swift
//  BitSense
//
//  Created by Peter on 04/04/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class CoreDataService {
    
    class func saveEntity(dict: [String:Any], entityName: ENTITY, completion: @escaping ((Bool)) -> Void) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                let context = appDelegate.persistentContainer.viewContext
                guard let entity = NSEntityDescription.entity(forEntityName: entityName.rawValue, in: context) else {
                    completion(false)
                    return
                }
                let credential = NSManagedObject(entity: entity, insertInto: context)
                var success = false
                for (key, value) in dict {
                    credential.setValue(value, forKey: key)
                    do {
                        try context.save()
                        success = true
                    } catch {
                    }
                }
                completion(success)
            } else {
                completion(false)
            }
        }
    }
    
    class func retrieveEntity(entityName: ENTITY, completion: @escaping (([[String:Any]]?)) -> Void) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                let context = appDelegate.persistentContainer.viewContext
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName.rawValue)
                fetchRequest.returnsObjectsAsFaults = false
                fetchRequest.resultType = .dictionaryResultType
                do {
                    if let results = try context.fetch(fetchRequest) as? [[String:Any]] {
                        completion(results)
                    }
                } catch {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    class func deleteAllData(entity: ENTITY, completion: @escaping ((Bool)) -> Void) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                let managedContext = appDelegate.persistentContainer.viewContext
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.rawValue)
                fetchRequest.returnsObjectsAsFaults = false
                do {
                    let stuff = try managedContext.fetch(fetchRequest)
                    for thing in stuff as! [NSManagedObject] {
                        managedContext.delete(thing)
                    }
                    try managedContext.save()
                    completion(true)
                } catch {
                    completion(false)
                }
            }
        }
    }
    
//    class func updateEntity(dictsToUpdate: [[String:Any]], completion: @escaping () -> Void) {
//        for (i, d) in dictsToUpdate.enumerated() {
//            var newValue:Any!
//
//            let id = d["id"] as! String
//
//            if let newValueCheck = d["newValue"] as? String {
//
//                newValue = newValueCheck
//
//            } else if let newValueCheck = d["newValue"] as? Bool {
//
//                newValue = newValueCheck
//
//            }
//
//            let keyToEdit = d["keyToEdit"] as! String
//            let entityName = d["entityName"] as! ENTITY
//
//            DispatchQueue.main.async {
//
//                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
//
//                    let context = appDelegate.persistentContainer.viewContext
//                    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName.rawValue)
//                    fetchRequest.returnsObjectsAsFaults = false
//
//                    do {
//
//                        let results = try context.fetch(fetchRequest) as [NSManagedObject]
//
//                        if results.count > 0 {
//
//                            for data in results {
//
//                                if id == data.value(forKey: "id") as? String {
//
//                                    data.setValue(newValue, forKey: keyToEdit)
//
//                                    do {
//
//                                        try context.save()
//                                        self.errorBool = false
//                                        self.boolToReturn = true
//                                        print("updated successfully")
//
//                                    } catch {
//
//                                        print("error editing")
//                                        self.errorBool = true
//                                        self.errorDescription = "error editing"
//
//                                    }
//
//                                }
//
//                            }
//
//                            if i == dictsToUpdate.count - 1 {
//
//                                completion()
//
//                            }
//
//                        } else {
//
//                            print("no results")
//                            self.errorBool = true
//                            self.errorDescription = "no results"
//                            completion()
//                        }
//
//                    } catch {
//
//                        print("Failed")
//                        self.errorBool = true
//                        self.errorDescription = "failed"
//                        completion()
//                    }
//
//                } else {
//
//                    self.errorBool = true
//                    self.errorDescription = "Something strange has happened and we do not have access to app delegate, please try again."
//                    completion()
//
//                }
//
//            }
//
//        }
//
//    }
    
    class func update(id: UUID, keyToUpdate: String, newValue: Any, entity: ENTITY, completion: @escaping ((Bool)) -> Void) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                let context = appDelegate.persistentContainer.viewContext
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entity.rawValue)
                fetchRequest.returnsObjectsAsFaults = false
                do {
                    let results = try context.fetch(fetchRequest) as [NSManagedObject]
                    if results.count > 0 {
                        for data in results {
                            if id == data.value(forKey: "id") as? UUID {
                                data.setValue(newValue, forKey: keyToUpdate)
                                do {
                                    try context.save()
                                    completion(true)
                                } catch {
                                    completion(false)
                                }
                            }
                        }
                    } else {
                        completion(false)
                    }
                } catch {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    class func deleteEntity(id: UUID, entityName: ENTITY, completion: @escaping ((Bool)) -> Void) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                let context = appDelegate.persistentContainer.viewContext
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName.rawValue)
                fetchRequest.returnsObjectsAsFaults = false
                do {
                    let results = try context.fetch(fetchRequest) as [NSManagedObject]
                    if results.count > 0 {
                        for (index, data) in results.enumerated() {
                            if id == data.value(forKey: "id") as? UUID {
                                context.delete(results[index] as NSManagedObject)
                                do {
                                    try context.save()
                                    completion(true)
                                } catch {
                                    completion(false)
                                }
                            }
                        }
                    } else {
                        completion(false)
                    }
                } catch {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
//    func deleteNode(id: UUID, entityName: ENTITY, completion: @escaping ((Bool)) -> Void) {
//        DispatchQueue.main.async {
//            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
//                let context = appDelegate.persistentContainer.viewContext
//                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName.rawValue)
//                fetchRequest.returnsObjectsAsFaults = false
//                do {
//                    let results = try context.fetch(fetchRequest) as [NSManagedObject]
//                    if results.count > 0 {
//                        for (index, data) in results.enumerated() {
//                            if id == data.value(forKey: "id") as? UUID {
//                                context.delete(results[index] as NSManagedObject)
//                                do {
//                                    try context.save()
//                                    completion(true)
//                                } catch {
//                                    completion(false)
//                                }
//                            }
//                        }
//                    } else {
//                        completion(false)
//                    }
//                } catch {
//                    completion(false)
//                }
//            } else {
//                completion(false)
//            }
//        }
//    }
    
}
