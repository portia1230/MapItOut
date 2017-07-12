//
//  MainViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/9/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import MapKit

class MainViewController : UIViewController{
    
    //MARK: - Properties
    
    @IBOutlet weak var contactAddressLabel: UILabel!
    @IBOutlet weak var contactRelationshipLabel: UILabel!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var contactImage: UIImageView!
    @IBOutlet weak var contactButton: UIButton!
    
    var locationManager = CLLocationManager()
    var contacts : [Entry] = []
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Lifecycles
    
    override func viewWillAppear(_ animated: Bool) {
        
        UserService.contacts(for: User.currentUser) { (contacts) in
            var sortedContacts = LocationService.rankDistance(entries: contacts)
            self.contacts = sortedContacts
            let imageURL = URL(string: contacts[0].imageURL)
            self.contactAddressLabel.text = contacts[0].locationDescription
            let coordinate = LocationService.getLocation(manager: self.locationManager)
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distance = self.contacts[0].distance(to: location)
            let km = Int(distance/1000)
            if distance > 1000
            {
                self.contactAddressLabel.text = " \(km) KM away"
            } else {
                self.contactAddressLabel.text = " \(((distance * 1000).rounded())/1000) M away"
            }
            self.contactNameLabel.text = contacts[0].firstName + " " + contacts[0].lastName
            self.contactRelationshipLabel.text = contacts[0].relationship
            self.contactImage.kf.setImage(with: imageURL)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //fittng the photo
        contactImage.layer.cornerRadius = 35
        contactButton.layer.cornerRadius = 15
        contactImage.clipsToBounds = true
        
        
        
    }
}
