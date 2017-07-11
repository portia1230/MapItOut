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
    var key: String
    var firstName: String
    var lastName: String
    var longitude: CLLocationDegrees
    var latitude: CLLocationDegrees
    var relationship: String
    var imageURL: String
    var number: String
    var email: String
    var dictValue: [String : Any]{
        return ["firstName": firstName,
                "lastName": lastName,
                "longitude": longitude,
                "latitude": latitude,
                "relationship": relationship,
                "imageURL": imageURL,
                "number": number,
                "email": email,
                "key": key]
    }
    
    init( firstName: String, lastName: String, longitude: CLLocationDegrees, latitude: CLLocationDegrees, relationship: String, imageURL: String, number: String, email: String, key: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.longitude = longitude
        self.latitude = latitude
        self.relationship = relationship
        self.imageURL = imageURL
        self.number = number
        self.email = email
        self.key = key
    }
    
    
    
}









