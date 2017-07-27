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

class MainViewController : UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIPickerViewDelegate{
    
    //MARK: - Properties
    
    @IBOutlet weak var numberCountLabel: UILabel!
    @IBOutlet weak var pickerUIView: UIView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var locationImage: UIImageView!
    @IBOutlet weak var itemDistanceLabel: UILabel!
    @IBOutlet weak var itemTypeLabel: UILabel!
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var detailsButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    
    var items = [Item]()
    
    var redColor = UIColor(red: 220/255, green: 94/255, blue: 86/255, alpha: 1)
    var greyColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
    var greenColor = UIColor(red: 64/255, green: 196/255, blue: 128/255, alpha: 1)
    var selectedItem : Item!
    var filteredItems : [Item] = []
    var sortedItems : [Item] = []
    var isUpdatingHeading = false
    var editedAnno = MKPointAnnotation()
    var selectedIndex = 0
    var isUpdated = false
    
    var contactStore = CNContactStore()
    var locationManager = CLLocationManager()
    var authHandle: AuthStateDidChangeListenerHandle?
    var pickerOptions = ["All items"]
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Lifecycles
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.startTimer), userInfo: nil, repeats: true)
        
        if (CLLocationManager.authorizationStatus() == .restricted) || (CLLocationManager.authorizationStatus() == .denied)  {
            let alertController = UIAlertController(title: nil, message:
                "We do not have access to your location, please go to Settings/ Privacy/ Location and give us permission", preferredStyle: UIAlertControllerStyle.alert)
            let cancel = UIAlertAction(title: "I authorized", style: .cancel, handler: { (action) in
                self.viewWillAppear(true)
            })
            alertController.addAction(cancel)
            self.present(alertController, animated: true, completion: nil)
        }
        if defaults.string(forKey: "type") == nil{
            defaults.set("All items", forKey: "type")
        }
        self.typeLabel.text = defaults.string(forKey: "type")
        self.pickerUIView.isHidden = true
        self.pickerView.delegate = self
        self.mapView.userLocation.subtitle = ""
        self.mapView.userLocation.title = ""
        
        self.detailsButton.isEnabled = false
        let annotations = self.mapView.annotations
        self.mapView.removeAnnotations(annotations)
        
        self.items = CoreDataHelper.retrieveItems()
        
        self.sortedItems = LocationService.rankDistance(items: items)
        filterResults(type: self.typeLabel.text!)
        
        let location = CLLocation(latitude: LocationService.getLocation(manager: locationManager).latitude, longitude: LocationService.getLocation(manager: locationManager).longitude)
        let span = LocationService.getSpan(myLocation: location, items: self.filteredItems)
        let region = MKCoordinateRegionMake(LocationService.getLocation(manager: locationManager), span)
        
        self.mapView.setRegion(region, animated: true)
        
        
        
    }
    //self.images = allImages
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemImage.layer.cornerRadius = 35
        detailsButton.layer.cornerRadius = 15
        itemImage.clipsToBounds = true

        //fittng the photofann
        if (CLLocationManager.authorizationStatus() == .restricted) || (CLLocationManager.authorizationStatus() == .denied)  {
            let alertController = UIAlertController(title: nil, message:
                "We do not have access to your location, please go to Settings/ Privacy/ Location and give us permission", preferredStyle: UIAlertControllerStyle.alert)
            let cancel = UIAlertAction(title: "I authorized", style: .cancel, handler: { (action) in
                self.viewDidLoad()
            })
            alertController.addAction(cancel)
            self.present(alertController, animated: true, completion: nil)
        } else {
        
        mapView.delegate = self
        itemImage.layer.cornerRadius = 35
        detailsButton.layer.cornerRadius = 15
        itemImage.clipsToBounds = true
        locationManager.delegate = self
        let loadedItems = defaults.string(forKey: "loadedItems")
        defaults.set("All items", forKey: "type")
        
        if loadedItems == "false" {
            UserService.items(for: User.currentUser, completion: { (entries) in
                
                if CoreDataHelper.retrieveItems().count == entries.count{
                    
                    defaults.set("true", forKey:"loadedItems")
                    let popOverVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewController(withIdentifier: "InitalLoadingViewController") as! InitalLoadingViewController
                    popOverVC.progressText = "\(CoreDataHelper.retrieveItems().count)/\(entries.count)"
                    self.addChildViewController(popOverVC)
                    popOverVC.view.frame = self.view.frame
                    UIView.transition(with: self.view, duration: 0.0, options: .transitionCrossDissolve, animations: { _ in
                        self.view.addSubview(popOverVC.view)
                    }, completion: nil)
                    popOverVC.didMove(toParentViewController: self)
                    
                } else {
                    
                    let popOverVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewController(withIdentifier: "InitalLoadingViewController") as! InitalLoadingViewController
                    popOverVC.progressText = "\(CoreDataHelper.retrieveItems().count)/\(entries.count)"
                    
                    self.addChildViewController(popOverVC)
                    popOverVC.view.frame = self.view.frame
                    self.view.addSubview(popOverVC.view)
                    popOverVC.didMove(toParentViewController: self)
                    self.viewDidLoad()
                    
                }
            })
        }
            
        authHandle = Auth.auth().addStateDidChangeListener() { [unowned self] (auth, user) in
            guard user == nil else { return }
            
            let loginViewController = UIStoryboard.initialViewController(for: .login)
            self.view.window?.rootViewController = loginViewController
            self.view.window?.makeKeyAndVisible()
            defaults.set("false", forKey:"loadedItems")
        }
        }
    }
    
    deinit {
        if let authHandle = authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }
    
    //MARK: - Update annotations
    
    func updateValue(item: Item){
        self.sortedItems = LocationService.rankDistance(items: CoreDataHelper.retrieveItems())
        filterResults(type: self.typeLabel.text!)
    }
    
    
    //MARK: - Location Manager Functions
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        mapView.camera.heading = newHeading.magneticHeading
        mapView.setCamera(mapView.camera, animated: true)
    }
    
    
    //MARK: - Picker view delegate functions 
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerOptions.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.pickerOptions[row]
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        typeLabel.text = pickerOptions[row]
        defaults.set(typeLabel.text, forKey: "type")
        self.filteredItems.removeAll()
        
        if pickerOptions[row] == "All items"{
            self.filteredItems = self.sortedItems
        } else {
            for item in self.sortedItems{
                if item.type == self.typeLabel.text!{
                    self.filteredItems.append(item)
                }
            }
        }
        self.numberCountLabel.text = "(" + String(self.filteredItems.count) + ")"
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        var i = 0
        while i < self.filteredItems.count {
            let longitude = filteredItems[i].longitude
            let latitude = filteredItems[i].latitude
            let anno = CustomPointAnnotation()
            
            anno.image = filteredItems[i].image as! UIImage
            anno.indexOfContact = i
            anno.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
            self.mapView.addAnnotation(anno)
            i += 1
        }
        
        if self.filteredItems.isEmpty{
            self.itemNameLabel.text = ""
            self.itemDistanceLabel.text = ""
            self.itemTypeLabel.text = ""
            self.itemImage.image = #imageLiteral(resourceName: "defaultNoItemImage.png")
            self.itemNameLabel.backgroundColor = greyColor
            self.itemDistanceLabel.backgroundColor = greyColor
            self.itemTypeLabel.backgroundColor = greyColor
            self.detailsButton.isEnabled = false
            self.detailsButton.setTitle("", for: .normal)
            self.detailsButton.backgroundColor = greyColor
        } else {
            let coordinate = LocationService.getLocation(manager: self.locationManager)
            let myLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let contactLocation = CLLocation(latitude: filteredItems[0].latitude, longitude: filteredItems[0].longitude)
            self.selectedItem = filteredItems[0]
            self.items = CoreDataHelper.retrieveItems()
            var n = 0
            while n < self.items.count {
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
            self.itemNameLabel.text = filteredItems[0].name
            self.itemTypeLabel.text = filteredItems[0].type
            self.itemImage.image = filteredItems[0].image as? UIImage
            self.selectedItem = filteredItems[0]
            self.detailsButton.setTitle("Details", for: .normal)
            //self.detailsButton.isHidden = false
            self.detailsButton.isEnabled = true
            self.detailsButton.backgroundColor = greenColor
        }
        self.pickerUIView.isHidden = true
        
        let location = CLLocation(latitude: LocationService.getLocation(manager: locationManager).latitude, longitude: LocationService.getLocation(manager: locationManager).longitude)
        let span = LocationService.getSpan(myLocation: location, items: self.filteredItems)
        let region = MKCoordinateRegionMake(LocationService.getLocation(manager: locationManager), span)
        
        self.mapView.setRegion(region, animated: true)
        
    }
    
    
    //MARK: - Functions
    
    
    @IBAction func listButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "showListSegue", sender: self)
    }
    
    
    func filterResults( type: String){
        self.filteredItems.removeAll()
        self.sortedItems = LocationService.rankDistance(items: CoreDataHelper.retrieveItems())
        if type == "All items"{
            self.filteredItems = self.sortedItems
        } else {
            for item in self.sortedItems{
                if item.type == self.typeLabel.text!{
                    self.filteredItems.append(item)
                }
            }
        }
        self.numberCountLabel.text = "(" + String(self.filteredItems.count) + ")"
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        var i = 0
        while i < self.filteredItems.count {
            let longitude = filteredItems[i].longitude
            let latitude = filteredItems[i].latitude
            let anno = CustomPointAnnotation()
            
            if self.filteredItems[i].image == nil{
                self.filteredItems[i].image = #imageLiteral(resourceName: "noContactImage.png")
                CoreDataHelper.saveItem()
            }
            anno.image = filteredItems[i].image as! UIImage
            anno.indexOfContact = i
            anno.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
            self.mapView.addAnnotation(anno)
            i += 1
        }
        
        if self.filteredItems.isEmpty{
            self.itemNameLabel.text = ""
            self.itemDistanceLabel.text = ""
            self.itemTypeLabel.text = ""
            self.itemImage.image = #imageLiteral(resourceName: "defaultNoItemImage.png")
            self.itemNameLabel.backgroundColor = greyColor
            self.itemDistanceLabel.backgroundColor = greyColor
            self.itemTypeLabel.backgroundColor = greyColor
            self.detailsButton.isEnabled = false
            self.detailsButton.setTitle("", for: .normal)
            self.detailsButton.backgroundColor = greyColor
        } else {
            let coordinate = LocationService.getLocation(manager: self.locationManager)
            let myLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let contactLocation = CLLocation(latitude: filteredItems[0].latitude, longitude: filteredItems[0].longitude)
            self.selectedItem = filteredItems[0]
            self.items = CoreDataHelper.retrieveItems()
            var n = 0
            while n < self.items.count {
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
            self.itemNameLabel.text = filteredItems[0].name
            self.itemTypeLabel.text = filteredItems[0].type
            self.itemImage.image = filteredItems[0].image as? UIImage
            self.selectedItem = filteredItems[0]
            self.detailsButton.setTitle("Details", for: .normal)
            //self.detailsButton.isHidden = false
            self.detailsButton.isEnabled = true
            self.detailsButton.backgroundColor = greenColor
        }
        
        self.pickerUIView.isHidden = true

    }
    
    @IBAction func filterButtonTapped(_ sender: Any) {
        if pickerUIView.isHidden == true {
            pickerOptions.removeAll()
            pickerOptions.append("All items")
            self.items = CoreDataHelper.retrieveItems()
            for item in items {
                if pickerOptions.contains(item.type!) == false{
                    self.pickerOptions.append(item.type!)
                    self.pickerOptions.sort()
                }
                self.pickerView.reloadAllComponents()
            }
            self.pickerUIView.isHidden = false
        } else {
            pickerUIView.isHidden = true
        }
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: "How would you like to create a new item", preferredStyle: .alert)
        
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
        
        alert.addAction(UIAlertAction(title: "Create new item", style: .default, handler:  { action in self.performSegue(withIdentifier: "addContactSegue", sender: self) }))
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
            self.items = CoreDataHelper.retrieveItems()
            var i = 0
            while i < self.items.count{
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
                defaults.set("false", forKey:"loadedItems")
                self.items = CoreDataHelper.retrieveItems()
                for item in self.items {
                    CoreDataHelper.deleteItems(item: item)
                }
                //CoreDataHelper.saveItem()
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
            isUpdatingHeading = false
            self.mapView.camera.heading = 0.0
            
            let location = CLLocation(latitude: LocationService.getLocation(manager: locationManager).latitude, longitude: LocationService.getLocation(manager: locationManager).longitude)
            let span = LocationService.getSpan(myLocation: location, items: self.filteredItems)
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
    
    //MARK: - Timer
    func startTimer(){
        if InternetConnectionHelper.connectedToNetwork() == false{
            let alertController = UIAlertController(title: "No internet connection", message: nil, preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Retry", style: .default, handler: { (alert) in
                if InternetConnectionHelper.connectedToNetwork() == true{
                    self.dismiss(animated: true, completion: nil)
                }
            })
            alertController.addAction(cancel)
            present(alertController, animated: true, completion: nil)
        }
    }
    
}
