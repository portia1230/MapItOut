//
//  UserService.swift
//  MapItOut
//
//  Created by Portia Wang on 7/9/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import Foundation
import FirebaseAuth.FIRUser
import FirebaseDatabase
import CoreData
import Kingfisher

struct UserService {
    
    //Create user
    static func create(_ firUser: FIRUser, email: String, completion: @escaping (User?) -> Void) {
        let data = [
            "userEmail": email
        ]
        
        let ref = Database.database().reference().child("Users").child(firUser.uid)
        
        ref.setValue(data) { (error, ref) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return completion(nil)
            }
        }
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            let user = User(snapshot: snapshot)
            completion(user)
        })
    }
    
    
    
    //show user
    static func show(forUID uid: String, completion: @escaping (User?) -> Void) {
        let ref = Database.database().reference().child("Users").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let user = User(snapshot: snapshot) else {
                return completion(nil)
            }
            completion(user)
        })
    }
    
    
    
    static func items(for user: User, completion: @escaping ([Entry]) -> Void) {
        let ref = Database.database().reference().child("Items").child(user.uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot] else {
                return completion([])
            }
            
            let dispatchGroup = DispatchGroup()
            
            let contacts: [Entry] =
                snapshot
                    .reversed()
                    .flatMap {
                        guard let contact = Entry(snapshot: $0)
                            else { return nil }
                        return contact
            }
            //User.currentUser.entries = contacts
            updateItems(contacts: contacts)
            
            dispatchGroup.notify(queue: .main, execute: {
                completion(contacts)
            })
        })
    }
    
    static func updateItems(contacts: [Entry]){
        var items = CoreDataHelper.retrieveItems()
        items.removeAll()
        for entry in contacts{
            let imageView = UIImageView()
            let item = Item()
            item.email = entry.email
            item.key = entry.key
            item.longitude = entry.longitude
            item.latitude = entry.latitude
            item.name = entry.name
            item.type = entry.type
            item.organization = entry.organization
            item.locationDescription = entry.locationDescription
            item.phone = entry.phone
            
            let url = URL(string: entry.imageURL)
            
            imageView.kf.setImage(with: url)
            if imageView.image != nil{
                item.image = imageView.image
                items.append(item)
            } else {
                updateItems(contacts: contacts)
            }
            CoreDataHelper.saveItem()
        }

    }
    
}









