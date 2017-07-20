//
//  LocationService.swift
//  MapItOut
//
//  Created by Portia Wang on 7/12/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import Foundation
import UIKit
import MapKit

struct LocationService{
    static func rankDistance( entries: [Entry]) -> [Entry] {
        let locationManager = CLLocationManager()
        let myLocation = getLocation(manager: locationManager)
        let location = CLLocation(latitude: myLocation.latitude, longitude: myLocation.longitude)
        var sortedEntries : [Entry] = []
        sortedEntries = entries.sorted { (entry1, entry2) -> Bool in
            return (entry1.distance(to: location).magnitude) > (entry2.distance(to: location).magnitude)
        }
        
        return sortedEntries.reversed()
        
    }
    
    static func getLocation(manager: CLLocationManager) -> CLLocationCoordinate2D {
        var locValue = CLLocationCoordinate2DMake(0.0, 0.0)
        if manager.location != nil{
            locValue = manager.location!.coordinate
        }
        return locValue
    }
}
