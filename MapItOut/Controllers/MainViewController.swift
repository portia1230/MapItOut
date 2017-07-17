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
import QuartzCore


class MainViewController : UIViewController, MKMapViewDelegate{
    
    //MARK: - Properties
    
    @IBOutlet weak var contactAddressLabel: UILabel!
    @IBOutlet weak var contactRelationshipLabel: UILabel!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var contactImage: UIImageView!
    @IBOutlet weak var contactButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    var redColor = UIColor(red: 1, green: 47/255, blue: 43/255, alpha: 1)
    var selectedContact : Entry!
    var contactStore = CNContactStore()
    
    var locationManager = CLLocationManager()
    var contacts : [Entry] = []
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Lifecycles
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(true)
        
        let imageView = UIImageView()
        self.contactButton.isEnabled = false
        imageView.image = #imageLiteral(resourceName: "redPin.png")
        let annotations = self.mapView.annotations
        self.mapView.removeAnnotations(annotations)
//        let span = MKCoordinateSpanMake(10, 10)
//        let region = MKCoordinateRegionMake(LocationService.getLocation(manager: locationManager), span)
        var coordinate: CLLocationCoordinate2D!
//        self.mapView.setRegion(region, animated: true)
        
        UserService.contacts(for: User.currentUser) { (contacts) in
            self.contacts = contacts
            var i = 0
            while i < contacts.count{
                let imageURL = URL(string
                    : contacts[i].imageURL)
                imageView.kf.setImage(with: imageURL!)
                if imageView.image == nil{
                    self.viewWillAppear(true)
                } else {
                    let thisLongitude = contacts[i].longitude
                    let thisLatitude = contacts[i].latitude
                    coordinate = CLLocationCoordinate2DMake(thisLatitude, thisLongitude)
                    let anno = CustomPointAnnotation()
                    anno.image = imageView.image!
                    anno.coordinate = coordinate
                    anno.indexOfContact = i
                    self.mapView.addAnnotation(anno)
                }
                i += 1
            }
            
            if contacts.isEmpty{
                self.contactNameLabel.backgroundColor = UIColor.clear
                self.contactNameLabel.text = "No contact entered"
                self.contactAddressLabel.text = ""
                self.contactButton.isHidden = true
            } else {
                self.contactButton.isHidden = false
                
                var sortedContacts = LocationService.rankDistance(entries: self.contacts)
                let imageURL = URL(string: sortedContacts[0].imageURL)
                
                let coordinate = LocationService.getLocation(manager: self.locationManager)
                let myLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let contactLocation = CLLocation(latitude: sortedContacts[0].latitude, longitude: sortedContacts[0].longitude)
                self.selectedContact = sortedContacts[0]
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
            self.contactButton.isEnabled = true
            
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
            annotationView?.canShowCallout = false
        } else {
            annotationView?.annotation = annotation
        }
        let custum = annotation as! CustomPointAnnotation
        annotationView?.image = custum.image
        annotationView?.contentMode = UIViewContentMode.scaleAspectFill
        annotationView?.image = userImageForAnnotation(image: custum.image)
        annotationView?.centerOffset = CGPoint(x: 0, y: -43.4135)
        return annotationView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let coordinate = view.annotation?.coordinate
        let customView = view.annotation as! CustomPointAnnotation
        self.selectedContact = contacts[customView.indexOfContact]
        let url = URL(string: self.selectedContact.imageURL)
        self.contactImage.kf.setImage(with: url!)
        self.contactNameLabel.text = self.selectedContact.firstName + " " + self.selectedContact.lastName
        self.contactRelationshipLabel.text = self.selectedContact.relationship
        let location = LocationService.getLocation(manager: locationManager)
        let myLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let contactLocation = CLLocation(latitude: (coordinate?.latitude)!, longitude: (coordinate?.longitude)!)
        let distance = contactLocation.distance(from: myLocation)
        
        if distance > 1000.0
        {
            self.contactAddressLabel.text = " \(Int(distance/1000)) KM away"
        } else {
            self.contactAddressLabel.text = " \(Int((distance * 1000).rounded())/1000) M away"
        }
    }
    

    func userImageForAnnotation(image: UIImage) -> UIImage {
        let pinImage = UIImage(named: "redPin.png")
        //print(pinImage?.size.height)
        //print(pinImage?.size.width)
        let userPinImg : UIImage = UIImage(cgImage: pinImage!.cgImage!, scale: 52/7, orientation: .up)
        UIGraphicsBeginImageContextWithOptions(userPinImg.size, false, 0.0);
        
        userPinImg.draw(in: CGRect(origin: CGPoint.zero, size: userPinImg.size))
        
        let roundRect : CGRect = CGRect(x: 3, y: 3, width: userPinImg.size.width-6, height: userPinImg.size.width-6)
        let myUserImgView = UIImageView(frame: roundRect)
        myUserImgView.image = image
        myUserImgView.contentMode = UIViewContentMode.scaleAspectFill
        let layer: CALayer = myUserImgView.layer
        layer.masksToBounds = true
        layer.cornerRadius = myUserImgView.frame.size.width/2
        
        UIGraphicsBeginImageContextWithOptions(myUserImgView.bounds.size, myUserImgView.isOpaque, 0.0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        roundedImage?.draw(in: roundRect)
        
        let resultImg : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return resultImg
        
    }
    
    
    @IBAction func refreshButtonTapped(_ sender: Any) {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "redPin.png")
        let span = MKCoordinateSpanMake(10, 10)
        let region = MKCoordinateRegionMake(LocationService.getLocation(manager: locationManager), span)
        self.mapView.setRegion(region, animated: true)
            
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
                self.selectedContact = sortedContacts[0]
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

    @IBAction func detailsButtonTapped(_ sender: Any) {
        let popOverVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewController(withIdentifier: "PopUpViewController") as! PopUpViewController
        let imageURL = URL(string: self.selectedContact.imageURL)
        
        popOverVC.firstName = self.selectedContact.firstName
        popOverVC.lastName = self.selectedContact.lastName
        popOverVC.address = self.selectedContact.locationDescription
        popOverVC.relationship = self.selectedContact.relationship
        popOverVC.contactPhoto.kf.setImage(with: imageURL!)
        popOverVC.email = self.selectedContact.email
        popOverVC.phoneNumber = self.selectedContact.number
        popOverVC.latitude = self.selectedContact.latitude
        popOverVC.longitude = self.selectedContact.longitude
        popOverVC.keyOfContact = self.selectedContact.key
        
        self.addChildViewController(popOverVC)
        popOverVC.view.frame = self.view.frame
        self.view.addSubview(popOverVC.view)
        popOverVC.didMove(toParentViewController: self)
    }
    
}

