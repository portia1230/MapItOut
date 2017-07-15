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
import ContactsUI

class MainViewController : UIViewController, MKMapViewDelegate{
    
    //MARK: - Properties
    
    @IBOutlet weak var contactAddressLabel: UILabel!
    @IBOutlet weak var contactRelationshipLabel: UILabel!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var contactImage: UIImageView!
    @IBOutlet weak var contactButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    var redColor = UIColor(red: 1, green: 47/255, blue: 43/255, alpha: 1)
    
    var contactStore = CNContactStore()
    
    var locationManager = CLLocationManager()
    var contacts : [Entry] = []
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Lifecycles
    
    override func viewWillAppear(_ animated: Bool) {
        
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "redPin.png")
        let annotations = self.mapView.annotations
        self.mapView.removeAnnotations(annotations)
        let span = MKCoordinateSpanMake(100, 100)
        let region = MKCoordinateRegionMake(LocationService.getLocation(manager: locationManager), span)
        var coordinate: CLLocationCoordinate2D!
        
        
        self.mapView.setRegion(region, animated: false)
        UserService.contacts(for: User.currentUser) { (contacts) in
            self.contacts = contacts
            for contact in contacts{
                let imageURL = URL(string
                    : contact.imageURL)
                
                imageView.kf.setImage(with: imageURL!)
                
                if imageView.image == nil{
                    self.viewWillAppear(true)
                } else {
                let thisLongitude = contact.longitude
                let thisLatitude = contact.latitude
                coordinate = CLLocationCoordinate2DMake(thisLatitude, thisLongitude)
                var anno = CustomPointAnnotation()
                anno.image = imageView.image!
                anno.coordinate = coordinate
                self.mapView.addAnnotation(anno)
                    
                }
            }
            
            if contacts.isEmpty{
                self.contactNameLabel.backgroundColor = UIColor.clear
                self.contactNameLabel.text = "No contact entered"
                self.contactAddressLabel.text = ""
                self.contactButton.isHidden = true
            } else {
                self.contactButton.isHidden = false
                var sortedContacts = LocationService.rankDistance(entries: contacts)
                let imageURL = URL(string: sortedContacts[0].imageURL)
                let coordinate = LocationService.getLocation(manager: self.locationManager)
                let myLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let contactLocation = CLLocation(latitude: sortedContacts[0].latitude, longitude: sortedContacts[0].longitude)
                
                let distance = myLocation.distance(from: contactLocation)
                
                self.contactAddressLabel.backgroundColor = UIColor.clear
                self.contactNameLabel.backgroundColor = UIColor.clear
                self.contactRelationshipLabel.backgroundColor = UIColor.clear
                
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
        mapView.delegate = self
        contactImage.layer.cornerRadius = 35
        contactButton.layer.cornerRadius = 15
        contactImage.clipsToBounds = true
        
    }
    
    
    //MARK: - Functions
    
    @IBAction func addButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: "How would you like to create a new contact", preferredStyle: .actionSheet)
        
        //Import from Contacts segue
        alert.addAction(UIAlertAction(title: "Import from Contacts", style: .default, handler:  { action in
            let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
            switch authorizationStatus {
            case .authorized:
                print("Authorized")
                self.performSegue(withIdentifier: "contactsSegue", sender: self)
            case .notDetermined: // needs to ask for authorization
                self.contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (accessGranted, error) -> Void in
                    if error != nil{
                        let alertController = UIAlertController(title: nil, message:
                            "We do not have access to your Contacts, please go to Settings/ Privacy/ Contacts and give us permission", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "Okay!", style: UIAlertActionStyle.cancel,handler: nil ))
                        self.present(alertController, animated: true, completion: nil)
                    }
                })
            default:
                let alertController = UIAlertController(title: nil, message:
                    "We do not have access to your Contacts, please go to Settings/ Privacy/ Contacts and give us permission", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Okay!", style: .cancel,handler: nil ))
                self.present(alertController, animated: true, completion: nil)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Create new contact", style: .default, handler:  { action in self.performSegue(withIdentifier: "addContactSegue", sender: self) }))
        alert.addAction(UIAlertAction(title: "Back", style: .cancel , handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if(annotation is MKUserLocation){
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "pinIdentifier")
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "pinIdentifier")
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        let custum = annotation as! CustomPointAnnotation
        
        annotationView!.image = custum.image
        annotationView?.contentMode = UIViewContentMode.scaleAspectFill
        annotationView?.frame.size = CGSize(width: 52, height: 52)
        annotationView?.layer.cornerRadius = 25
        annotationView?.layer.borderColor = redColor.cgColor
        annotationView?.layer.borderWidth = 2
        return annotationView

    }
    
    
}
