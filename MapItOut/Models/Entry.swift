//
//  Entry.swift
//  MapItOut
//
//  Created by Portia Wang on 7/9/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import FirebaseDatabase.FIRDataSnapshot

class Entry {
    var key: String?
    var firstName: String
    var lastName: String
    var location: CLLocationCoordinate2D
    var relationship: String
    var imageURL: String
    var number: String
    var email: String
    var dictValue: [String : Any]{
        return ["firstName": firstName,
                "lastName": lastName,
                "location": location,
                "relationship": relationship,
                "imageURL": imageURL,
                "number": number,
                "email": email  ]
    }
    
    init( firstName: String, lastName: String, location: CLLocationCoordinate2D, relationship: String, imageURL: String, number: String, email: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.location = location
        self.relationship = relationship
        self.imageURL = imageURL
        self.number = number
        self.email = email
    }
    
    
    
}









