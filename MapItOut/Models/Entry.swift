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
    var name: String
    var location: CLLocationCoordinate2D
    var relationship: String
    var imageURL: String
    var number: String
    var dictValue: [String : Any]{
        return ["name": name,
                "location": location,
                "relationship": relationship,
                "imageURL": imageURL,
                "number": number]
    }
    
    init( name: String, location: CLLocationCoordinate2D, relationship: String, imageURL: String, number: String) {
        self.name = name
        self.location = location
        self.relationship = relationship
        self.imageURL = imageURL
        self.number = number
    }
    
    
    
}









