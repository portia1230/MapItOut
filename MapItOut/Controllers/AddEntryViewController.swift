//
//  AddEntryViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/10/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//
import Foundation
import UIKit
import MapKit
import AddressBookUI
import FirebaseStorage
import FirebaseDatabase
import Contacts

class AddEntryViewController: UIViewController, MKMapViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate{
    
    //MARK: - Properties
    
    @IBOutlet weak var locationMapView: MKMapView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var uploadPhotoButton: UIButton!
    @IBOutlet weak var addContactButton: UIButton!
    @IBOutlet weak var locationTextField: UITextField!
    
    var originalLocation : String!
    var name : String!
    var organization : String!
    var image : UIImage!
    var email : String!
    var phone : String!
    var contactLocationDescription : String!
    var type: String!
    var latitude = 0.0
    var longitude = 0.0
    var location : CLLocationCoordinate2D!
    
    let locationManager = CLLocationManager()
    //let blueColor = UIColor(red: 74/255, green: 88/255, blue: 178/255, alpha: 1)
    let greenColor = UIColor(red: 173/255, green: 189/255, blue: 240/255, alpha: 0.2)
    let blueColor = UIColor(red: 76, green: 109, blue: 255, alpha: 1)
    var photoHelper = MGPhotoHelper()
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var pickOption = ["Close Friend", "Co-worker", "Family", "Food", "Friend"]
    
    //MARK: - IBoutlets for text fields
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var organizationTextField: UITextField!
    @IBOutlet weak var typeTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let pickerView = UIPickerView()
        pickerView.delegate = self
        typeTextField.tintColor = UIColor.clear
        typeTextField.inputView = pickerView
        locationMapView.delegate = self
        locationMapView.isUserInteractionEnabled = true
        locationMapView.tintColor = blueColor
        photoImageView.layer.cornerRadius = 70
        uploadPhotoButton.layer.cornerRadius = 70
        photoImageView.clipsToBounds = true
        locationMapView.showsUserLocation = true
        
        nameTextField.delegate = self
        organizationTextField.delegate = self
        typeTextField.delegate = self
        phoneTextField.delegate = self
        emailTextField.delegate = self
        locationTextField.delegate = self
        nameTextField.tag = 0
        organizationTextField.tag = 1
        typeTextField.tag = 2
        phoneTextField.tag = 3
        emailTextField.tag = 4
        locationTextField.tag = 5
        
        //dismiss keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AddEntryViewController.dismissKeyboard))
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(AddEntryViewController.dismissKeyboard))
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(AddEntryViewController.dismissKeyboard))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        swipeUp.direction = UISwipeGestureRecognizerDirection.up
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(swipeDown)
        view.addGestureRecognizer(swipeUp)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if (CLLocationManager.authorizationStatus() == .restricted) || (CLLocationManager.authorizationStatus() == .denied)  {
            let alertController = UIAlertController(title: nil, message:
                "We do not have access to your location, please go to Settings/ Privacy/ Location and give us permission", preferredStyle: UIAlertControllerStyle.alert)
            let cancel = UIAlertAction(title: "I authorized", style: .cancel, handler: { (action) in
                self.viewWillAppear(true)
            })
            
            alertController.addAction(cancel)
            self.present(alertController, animated: true, completion: nil)
            
        } else {
            
            for item in CoreDataHelper.retrieveItems(){
                if pickOption.contains(item.type!) == false{
                    pickOption.append(item.type!)
                }
            }
            
            //set region/zoom in for map
            if let name = self.name {
                self.nameTextField.text = name
            }
            if let organization = self.organization {
                self.organizationTextField.text = organization
            }
            if let email = self.email {
                self.emailTextField.text = email
            }
            if let phone = self.phone {
                self.phoneTextField.text = phone
            }
            if (self.image) != nil{
                self.photoImageView.image = self.image
            }
            self.locationMapView.showsUserLocation = false
            
            if let _ = self.contactLocationDescription {
                self.locationTextField.text = self.contactLocationDescription
                getCoordinate(addressString: self.contactLocationDescription!, completionHandler: { (location, error) in
                    let dispatchGroup = DispatchGroup()
                    let anno = MKPointAnnotation()
                    anno.coordinate = location
                    self.longitude = anno.coordinate.longitude
                    self.latitude = anno.coordinate.latitude
                    let annotations = self.locationMapView.annotations
                    self.locationMapView.removeAnnotations(annotations)
                    self.locationMapView.addAnnotation(anno)
                    self.location = location
                    let coordinate = CLLocationCoordinate2DMake(self.latitude, self.longitude)
                    let span = MKCoordinateSpanMake(0.1, 0.1)
                    let region = MKCoordinateRegionMake(coordinate, span)
                    self.locationMapView.setRegion(region, animated: true)
                    dispatchGroup.notify(queue: .main, execute: {
                    })
                })
            }  else {
                let coordinate = getLocation(manager: locationManager)
                self.location = coordinate
                reverseGeocoding(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let anno = MKPointAnnotation()
                anno.coordinate = coordinate
                self.longitude = anno.coordinate.longitude
                self.latitude = anno.coordinate.latitude
                let annotations = self.locationMapView.annotations
                self.locationMapView.removeAnnotations(annotations)
                self.locationMapView.addAnnotation(anno)
                let span = MKCoordinateSpanMake(0.1, 0.1)
                let region = MKCoordinateRegionMake(coordinate, span)
                locationMapView.setRegion(region, animated: true)
            }
        }
    }
    
    
    //MARK: - Functions
    
    @IBAction func addTypeButtonTapped(_ sender: Any) {
        let popOverVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewController(withIdentifier: "AddTypePopUpViewController" ) as! AddTypePopUpViewController
        self.addChildViewController(popOverVC)
        popOverVC.view.frame = self.view.frame
        UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
            self.view.addSubview(popOverVC.view)
        }, completion: nil)
        popOverVC.didMove(toParentViewController: self)
    }
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        // Try to find next responder
        if let nextTextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextTextField.becomeFirstResponder()
            if nextTextField.tag == 5 {
                self.originalLocation = nextTextField.text!
                nextTextField.text = ""
            }
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
        }
        // Do not add a line break
        return false
    }
    
    func reverseGeocoding(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        var address = ""
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) -> Void in
            if error != nil{
                print(error as Any)
                return
            } else if (placemarks?.count)! > 0 {
                let pm = placemarks![0].addressDictionary
                let addressLine = pm?["FormattedAddressLines"] as? [String]
                address = (addressLine?.joined(separator: ", "))!
            }
            self.locationTextField.text = address
            self.originalLocation = address
        }
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == locationTextField{
            self.originalLocation = locationTextField.text
            self.locationTextField.text = ""
            return true
        }
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.locationTextField{
            if self.locationTextField.text == ""{
                self.locationTextField.text = self.originalLocation
            } else {
                let geocoder = CLGeocoder()
                geocoder.geocodeAddressString(locationTextField.text!) { (placemarks:[CLPlacemark]?, error: Error?) in
                    if error == nil{
                        let placemark = placemarks?.first
                        let anno = MKPointAnnotation()
                        anno.coordinate = (placemark?.location?.coordinate)!
                        
                        let annotations = self.locationMapView.annotations
                        
                        //centering and clearing other annotations
                        let span = MKCoordinateSpanMake(0.1, 0.1)
                        self.location = anno.coordinate
                        let region = MKCoordinateRegion(center: anno.coordinate, span: span)
                        self.locationMapView.setRegion(region, animated: true)
                        self.locationMapView.removeAnnotations(annotations)
                        self.locationMapView.addAnnotation(anno)
                        
                        self.reverseGeocoding(latitude: anno.coordinate.latitude, longitude: anno.coordinate.longitude)
                        self.longitude = anno.coordinate.longitude
                        self.latitude = anno.coordinate.latitude
                        self.originalLocation = self.locationTextField.text!
                        self.contactLocationDescription = self.originalLocation
                        
                        
                        
                    } else {
                        print(error?.localizedDescription ?? "error" )
                    }
                }
            }
        }
        self.name = self.nameTextField.text!
        self.organization = self.organizationTextField.text!
        self.type = self.typeTextField.text!
        self.email = self.emailTextField.text!
        self.phone = self.phoneTextField.text!
        self.latitude = self.location.latitude
        self.longitude = self.location.longitude
        
    }
    
    @IBAction func uploadPhotoButtonTapped(_ sender: UIButton) {
        photoHelper.presentActionSheet(from: self)
        photoHelper.completionHandler = { image in
            self.photoImageView.image = image
            self.uploadPhotoButton.setTitle("", for: .normal)
        }
    }
    
    func getLocation(manager: CLLocationManager) -> CLLocationCoordinate2D {
        guard let locValue:CLLocationCoordinate2D = manager.location!.coordinate else{
            let locValue = CLLocationCoordinate2DMake(0.0, 0.0)
        }
        return locValue
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true) {
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        if !(annotation is MKPointAnnotation){
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "pinIdentifier")
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "pinIdentifier")
            annotationView!.canShowCallout = true
        } else {
            annotationView!.annotation = annotation
        }
        let pinImage = UIImage(named: "200*274pin")
        
        annotationView!.image = UIImage(cgImage: (pinImage?.cgImage)!, scale: 200/30, orientation: .up)
        return annotationView
        
    }
    
    @IBAction func addContactButtonTapped(_ sender: Any) {
        
        if self.nameTextField.text != "",
            self.typeTextField.text != "Select type"{
            
            let currentUser = User.currentUser
            let entryRef = Database.database().reference().child("Contacts").child(currentUser.uid).childByAutoId()
            
            let item = CoreDataHelper.newItem()
            item.name = self.nameTextField.text
            item.organization = self.organizationTextField.text
            item.type = self.typeTextField.text
            item.phone = self.phoneTextField.text
            item.email = self.emailTextField.text
            item.latitude = self.latitude
            item.longitude = self.longitude
            item.locationDescription = self.locationTextField.text
            item.key = entryRef.key
            item.image = self.photoImageView.image!
            CoreDataHelper.saveItem()
            self.dismiss(animated: true, completion: {
            })
            let imageRef = StorageReference.newContactImageReference(key: entryRef.key)
            StorageService.uploadHighImage(item.image as! UIImage, at: imageRef) { (downloadURL) in
                
                guard let downloadURL = downloadURL else {
                    return
                }
                
                let urlString = downloadURL.absoluteString
                let entry = Entry(name: self.nameTextField.text!, organization: self.organizationTextField.text!, longitude: self.longitude, latitude: self.latitude, type: self.typeTextField.text!, imageURL: urlString, phone: self.phoneTextField.text!, email: self.emailTextField.text!, key: entryRef.key, locationDescription: self.locationTextField.text!)
                
                ItemService.addEntry(entry: entry)
                
            }
        } else {
            let alertController = UIAlertController(title: "", message:
                "Did you put in a name and type?", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "No?", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    func getCoordinate( addressString : String,
                        completionHandler: @escaping(CLLocationCoordinate2D, NSError?) -> Void ) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressString) { (placemarks, error) in
            if error == nil {
                if let placemark = placemarks?[0] {
                    let location = placemark.location!
                    completionHandler(location.coordinate, nil)
                    return
                }
            }
            
        }
    }
    
    
    //MARK: - Picker View functions
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickOption.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickOption[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        typeTextField.text = pickOption[row]
        
    }
    
    //MARK: - Image rotating functions
    
    func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.width, height: oldImage.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.width / 2, y: -oldImage.size.height / 2, width: oldImage.size.width, height: oldImage.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}
