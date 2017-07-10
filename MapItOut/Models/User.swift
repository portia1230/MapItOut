//
//  User.swift
//  MapItOut
//
//  Created by Portia Wang on 7/9/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import Foundation
import FirebaseDatabase.FIRDataSnapshot
import Firebase

class User {
    
    //MARK: - Properties
    
    let uid: String
    var userName: String = ""
    var userEmail: String = ""
    private static var current: User?
    
    //MARK: - Init
    
    init(uid: String){
        self.uid = uid
    }
    
    init?(snapshot: DataSnapshot){
        guard let dic = snapshot.value as? [String: Any]
        else { return nil }
        self.uid = snapshot.key
    }
    
    //MARK: - Functions
    static var currentUser: User{
        guard let currentUser = current else {
            fatalError("Error: Current user does not exist")
        }
        return currentUser
    }
    
    static func setCurrent(_ user : User){
        current = user
    }
    
}
