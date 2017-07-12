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
            if contacts.isEmpty{
                self.contactNameLabel.text = "No contact entered"
                self.contactAddressLabel.text = ""
                self.contactButton.isHidden = true
            } else {
                self.contactButton.isHidden = false
                var sortedContacts = LocationService.rankDistance(entries: contacts)
                let imageURL = URL(string: sortedContacts[0].imageURL)
                self.contactAddressLabel.text = sortedContacts[0].locationDescription
                let coordinate = LocationService.getLocation(manager: self.locationManager)
                let myLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let contactLocation = CLLocation(latitude: sortedContacts[0].latitude, longitude: sortedContacts[0].longitude)
                
                let distance = myLocation.distance(from: contactLocation)
                
                if distance > 1000.0
                {
                    self.contactAddressLabel.text = " \(Int(distance/1000)) KM away"
                } else {
                    self.contactAddressLabel.text = " \(Int((distance * 1000).rounded())/1000) M away"
                }
                self.contactNameLabel.text = sortedContacts[0].firstName + " " + sortedContacts[0].lastName
                self.contactRelationshipLabel.text = sortedContacts[0].relationship
                self.contactImage.kf.setImage(with: imageURL)
            }
            
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
