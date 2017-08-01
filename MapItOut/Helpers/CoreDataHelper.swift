//
//  CoreDataHelper.swift
//  MapItOut
//
//  Created by Portia Wang on 7/2/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import CoreData
import UIKit

class CoreDataHelper {
    static let appDelegate = UIApplication.shared.delegate as! AppDelegate
    static let persistentContainer = appDelegate.persistentContainer
    static let managedContext = persistentContainer.viewContext
    
    //static methods will go here
    
    //new activity
    static func newItem() -> Item {
        weak var item = NSEntityDescription.insertNewObject(forEntityName: "Item", into: managedContext) as? Item
        return item!
    }
    
    //save activity
    static func saveItem() {
        do{
            try managedContext.save()
        } catch let error as NSError{
            print("could not save \(error)")
        }
    }
    
    //delete activity
    static func deleteItems (item: Item){
        managedContext.delete(item)
        saveItem()
    }
    
    //retreive activity
    
    static func retrieveItems() -> [Item] {
        let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
        do {
            let results = try managedContext.fetch(fetchRequest)
            return results
        } catch let error as NSError {
            print("Could not fetch \(error)")
        }
        return []
    }
}





