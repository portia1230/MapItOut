//
//  popUpViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/16/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import AddressBookUI
import FirebaseStorage
import FirebaseDatabase

class PopUpViewController : UIViewController, MKMapViewDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource{
    
    //MARK: - Properties
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var changeImageButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var relationshipTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var addressDescription: UITextField!
    @IBOutlet weak var contactMapView: MKMapView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var contactImage: UIImageView!
    
    var OFirstName = ""
    var OLastName = ""
    var ORelationship = ""
    var OPhoneNumber = "No number entered"
    var OEmail = "No email entered"
    var OAddress = ""
    var OLongitude = 0.0
    var OLatitude = 0.0
    var OContactPhoto = UIImageView()
    var OOriginalLocation = ""
    var OLocation = CLLocationCoordinate2D()
    
    var firstName = ""
    var lastName = ""
    var relationship = ""
    var phoneNumber = "No number entered"
    var email = "No email entered"
    var address = ""
    var longitude = 0.0
    var latitude = 0.0
    var contactPhoto = UIImageView()
    var originalLocation = ""
    var locationManager = CLLocationManager()
    var location = CLLocationCoordinate2D()
    var photoHelper = MGPhotoHelper()
    var keyOfContact = ""
    
    
    var greenColor = UIColor(red: 90/255, green: 196/255, blue: 128/255, alpha: 1)
    var greyColor = UIColor
    var pickOption = ["Business partners", "Classmate", "Close Friend", "Co-worker", "Family", "Friend"]
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        
        contactMapView.delegate = self
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        relationshipTextField.delegate = self
        phoneNumberTextField.delegate = self
        emailTextField.delegate = self
        addressDescription.delegate = self
        
        relationshipTextField.inputView = pickerView
        
        firstNameTextField.tag = 0
        lastNameTextField.tag = 1
        relationshipTextField.tag = 2
        phoneNumberTextField.tag = 3
        emailTextField.tag = 4
        addressDescription.tag = 5
        
        firstNameTextField.isUserInteractionEnabled = true
        lastNameTextField.isUserInteractionEnabled = true
        relationshipTextField.isUserInteractionEnabled = true
        phoneNumberTextField.isUserInteractionEnabled = true
        emailTextField.isUserInteractionEnabled = true
        addressDescription.isUserInteractionEnabled = true
        changeImageButton.isEnabled = true
        
        
        //dismiss keyboard gesture recognizer
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PopUpViewController.dismissKeyboard))
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(PopUpViewController.dismissView))
        //let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(PopUpViewController.dismissView))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        //swipeUp.direction = UISwipeGestureRecognizerDirection.up
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(swipeDown)
        //view.addGestureRecognizer(swipeUp)
        
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        deleteButton.layer.cornerRadius = 15
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.backgroundView.backgroundColor
        self.changeImageButton.isHidden = true
        self.undoButton.layer.cornerRadius = 30
        self.contactImage.layer.cornerRadius = 75
        self.changeImageButton.layer.cornerRadius = 75
        self.contactImage.clipsToBounds = true
        contactMapView.isUserInteractionEnabled = false
        self.firstNameTextField.text = firstName
        self.lastNameTextField.text = lastName
        self.relationshipTextField.text = relationship
        self.phoneNumberTextField.text = phoneNumber
        self.emailTextField.text = email
        self.addressDescription.text = address
        let location = CLLocationCoordinate2DMake(latitude, longitude)
        self.location = location
        let annos = contactMapView.annotations
        let anno = MKPointAnnotation()
        self.contactImage.image = self.contactPhoto.image
        anno.coordinate = location
        
        contactMapView.removeAnnotations(annos)
        contactMapView.addAnnotation(anno)
        
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(location, span)
        self.contactMapView.setRegion(region, animated: true)
        
        self.originalLocation = self.addressDescription.text!
        
        self.OFirstName = self.firstName
        self.OLastName = self.lastName
        self.ORelationship = self.relationship
        self.OEmail = self.email
        self.OPhoneNumber = self.phoneNumber
        self.OAddress = self.originalLocation
        self.OLatitude = self.latitude
        self.OLongitude = self.longitude
        self.OLocation = self.location
        self.OContactPhoto = self.contactPhoto
        
    }
    
    
    
    
    //MARK: - VC Functions
    
    @IBAction func undoButtonTapped(_ sender: Any) {
        self.firstNameTextField.text = self.OFirstName
        self.lastNameTextField.text = self.OLastName
        self.relationshipTextField.text = self.ORelationship
        self.emailTextField.text = self.OEmail
        self.phoneNumberTextField.text = self.OPhoneNumber
        self.addressDescription.text = self.OOriginalLocation
        let annotations = self.contactMapView.annotations
        self.contactMapView.removeAnnotations(annotations)
        let anno = MKPointAnnotation()
        anno.coordinate = CLLocationCoordinate2D(latitude: self.OLatitude, longitude: self.OLongitude)
        self.contactMapView.addAnnotation(anno)
        undoButton.color
    }
    
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        
        EntryService.deleteEntry(key: self.keyOfContact)
        
        UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
            self.view.removeFromSuperview()
        }, completion: nil)
        self.parent?.viewDidLoad()
        self.parent?.viewWillAppear(true)
    }
    
    @IBAction func changeImageButton(_ sender: Any) {
        photoHelper.presentActionSheet(from: self)
        photoHelper.completionHandler = { image in
            self.contactImage.image = image
        }
    }
    
    //    @IBAction func editButtonTapped(_ sender: Any) {
    //        if self.isEditingContact == false {
    //            self.isEditingContact = true
    //            self.changeImageButton.isHidden = false
    //            firstNameTextField.isUserInteractionEnabled = true
    //            lastNameTextField.isUserInteractionEnabled = true
    //            relationshipTextField.isUserInteractionEnabled = true
    //            phoneNumberTextField.isUserInteractionEnabled = true
    //            emailTextField.isUserInteractionEnabled = true
    //            addressDescription.isUserInteractionEnabled = true
    //            changeImageButton.isEnabled = true
    //            editButton.setTitle("Cancel", for: .normal)
    //            doneButton.setTitle("Save", for: .normal)
    //        } else {
    //            self.isEditingContact = false
    //            changeImageButton.isEnabled = false
    //            self.changeImageButton.isHidden = true
    //            firstNameTextField.isUserInteractionEnabled = false
    //            lastNameTextField.isUserInteractionEnabled = false
    //            relationshipTextField.isUserInteractionEnabled = false
    //            phoneNumberTextField.isUserInteractionEnabled = false
    //            emailTextField.isUserInteractionEnabled = false
    //            addressDescription.isUserInteractionEnabled = false
    //            editButton.setTitle("Edit", for: .normal)
    //            doneButton.setTitle("Done", for: .normal)
    //        }
    //
    //    }
    
    func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    func dismissView(){
        if UIApplication.shared.isKeyboardPresented{
            self.view.endEditing(true)
        } else {
            
            let imageRef = StorageReference.newContactImageReference()
            StorageService.uploadImage(contactImage.image!, at: imageRef) { (downloadURL) in
                guard let downloadURL = downloadURL else {
                    return
                }
                let urlString = downloadURL.absoluteString
                let contact = Entry(firstName: self.firstNameTextField.text!, lastName: self.lastNameTextField.text!, longitude: self.location.longitude, latitude: self.location.latitude, relationship: self.relationshipTextField.text!, imageURL: String(describing: urlString), number: self.phoneNumberTextField.text!, email: self.emailTextField.text!, key: self.keyOfContact, locationDescription: self.addressDescription.text!)
                EntryService.editEntry(entry: contact)
            }
            
            UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                self.view.removeFromSuperview()
            }, completion: nil)
            self.parent?.viewDidLoad()
            self.parent?.viewWillAppear(true)
        }
    }
    
//    @IBAction func doneButtonTapped(_ sender: Any) {
//        if isEditingContact == true{
//            changeImageButton.isEnabled = false
//            self.changeImageButton.isHidden = true
//            firstNameTextField.isUserInteractionEnabled = false
//            lastNameTextField.isUserInteractionEnabled = false
//            relationshipTextField.isUserInteractionEnabled = false
//            phoneNumberTextField.isUserInteractionEnabled = false
//            emailTextField.isUserInteractionEnabled = false
//            addressDescription.isUserInteractionEnabled = false
//            isEditingContact = false
//            editButton.setTitle("Edit", for: .normal)
//            doneButton.setTitle("Done", for: .normal)
//            let imageRef = StorageReference.newContactImageReference()
//            StorageService.uploadImage(contactImage.image!, at: imageRef) { (downloadURL) in
//                guard let downloadURL = downloadURL else {
//                    return
//                }
//                let urlString = downloadURL.absoluteString
//                let contact = Entry(firstName: self.firstNameTextField.text!, lastName: self.lastNameTextField.text!, longitude: self.location.longitude, latitude: self.location.latitude, relationship: self.relationshipTextField.text!, imageURL: String(describing: urlString), number: self.phoneNumberTextField.text!, email: self.emailTextField.text!, key: self.keyOfContact, locationDescription: self.addressDescription.text!)
//                EntryService.editEntry(entry: contact)
//            }
//        } else {
//            UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
//                self.view.removeFromSuperview()
//            }, completion: nil)
//            self.parent?.viewDidLoad()
//            self.parent?.viewWillAppear(true)
//        }
//    }
    
    //MARK: - Text field delegate functions
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == addressDescription{
            self.originalLocation = addressDescription.text!
            self.addressDescription.text = ""
            return true
        }
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if self.addressDescription.text == ""{
            self.addressDescription.text = self.originalLocation
        } else {
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(addressDescription.text!) { (placemarks:[CLPlacemark]?, error: Error?) in
                if error == nil{
                    let placemark = placemarks?.first
                    let anno = MKPointAnnotation()
                    anno.coordinate = (placemark?.location?.coordinate)!
                    
                    let annotations = self.contactMapView.annotations
                    
                    //centering and clearing other annotations
                    let span = MKCoordinateSpanMake(0.1, 0.1)
                    self.location = anno.coordinate
                    let region = MKCoordinateRegion(center: anno.coordinate, span: span)
                    self.contactMapView.setRegion(region, animated: true)
                    self.contactMapView.removeAnnotations(annotations)
                    self.contactMapView.addAnnotation(anno)
                    
                    self.reverseGeocoding(latitude: anno.coordinate.latitude, longitude: anno.coordinate.longitude)
                    self.longitude = anno.coordinate.longitude
                    self.latitude = anno.coordinate.latitude
                    
                } else {
                    print(error?.localizedDescription ?? "error" )
                }
            }
            
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
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
        return false
    }
    
    //MARK: - Map View delegate
    
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
    
    //MARK: - Reverse Geocoding
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
            self.addressDescription.text = address
        }
    }
    
    
}

extension UIApplication {
    var isKeyboardPresented: Bool {
        if let keyboardWindowClass = NSClassFromString("UIRemoteKeyboardWindow"), self.windows.contains(where: { $0.isKind(of: keyboardWindowClass) }) {
            return true
        } else {
            return false
        }
    }
}
