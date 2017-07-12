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

struct EntryService{
    
    static func addEntry(entry: Entry){
        let currentUser = User.currentUser
        let entryRef = Database.database().reference().child("Contacts").child(currentUser.uid).childByAutoId()
        let newKey = entryRef.key
        let newEntry = Entry(firstName: entry.firstName, lastName: entry.lastName, longitude: entry.longitude, latitude: entry.latitude, relationship: entry.relationship, imageURL: entry.imageURL, number: entry.number, email: entry.email, key: newKey, locationDescription: entry.locationDescription)
        
        User.currentUser.entries.append(newEntry)
        let userRef = Database.database().reference().child("Users").child(currentUser.uid).child("Contacts").child(newKey)
        let dict = newEntry.dictValue
        entryRef.setValue(dict)
        userRef.setValue(newKey)
        
    }
    
    static func deleteEntry(entry: Entry, index: Int){
        User.currentUser.entries.remove(at: index)
        let currentUser = User.currentUser
        //let dict = entry.dictValue
        let entryRef = Database.database().reference().child("Contacts").child(currentUser.uid).childByAutoId().child(entry.key)
        entryRef.removeValue()
    }
    
    static func editEntry(entry: Entry, index: Int){
        User.currentUser.entries.remove(at: index)
        User.currentUser.entries.append(entry)
        deleteEntry(entry: entry, index: index)
        addEntry(entry: entry)
    }
    
}

