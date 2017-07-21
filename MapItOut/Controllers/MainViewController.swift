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
    @IBOutlet weak var itemDistanceLabel: UILabel!
    @IBOutlet weak var itemTypeLabel: UILabel!
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var detailsButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var itemNameLabel: UILabel!
    
    var redColor = UIColor(red: 1, green: 47/255, blue: 43/255, alpha: 1)
    var selectedItem : Item!
    var sortedItems : [Item] = []
    var isUpdatingHeading = false
    var editedAnno = MKPointAnnotation()
    var selectedIndex = 0
    var isUpdated = false
    
    var contactStore = CNContactStore()
    var locationManager = CLLocationManager()
    var authHandle: AuthStateDidChangeListenerHandle?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Lifecycles
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(true)
        
        self.mapView.userLocation.subtitle = ""
        self.mapView.userLocation.title = ""
        
        self.detailsButton.isEnabled = false
        let annotations = self.mapView.annotations
        self.mapView.removeAnnotations(annotations)
        let span = MKCoordinateSpanMake(100, 100)
        let region = MKCoordinateRegionMake(LocationService.getLocation(manager: locationManager), span)
        self.mapView.setRegion(region, animated: true)
        let items = CoreDataHelper.retrieveItems()
        var i = 0
        while i < items.count {
            let longitude = items[i].longitude
            let latitude = items[i].latitude
            let anno = CustomPointAnnotation()
            anno.image = items[i].image as! UIImage
            anno.indexOfContact = i
            anno.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
            self.mapView.addAnnotation(anno)
            i += 1
        }
        
        let sortedItems = LocationService.rankDistance(items: items)
        self.sortedItems = sortedItems
        if sortedItems.isEmpty{
            self.itemNameLabel.backgroundColor = UIColor.clear
            self.itemNameLabel.text = "No contact entered"
            self.itemDistanceLabel.text = ""
            self.detailsButton.isHidden = true
        } else {
            let coordinate = LocationService.getLocation(manager: self.locationManager)
            let myLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let contactLocation = CLLocation(latitude: sortedItems[0].latitude, longitude: sortedItems[0].longitude)
            self.selectedItem = sortedItems[0]
            
            var n = 0
            while n < items.count {
                if items[n].key == self.selectedItem.key{
                    self.selectedIndex = n
                }
                n += 1
            }
            
            let distance = myLocation.distance(from: contactLocation)
            self.itemDistanceLabel.backgroundColor = UIColor.clear
            self.itemNameLabel.backgroundColor = UIColor.clear
            self.itemTypeLabel.backgroundColor = UIColor.clear
            
            if distance > 1000.0
            {
                self.itemDistanceLabel.text = " \(Int(distance/1000)) KM away"
            } else {
                self.itemDistanceLabel.text = " \(Int((distance * 1000).rounded())/1000) M away"
            }
            self.itemNameLabel.text = sortedItems[0].name
            self.itemTypeLabel.text = sortedItems[0].type
            self.itemImage.image = sortedItems[0].image as? UIImage
            self.selectedItem = sortedItems[0]
            self.detailsButton.isHidden = false
            self.detailsButton.isEnabled = true
        }
    }
    //self.images = allImages
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //fittng the photo
        mapView.delegate = self
        itemImage.layer.cornerRadius = 35
        detailsButton.layer.cornerRadius = 15
        itemImage.clipsToBounds = true
        locationManager.delegate = self
        
        let popOverVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewController(withIdentifier: "InitalLoadingViewController") as! InitalLoadingViewController
        
        self.addChildViewController(popOverVC)
        popOverVC.view.frame = self.view.frame
        UIView.transition(with: self.view, duration: 0.0, options: .transitionCrossDissolve, animations: { _ in
            self.view.addSubview(popOverVC.view)
        }, completion: nil)
        popOverVC.didMove(toParentViewController: self)
        
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
    
    func updateValue(item: Item){
        
        self.mapView.removeAnnotation(self.editedAnno)
        let items = CoreDataHelper.retrieveItems()
        
        let coordinate = CLLocationCoordinate2DMake(item.latitude, item.longitude)
        let anno = CustomPointAnnotation()
        anno.coordinate = coordinate
        anno.image = (item.image as? UIImage)!
        self.sortedItems = LocationService.rankDistance(items: items)
        self.selectedItem = item
        let myCoordinate = LocationService.getLocation(manager: self.locationManager)
        let myLocation = CLLocation(latitude: myCoordinate.latitude, longitude: myCoordinate.longitude)
        let contactLocation = CLLocation(latitude: item.latitude, longitude: item.longitude)
        
        self.mapView.addAnnotation(anno)
        
        let distance = myLocation.distance(from: contactLocation)
        
        if distance > 1000.0
        {
            self.itemDistanceLabel.text = " \(Int(distance/1000)) KM away"
        } else {
            self.itemDistanceLabel.text = " \(Int((distance * 1000).rounded())/1000) M away"
        }
        self.itemNameLabel.text = sortedItems[0].name
        self.itemTypeLabel.text = sortedItems[0].type
        self.itemImage.image = sortedItems[0].image as? UIImage
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
            let items = CoreDataHelper.retrieveItems()
            var i = 0
            while i < items.count{
                if (items[i].latitude == self.editedAnno.coordinate.latitude) && ( items[i].longitude == self.editedAnno.coordinate.longitude){
                    self.selectedItem = items[i]
                    self.selectedIndex = i
                    break
                }
                i += 1
            }
            
            self.itemNameLabel.text = self.selectedItem.name
            self.itemTypeLabel.text = self.selectedItem.type
            self.itemImage.image = self.selectedItem.image as? UIImage
            
            let location = LocationService.getLocation(manager: locationManager)
            let myLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            let contactLocation = CLLocation(latitude: (coordinate?.latitude)!, longitude: (coordinate?.longitude)!)
            let distance = contactLocation.distance(from: myLocation)
            if distance > 1000.0
            {
                self.itemDistanceLabel.text = " \(Int(distance/1000)) KM away"
            } else {
                self.itemDistanceLabel.text = " \(Int((distance * 1000).rounded())/1000) M away"
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
                var items = CoreDataHelper.retrieveItems()
                items.removeAll()
                CoreDataHelper.saveItem()
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
        popOverVC.item = selectedItem
        popOverVC.name = selectedItem.name!
        popOverVC.organization = selectedItem.organization!
        popOverVC.address = selectedItem.locationDescription!
        popOverVC.type = selectedItem.type!
        popOverVC.contactPhoto = (selectedItem.image as? UIImage)!
        popOverVC.email = selectedItem.email!
        popOverVC.phone = selectedItem.phone!
        popOverVC.latitude = selectedItem.latitude
        popOverVC.longitude = selectedItem.longitude
        popOverVC.keyOfItem = selectedItem.key!
        
        self.addChildViewController(popOverVC)
        popOverVC.view.frame = self.view.frame
        UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
            self.view.addSubview(popOverVC.view)
        }, completion: nil)
        popOverVC.didMove(toParentViewController: self)
    }
    
    
    
}
