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
    static func create(_ firUser: FIRUser, name: String, email: String, completion: @escaping (User?) -> Void) {
        let userName = ["name": name]
        let userEmail = ["email": email]
        
        print("\(name) \(email)")
        
        let ref = Database.database().reference().child("users").child(firUser.uid)
        ref.setValue(userName) { (error, ref) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return completion(nil)
            }
        ref.setValue(userEmail) { (error, ref) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return completion(nil)
        }
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            let user = User(snapshot: snapshot)
            completion(user)
        })
    }
    }
}
}
