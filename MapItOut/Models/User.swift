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

class User: NSObject {
    
    //MARK: - Properties
    
    let uid: String
    var userName: String = ""
    var userEmail: String = ""
    var entries: [Entry] = []
    private static var current: User?
    
    //MARK: - Init
    
    init(uid: String){
        self.uid = uid
        super.init()
    }
    
    init?(snapshot: DataSnapshot){
        guard (snapshot.value as? [String: Any]) != nil
        else { return nil }
        self.uid = snapshot.key
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let uid = aDecoder.decodeObject(forKey: "uid") as? String,
            let userName = aDecoder.decodeObject(forKey: "userName") as? String,
            let userEmail = aDecoder.decodeObject(forKey: "userEmail") as? String
            else { return nil }
        
        self.uid = uid
        self.userEmail = userEmail
        self.userName = userName
        
        super.init()
    }
    
    //MARK: - Functions
    static var currentUser: User{
        guard let currentUser = current else {
            fatalError("Error: Current user does not exist")
        }
        return currentUser
    }
    
    class func setCurrent (_ user: User, writeToUserDefaults : Bool = false){
        if writeToUserDefaults{
            let data = NSKeyedArchiver.archivedData(withRootObject: user)
            UserDefaults.standard.set(data,forKey: "currentUser")
        }
        current = user
    }
    
}

extension User: NSCoding {
    func encode(with aCoder: NSCoder) {
        aCoder.encode(uid, forKey: "uid")
        aCoder.encode(userName, forKey: "userName")
        aCoder.encode(userEmail, forKey: "userEmail")
    }
}



