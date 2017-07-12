//
//  GeocodingLocationService.swift
//  MapItOut
//
//  Created by Portia Wang on 7/11/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import Foundation
import MapKit
import AddressBookUI

struct LocationService {
    static func reverseGeocoding(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> String {
        var trimmed = ""
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) -> Void in
            if error != nil{
                print(error as Any)
                return
            } else if (placemarks?.count)! > 0 {
                let pm = placemarks![0]
                let address = ABCreateStringWithAddressDictionary(pm.addressDictionary!, false)
                trimmed = address
            }
            trimmed = trimmed.replacingOccurrences(of: "\n", with: ", ")
        }
        return trimmed
    }
    
}
