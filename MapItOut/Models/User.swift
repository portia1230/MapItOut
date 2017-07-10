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
    var name: String = ""
    var email: String = ""
    
    //MARK: - Init
    
    init(uid: String){
        self.uid = uid
    }
    
    init?(snapshot: DataSnapshot){
        guard let dic = snapshot.value as? [String: Any]
        else { return nil }
        self.uid = snapshot.key
    }
    
}
