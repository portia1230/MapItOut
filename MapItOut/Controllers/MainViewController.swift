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
import FirebaseAuth
import CoreLocation

class MainViewController : UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{
    
    //MARK: - Properties
    @IBOutlet weak var locationImage: UIImageView!
    
    @IBOutlet weak var contactAddressLabel: UILabel!
    @IBOutlet weak var contactRelationshipLabel: UILabel!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var contactImage: UIImageView!
    @IBOutlet weak var contactButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    var redColor = UIColor(red: 1, green: 47/255, blue: 43/255, alpha: 1)
    var selectedContact : Entry!
    var contacts : [Entry] = []
    var isUpdatingHeading = false
    
    var contactStore = CNContactStore()
    var locationManager = CLLocationManager()
    var authHandle: AuthStateDidChangeListenerHandle?
    
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
        let span = MKCoordinateSpanMake(100, 100)
        let region = MKCoordinateRegionMake(mapView.userLocation.coordinate, span)
        var coordinate: CLLocationCoordinate2D!
        self.mapView.setRegion(region, animated: true)
        
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
                let contactLocation = CLLocation(latitude: sortedContacts[0].latitude, longitude: sortedContacts[0].longitude)
                self.selectedContact = sortedContacts[0]
                let distance = contactLocation.distance(from: self.mapView.userLocation.location!)
                
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
        locationManager.delegate = self
        authHandle = Auth.auth().addStateDidChangeListener() { [unowned self] (auth, user) in
            guard user == nil else { return }
            
            let loginViewController = UIStoryboard.initialViewController(for: .login)
            self.view.window?.rootViewController = loginViewController
            self.view.window?.makeKeyAndVisible()
        }
    }
    
    deinit {
        if let authHandle = authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }
    
    //MARK: - Location Manager Functions
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        mapView.camera.heading = newHeading.magneticHeading
        mapView.setCamera(mapView.camera, animated: true)
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
        if(view.annotation is MKUserLocation){
        } else {
            let coordinate = view.annotation?.coordinate
            
            let customView = view.annotation as! CustomPointAnnotation
            self.selectedContact = contacts[customView.indexOfContact]
            let url = URL(string: self.selectedContact.imageURL)
            self.contactImage.kf.setImage(with: url!)
            self.contactNameLabel.text = self.selectedContact.firstName + " " + self.selectedContact.lastName
            self.contactRelationshipLabel.text = self.selectedContact.relationship
            let contactLocation = CLLocation(latitude: (coordinate?.latitude)!, longitude: (coordinate?.longitude)!)
            let distance = contactLocation.distance(from: self.mapView.userLocation.location!)
            
            if distance > 1000.0
            {
                self.contactAddressLabel.text = " \(Int(distance/1000)) KM away"
            } else {
                self.contactAddressLabel.text = " \(Int((distance * 1000).rounded())/1000) M away"
            }
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
        UIGraphicsBeginImageContextWithOptions(myUserImgView.bounds.size, false, 0.0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        roundedImage?.draw(in: roundRect)
        
        let resultImg : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return resultImg
        
    }
    //MARK: - Buttons Tapped
    
    @IBAction func settingButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Settings", message: nil, preferredStyle: .actionSheet)
        let signOutAction = UIAlertAction(title: "Sign out", style: .default) { _ in
            do {
                try Auth.auth().signOut()
            } catch let error as NSError {
                assertionFailure("Error signing out: \(error.localizedDescription)")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(signOutAction)
        self.present(alertController, animated: true)
    }
    
    @IBAction func refreshButtonTapped(_ sender: Any) {
        if isUpdatingHeading == false {
            self.isUpdatingHeading = true
            self.locationImage.image = #imageLiteral(resourceName: "selectedFindcontact.png")
            self.locationManager.startUpdatingHeading()
        } else {
            self.isUpdatingHeading = false
            let span = MKCoordinateSpanMake(100, 100)
            let region = MKCoordinateRegionMake(self.mapView.userLocation.coordinate, span)
            self.mapView.setRegion(region, animated: true)
            self.locationImage.image = #imageLiteral(resourceName: "findContact.png")
            self.locationManager.stopUpdatingHeading()
            self.mapView.isRotateEnabled = false
            
        }
        usleep(700000) //sleep for 0.4 second
        
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
        UIView.transition(with: self.view, duration: 0.3, options: .transitionCrossDissolve, animations: { _ in
            self.view.addSubview(popOverVC.view)
        }, completion: nil)
        popOverVC.didMove(toParentViewController: self)
    }
    
    
    
}

