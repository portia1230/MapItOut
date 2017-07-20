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
import FirebaseDatabase

class MainViewController : UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{
    
    //MARK: - Properties
    
    @IBOutlet weak var locationImage: UIImageView!
    @IBOutlet weak var contactAddressLabel: UILabel!
    @IBOutlet weak var contactRelationshipLabel: UILabel!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var contactImage: UIImageView!
    @IBOutlet weak var contactButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    var images = [UIImage]()
    var redColor = UIColor(red: 1, green: 47/255, blue: 43/255, alpha: 1)
    var selectedContact : Entry!
    var sortedContacts : [Entry] = []
    var isUpdatingHeading = false
    var editedAnno = MKPointAnnotation()
    var selectedIndex = 0
    
    var contactStore = CNContactStore()
    var locationManager = CLLocationManager()
    var authHandle: AuthStateDidChangeListenerHandle?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Lifecycles
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(true)
            
        self.images.removeAll()
        self.mapView.userLocation.subtitle = ""
        self.mapView.userLocation.title = ""
        //var allImages = [UIImage]()
        let imageView = UIImageView()
        //imageView.image = #imageLiteral(resourceName: "redPin.png")
        self.contactButton.isEnabled = false
        let annotations = self.mapView.annotations
        self.mapView.removeAnnotations(annotations)
        let span = MKCoordinateSpanMake(100, 100)
        let region = MKCoordinateRegionMake(LocationService.getLocation(manager: locationManager), span)
        var coordinate: CLLocationCoordinate2D!
        self.mapView.setRegion(region, animated: true)
        
        UserService.contacts(for: User.currentUser) { (contacts) in
            User.currentUser.entries = contacts
            self.sortedContacts = LocationService.rankDistance(entries: contacts)
            var i = 0
            let allAnnos = self.mapView.annotations
            self.mapView.removeAnnotations(allAnnos)
            while i < self.sortedContacts.count{
                let imageURL = URL(string
                    : contacts[i].lowImageURL)
                imageView.kf.setImage(with: imageURL)
                let thisLongitude = contacts[i].longitude
                let thisLatitude = contacts[i].latitude
                coordinate = CLLocationCoordinate2DMake(thisLatitude, thisLongitude)
                let anno = CustomPointAnnotation()
                anno.coordinate = coordinate
                anno.indexOfContact = i
                self.mapView.addAnnotation(anno)
                
                if imageView.image == nil{
                    self.viewWillAppear(true)
                } else {
                    anno.image = imageView.image!
                    self.images.append(imageView.image!)
                    if (self.images.count == User.currentUser.entries.count ) && ( self.sortedContacts.count == User.currentUser.entries.count ){
                        //self.mapView.addAnnotation(anno)
                        self.finishLoading()
                        
                    }
                }
                i += 1
            }
        }
    }
    //self.images = allImages
    
    func finishLoading(){
        
        if User.currentUser.entries.isEmpty{
            self.contactNameLabel.backgroundColor = UIColor.clear
            self.contactNameLabel.text = "No contact entered"
            self.contactAddressLabel.text = ""
            self.contactButton.isHidden = true
        } else {
            self.contactButton.isHidden = false
            
            self.sortedContacts = LocationService.rankDistance(entries: User.currentUser.entries)
            
            let coordinate = LocationService.getLocation(manager: self.locationManager)
            let myLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let contactLocation = CLLocation(latitude: self.sortedContacts[0].latitude, longitude: self.sortedContacts[0].longitude)
            self.selectedContact = self.sortedContacts[0]
            
            var n = 0
            while n < User.currentUser.entries.count {
                if User.currentUser.entries[n].key == self.selectedContact.key{
                    self.selectedIndex = n
                }
                n += 1
            }
            
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
            self.contactNameLabel.text = self.sortedContacts[0].firstName + " " + self.sortedContacts[0].lastName
            self.contactRelationshipLabel.text = self.sortedContacts[0].relationship
            self.contactImage.image = self.images[self.selectedIndex]
            self.contactButton.isEnabled = true
            //self.mapView.addAnnotations(anno)
            
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
    
    //MARK: - Update annotations
    
    func newValue(entry: Entry, image: UIImage){
        User.currentUser.entries.append(entry)
        let coordinate = CLLocationCoordinate2DMake(entry.latitude, entry.longitude)
        let anno = CustomPointAnnotation()
        anno.coordinate = coordinate
        anno.image = image
        self.images.append(image)
        self.selectedIndex = User.currentUser.entries.count - 1
        self.sortedContacts = LocationService.rankDistance(entries: User.currentUser.entries)
        
        let myCoordinate = LocationService.getLocation(manager: self.locationManager)
        let myLocation = CLLocation(latitude: myCoordinate.latitude, longitude: myCoordinate.longitude)
        let contactLocation = CLLocation(latitude: User.currentUser.entries[self.selectedIndex].latitude, longitude: User.currentUser.entries[self.selectedIndex].longitude)
        
        self.mapView.addAnnotation(anno)
        
        let distance = myLocation.distance(from: contactLocation)
        
        if distance > 1000.0
        {
            self.contactAddressLabel.text = " \(Int(distance/1000)) KM away"
        } else {
            self.contactAddressLabel.text = " \(Int((distance * 1000).rounded())/1000) M away"
        }
        self.contactNameLabel.text = User.currentUser.entries[selectedIndex].firstName + " " + User.currentUser.entries[selectedIndex].lastName
        self.contactRelationshipLabel.text = User.currentUser.entries[selectedIndex].relationship
        self.contactImage.image = self.images[self.selectedIndex]
        self.contactButton.isEnabled = true
    }
    
    
    func updateValue(entry: Entry, image: UIImage){
        self.mapView.removeAnnotation(self.editedAnno)
        User.currentUser.entries.remove(at: self.selectedIndex)
        User.currentUser.entries.insert(entry, at: self.selectedIndex)
        self.mapView.removeAnnotation(self.editedAnno)
        let coordinate = CLLocationCoordinate2DMake(entry.latitude, entry.longitude)
        let anno = CustomPointAnnotation()
        anno.coordinate = coordinate
        anno.image = image
        self.images.remove(at: selectedIndex)
        self.images.insert(image, at: selectedIndex)
        
        self.sortedContacts = LocationService.rankDistance(entries: User.currentUser.entries)
        
        let myCoordinate = LocationService.getLocation(manager: self.locationManager)
        let myLocation = CLLocation(latitude: myCoordinate.latitude, longitude: myCoordinate.longitude)
        let contactLocation = CLLocation(latitude: User.currentUser.entries[self.selectedIndex].latitude, longitude: User.currentUser.entries[self.selectedIndex].longitude)
        
        self.mapView.addAnnotation(anno)
        
        let distance = myLocation.distance(from: contactLocation)
        
        if distance > 1000.0
        {
            self.contactAddressLabel.text = " \(Int(distance/1000)) KM away"
        } else {
            self.contactAddressLabel.text = " \(Int((distance * 1000).rounded())/1000) M away"
        }
        self.contactNameLabel.text = User.currentUser.entries[selectedIndex].firstName + " " + User.currentUser.entries[selectedIndex].lastName
        self.contactRelationshipLabel.text = User.currentUser.entries[selectedIndex].relationship
        self.contactImage.image = self.images[self.selectedIndex]
        self.contactButton.isEnabled = true
    }
    
    
    //MARK: - Location Manager Functions
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        mapView.camera.heading = newHeading.magneticHeading
        mapView.setCamera(mapView.camera, animated: true)
    }
    
    //MARK: - Functions
    
    @IBAction func addButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: "How would you like to create a new contact", preferredStyle: .alert)
        
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
                    } else {
                        self.performSegue(withIdentifier: "contactsSegue", sender: self)
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
        let custom = annotation as! CustomPointAnnotation
        annotationView?.image = custom.image
        annotationView?.contentMode = UIViewContentMode.scaleAspectFill
        annotationView?.image = userImageForAnnotation(image: custom.image)
        annotationView?.centerOffset = CGPoint(x: 0, y: -43.4135)
        return annotationView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if(view.annotation is MKUserLocation){
        } else {
            let coordinate = view.annotation?.coordinate
            self.editedAnno = view.annotation! as! CustomPointAnnotation
            
            var i = 0
            while i < User.currentUser.entries.count{
                if (User.currentUser.entries[i].latitude == self.editedAnno.coordinate.latitude) && ( User.currentUser.entries[i].longitude == self.editedAnno.coordinate.longitude){
                    self.selectedContact = User.currentUser.entries[i]
                    self.selectedIndex = i
                    break
                }
                i += 1
            }
            
            self.contactImage.image = self.images[selectedIndex]
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
        let resetPasswordAction = UIAlertAction(title: "Reset password", style: .default) { _ in
            do {
                Auth.auth().sendPasswordReset(withEmail: (Auth.auth().currentUser?.email)!) { error in
                    let alertController = UIAlertController(title: nil, message: "An reset password email has been sent to \((Auth.auth().currentUser?.email)!)", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true)
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(signOutAction)
        alertController.addAction(resetPasswordAction)
        self.present(alertController, animated: true)
    }
    
    @IBAction func refreshButtonTapped(_ sender: Any) {
        if isUpdatingHeading == false {
            self.isUpdatingHeading = true
            self.locationImage.image = #imageLiteral(resourceName: "selectedFindcontact.png")
            self.locationManager.startUpdatingHeading()
        } else {
            self.locationImage.image = #imageLiteral(resourceName: "findContact.png")
            self.locationManager.stopUpdatingHeading()
            self.mapView.isRotateEnabled = false
            self.isUpdatingHeading = false
            usleep(500000) //sleep for 0.1 second
            let span = MKCoordinateSpanMake(100, 100)
            let region = MKCoordinateRegionMake(LocationService.getLocation(manager: locationManager), span)
            self.mapView.setRegion(region, animated: true)
        }
        
    }
    
    @IBAction func detailsButtonTapped(_ sender: Any) {
        
        let popOverVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewController(withIdentifier: "PopUpViewController") as! PopUpViewController
        //let imageURL = URL(string: self.selectedContact.imageURL)
        
        popOverVC.contactPhoto.image = self.images[selectedIndex]
        popOverVC.firstName = self.selectedContact.firstName
        popOverVC.lastName = self.selectedContact.lastName
        popOverVC.address = self.selectedContact.locationDescription
        popOverVC.relationship = self.selectedContact.relationship
        //popOverVC.contactPhoto.kf.setImage(with: imageURL!)
        popOverVC.email = self.selectedContact.email
        popOverVC.phoneNumber = self.selectedContact.number
        popOverVC.latitude = self.selectedContact.latitude
        popOverVC.longitude = self.selectedContact.longitude
        popOverVC.keyOfContact = self.selectedContact.key
        
        self.addChildViewController(popOverVC)
        popOverVC.view.frame = self.view.frame
        UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
            self.view.addSubview(popOverVC.view)
        }, completion: nil)
        popOverVC.didMove(toParentViewController: self)
    }
    
    
    
}
