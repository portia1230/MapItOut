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
    var name: String
    var organization: String
    var longitude: CLLocationDegrees
    var latitude: CLLocationDegrees
    var type: String
    var imageURL: String
    var phone: String
    var email: String
    var locationDescription: String
    var contactKey : String
    var dictValue: [String : Any]{
        return ["name": name,
                "organization": organization,
                "longitude": longitude,
                "latitude": latitude,
                "type": type,
                "imageURL": imageURL,
                "phone": phone,
                "email": email,
                "key": key,
                "locationDescription": locationDescription,
                "contactKey": contactKey]
    }
    
    init( name: String, organization: String, longitude: CLLocationDegrees, latitude: CLLocationDegrees, type: String, imageURL: String, phone: String, email: String, key: String, locationDescription: String, contactKey: String) {
        self.name = name
        self.organization = organization
        self.longitude = longitude
        self.latitude = latitude
        self.type = type
        self.imageURL = imageURL
        self.phone = phone
        self.email = email
        self.key = key
        self.locationDescription = locationDescription
        self.contactKey = contactKey
    }
    
    init?(snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? [String : Any],
            let imageURL = dict["imageURL"] as? String,
            let name = dict["name"] as? String,
            let organization = dict["organization"] as? String,
            let longitude = dict["longitude"] as? Double,
            let latitude = dict["latitude"] as? Double,
            let type = dict["type"] as? String,
            let phone = dict["phone"] as? String,
            let email = dict["email"] as? String,
            let key = dict["key"] as? String,
            let locationDescription = dict["locationDescription"] as? String,
            let contactKey = dict["contactKey"] as? String
            else { return nil }
        
        self.key = key
        self.imageURL = imageURL
        self.name = name
        self.organization = organization
        self.longitude = longitude
        self.latitude = latitude
        self.type = type
        self.phone = phone
        self.email = email
        self.locationDescription = locationDescription
        self.contactKey = contactKey
    }
    
    func distance(to location: CLLocation) -> CLLocationDistance {
        let contactLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        return contactLocation.distance(from: location)
    }
    
}









