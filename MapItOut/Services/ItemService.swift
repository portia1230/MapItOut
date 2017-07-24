//
//  EntryService.swift
//  MapItOut
//
//  Created by Portia Wang on 7/9/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseStorage

struct ItemService{
    
    static func addEntry(entry: Entry){
        let currentUser = User.currentUser
        let entryRef = Database.database().reference().child("Items").child(currentUser.uid).child(entry.key)
        let dict = entry.dictValue
        entryRef.setValue(dict)
    }
    
    static func deleteEntry(key: String){
        let currentUser = User.currentUser
        //let dict = entry.dictValue
        let entryRef = Database.database().reference().child("Items").child(currentUser.uid).child(key)
        entryRef.removeValue()
    }
    
    static func editEntry(entry: Entry){
        let currentUser = User.currentUser
        let entryRef = Database.database().reference().child("Items").child(currentUser.uid).child(entry.key)
        let dict = entry.dictValue
        entryRef.updateChildValues(dict)
    }
    
}

