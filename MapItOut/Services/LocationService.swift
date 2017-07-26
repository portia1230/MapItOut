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
    static func rankDistance( items: [Item]) -> [Item] {
        let locationManager = CLLocationManager()
        let myLocation = getLocation(manager: locationManager)
        let location = CLLocation(latitude: myLocation.latitude, longitude: myLocation.longitude)
        var sortedItems : [Item] = []
        sortedItems = items.sorted { (entry1, entry2) -> Bool in
            let distanceOne = CLLocation(latitude: entry1.latitude, longitude: entry1.longitude)
            let distanceTwo = CLLocation(latitude: entry2.latitude, longitude: entry2.longitude)
            let magOne = distanceOne.distance(from: location).magnitude
            let magTwo = distanceTwo.distance(from: location).magnitude
            return (magOne) > (magTwo)
        }
        
        return sortedItems.reversed()
        
    }
    
    static func getLocation(manager: CLLocationManager) -> CLLocationCoordinate2D {
        var locValue = CLLocationCoordinate2DMake(0.0, 0.0)
        if manager.location != nil{
            locValue = manager.location!.coordinate
        }
        return locValue
    }
    
    static func getSpan(myLocation : CLLocation, items: [Item]) -> MKCoordinateSpan{
        var span = MKCoordinateSpan()
        if items.count == 0{
            span.latitudeDelta = 100
            span.longitudeDelta = 100
        } else {
            if items.count <= 3 {
                let location = CLLocation(latitude: items[items.count - 1].latitude, longitude: items[items.count - 1].longitude )
                span.latitudeDelta = myLocation.distance(from: location) / 55500
                span.longitudeDelta = myLocation.distance(from: location) / 55500
            } else {
                let location = CLLocation(latitude: items[3].latitude, longitude: items[3].longitude)
                span.latitudeDelta = myLocation.distance(from: location) / 55500
                span.longitudeDelta = myLocation.distance(from: location) / 55500
                
                
            }
        }
        
        return span
    }
}
