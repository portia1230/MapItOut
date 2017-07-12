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
        var locationManager = CLLocationManager()
        let myLocation = getLocation(manager: locationManager)
        let location = CLLocation(latitude: myLocation.latitude, longitude: myLocation.longitude)
        var sortedEntries : [Entry] = []
        entries.sorted { (entry1, entry2) -> Bool in
            return (entry1.distance(to: location)) < (entry2.distance(to: location))
        }
        return entries
        
    }
    
    static func getLocation(manager: CLLocationManager) -> CLLocationCoordinate2D {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        return locValue
    }
}
