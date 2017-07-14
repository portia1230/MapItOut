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

class AddEntryViewController: UIViewController, MKMapViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate{
    
    //MARK: - Properties
    
    @IBOutlet weak var locationMapView: MKMapView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var uploadPhotoButton: UIButton!
    @IBOutlet weak var addContactButton: UIButton!
    @IBOutlet weak var locationTextField: UITextField!
    
    var originalLocation : String!
    var firstName : String!
    var lastName : String!
    var image : UIImage!
    var email : String!
    var phone : String!
    var contactLocationDescription : String!
    var relationship: String!
    
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
    
    var pickOption = ["Business partners", "Classmate", "Close Friend", "Co-worker", "Family", "Friend"]
    
    //MARK: - IBoutlets for text fields
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var relationshipTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let pickerView = UIPickerView()
        pickerView.delegate = self
        relationshipTextField.tintColor = UIColor.clear
        relationshipTextField.inputView = pickerView
        locationMapView.delegate = self
        locationMapView.isUserInteractionEnabled = false
        locationMapView.tintColor = blueColor
        photoImageView.layer.cornerRadius = 75
        uploadPhotoButton.layer.cornerRadius = 75
        photoImageView.clipsToBounds = true
        locationMapView.showsUserLocation = true
        
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        relationshipTextField.delegate = self
        phoneTextField.delegate = self
        emailTextField.delegate = self
        firstNameTextField.tag = 0
        lastNameTextField.tag = 1
        relationshipTextField.tag = 2
        phoneTextField.tag = 3
        emailTextField.tag = 4
        locationTextField.tag = 5
        
        //dismiss keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        let swipeDown = UISwipeGestureRecognizer(target: self, action: "dismissKeyboard")
        let swipeUp = UISwipeGestureRecognizer(target: self, action: "dismissKeyboard")
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        swipeUp.direction = UISwipeGestureRecognizerDirection.up
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(swipeDown)
        view.addGestureRecognizer(swipeUp)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //set region/zoom in for map
        if let firstName = self.firstName {
            self.firstNameTextField.text = firstName
        }
        if let lastName = self.lastName {
            self.lastNameTextField.text = lastName
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
                self.locationMapView.setRegion(region, animated: false)
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
            locationMapView.setRegion(region, animated: false)
        }
    }
    
    
    
    //MARK: - Functions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        // Try to find next responder
        if let nextTextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextTextField.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
        }
        // Do not add a line break
        return false
    }
    
    func reverseGeocoding(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
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
            self.locationTextField.text = trimmed
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
                    
                } else {
                    print(error?.localizedDescription ?? "error" )
                }
            }
            
        }
    }
    
    @IBAction func uploadPhotoButtonTapped(_ sender: UIButton) {
        photoHelper.presentActionSheet(from: self)
        photoHelper.completionHandler = { image in
            self.photoImageView.image = image
        }
    }
    
    func getLocation(manager: CLLocationManager) -> CLLocationCoordinate2D {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
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
        if self.firstNameTextField.text != "",
            self.lastNameTextField.text != "",
            self.relationshipTextField.text != "Relationship Status"{
            if photoImageView.image == nil {
                photoImageView.image = #imageLiteral(resourceName: "Rory.jpg")
            }
            let imageRef = StorageReference.newPostImageReference()
            StorageService.uploadImage(photoImageView.image!, at: imageRef) { (downloadURL) in
                guard let downloadURL = downloadURL else {
                    return
                }
                
                let urlString = downloadURL.absoluteString
                
                let entry = Entry(firstName: self.firstNameTextField.text!, lastName: self.lastNameTextField.text!, longitude: self.longitude, latitude: self.latitude, relationship: self.relationshipTextField.text!, imageURL: urlString , number: self.phoneTextField.text!, email: self.emailTextField.text!, key: "", locationDescription: self.locationTextField.text!)
                EntryService.addEntry(entry: entry)
                self.dismiss(animated: true) {
                }
            }
        } else {
            let alertController = UIAlertController(title: "", message:
                "Did you put in a full name, image, and relationship status?", preferredStyle: UIAlertControllerStyle.alert)
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
        relationshipTextField.text = pickOption[row]
    }
}
