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

class Entry : User {
    var name: String
    var location: CLLocationCoordinate2D
    var relationship: String
    var imageURL: String
    var number: String
    
    init( uid: String, name: String, location: CLLocationCoordinate2D, relationship: String, imageURL: String, number: String) {
        self.name = name
        self.location = location
        self.relationship = relationship
        self.imageURL = imageURL
        self.number = number
        super.init(uid: uid)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}









