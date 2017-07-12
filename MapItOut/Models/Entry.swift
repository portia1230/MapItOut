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
    var locationDescription: String
    var dictValue: [String : Any]{
        return ["firstName": firstName,
                "lastName": lastName,
                "longitude": longitude,
                "latitude": latitude,
                "relationship": relationship,
                "imageURL": imageURL,
                "number": number,
                "email": email,
                "key": key,
                "locationDescription": locationDescription]
    }
    
    init( firstName: String, lastName: String, longitude: CLLocationDegrees, latitude: CLLocationDegrees, relationship: String, imageURL: String, number: String, email: String, key: String, locationDescription: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.longitude = longitude
        self.latitude = latitude
        self.relationship = relationship
        self.imageURL = imageURL
        self.number = number
        self.email = email
        self.key = key
        self.locationDescription = locationDescription
    }
    
    init?(snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? [String : Any],
            let imageURL = dict["imageURL"] as? String,
            let firstName = dict["firstName"] as? String,
            let lastName = dict["lastName"] as? String,
            let longitude = dict["longitude"] as? Double,
            let latitude = dict["latitude"] as? Double,
            let relationship = dict["relationship"] as? String,
            let number = dict["number"] as? String,
            let email = dict["email"] as? String,
            let key = dict["key"] as? String,
            let locationDescription = dict["locationDescription"] as? String
            else { return nil }
        
        self.key = key
        self.imageURL = imageURL
        self.firstName = firstName
        self.lastName = lastName
        self.longitude = longitude
        self.latitude = latitude
        self.relationship = relationship
        self.number = number
        self.email = email
        self.locationDescription = locationDescription
    }
    
}









