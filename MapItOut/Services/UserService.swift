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

struct UserService {
    
    static func addEntry(_ firUer: FIRUser, )
    
    
    
    //Create user
    static func create(_ firUser: FIRUser, name: String, email: String, completion: @escaping (User?) -> Void) {
        let data = [
            "username": name,
            "userEmail": email
        ]
        
        print("\(name) \(email)")
        
        let ref = Database.database().reference().child("users").child(firUser.uid)
        
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
        let ref = Database.database().reference().child("users").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let user = User(snapshot: snapshot) else {
                return completion(nil)
            }
            completion(user)
        })
    }
}
