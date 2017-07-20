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
import MessageUI

class PopUpViewController : UIViewController, MKMapViewDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate{
    
    //MARK: - Properties
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var changeImageButton: UIButton!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var relationshipTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var addressDescription: UITextField!
    @IBOutlet weak var contactMapView: MKMapView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var contactImage: UIImageView!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var emailButton: UIButton!
    
    @IBOutlet weak var phoneImageView: UIImageView!
    @IBOutlet weak var emailImageView: UIImageView!
    
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
    var greyColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
    var darkTextColor = UIColor(red: 90/255, green: 92/255, blue: 92/255, alpha: 1)
    var pickOption = ["Acquaintance","Business partners", "Classmate", "Close Friend", "Co-worker", "Family", "Friend"]
    
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
        
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        deleteButton.layer.cornerRadius = 15
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        self.backgroundView.layer.backgroundColor = greyColor.cgColor
        self.undoButton.setTitleColor(darkTextColor, for: .normal)
        self.backgroundView.layer.cornerRadius = 30
        self.undoButton.isEnabled = false
        self.undoButton.layer.cornerRadius = 30
        self.contactImage.layer.cornerRadius = 70
        self.changeImageButton.layer.cornerRadius = 70
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
        
        if self.phoneNumberTextField.text! == ""{
            self.phoneButton.isHidden = true
            self.phoneImageView.isHidden = true
        }
        
        if self.emailTextField.text! == ""{
            self.emailButton.isHidden = true
            self.emailImageView.isHidden = true
        }
        
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
        self.OOriginalLocation = self.originalLocation
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
        self.addressDescription.text = self.OOriginalLocation
        let anno = MKPointAnnotation()
        anno.coordinate = CLLocationCoordinate2D(latitude: self.OLatitude, longitude: self.OLongitude)
        self.contactMapView.addAnnotation(anno)
        self.backgroundView.layer.backgroundColor = greyColor.cgColor
        self.undoButton.setTitleColor(darkTextColor, for: .normal)
        self.undoButton.isEnabled = false
    }
    
    @IBAction func mapButtonTapped(_ sender: Any) {
        
        let regionDistance:CLLocationDistance = 100000
        let coordinates = CLLocationCoordinate2DMake(self.location.latitude, self.location.longitude)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = self.firstNameTextField.text! + " " + self.lastNameTextField.text!
        mapItem.openInMaps(launchOptions: options)
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func phoneButtonTapped(_ sender: Any) {
        let composeVC = MFMessageComposeViewController()
        let name = self.firstNameTextField.text!
        composeVC.messageComposeDelegate = self
        composeVC.recipients = [self.phoneNumberTextField.text!]
        composeVC.body = "Hey \(name), "
        self.present(composeVC, animated: true,completion: nil)
    }
    
    
    @IBAction func emailButtonTapped(_ sender: Any) {
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        // Configure the fields of the interface.
        composeVC.setToRecipients([self.emailTextField.text!])
        //composeVC.setSubject("")
        composeVC.setMessageBody("Hey \(self.firstNameTextField.text!)", isHTML: false)
        
        // Present the view controller modally.
        self.present(composeVC, animated: true, completion: nil)
        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        // Check the result or perform other tasks.
        
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
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
            self.contactPhoto.image = image
        }
    }
    
    func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    func dismissView(){
        if UIApplication.shared.isKeyboardPresented{
            self.view.endEditing(true)
        } else {
            if self.parent is MainViewController{
                let parent = self.parent as! MainViewController
                
                 let firstContact = Entry(firstName: self.firstNameTextField.text!, lastName: self.lastNameTextField.text!, longitude: self.location.longitude, latitude: self.location.latitude, relationship: self.relationshipTextField.text!, imageURL: "", lowImageURL: "", number: self.phoneNumberTextField.text!, email: self.emailTextField.text!, key: self.keyOfContact, locationDescription: self.addressDescription.text!)
                
                parent.updateValue(entry: firstContact, image: self.contactImage.image!)

                UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                    self.view.removeFromSuperview()
                }, completion: nil)
                
                let imageRef = Storage.storage().reference().child("images/contacts/\(User.currentUser.uid)/\(parent.selectedContact.key).jpg")
                let lowImageRef = Storage.storage().reference().child("images/contacts/\(User.currentUser.uid)/\(parent.selectedContact.key)low.jpg")
                
                imageRef.delete(completion: nil)
                lowImageRef.delete(completion: nil)
                
                
                let newImageRef = StorageReference.newContactImageReference(key: parent.selectedContact.key)
                let newLowImageRef = StorageReference.newLowContactImageReference(key: parent.selectedContact.key)
                
                StorageService.uploadHighImage(contactImage.image!, at: newImageRef) { (downloadURL) in
                    guard let downloadURL = downloadURL else {
                        return
                    }
                    StorageService.uploadLowImage(self.contactImage.image!, at: newLowImageRef) { (lowDownloadURL) in
                        guard let lowDownloadURL = lowDownloadURL else {
                            return
                        }
                    let lowURLString = lowDownloadURL.absoluteString
                    let urlString = downloadURL.absoluteString
                    firstContact.lowImageURL = lowURLString
                    firstContact.imageURL = urlString
                    EntryService.editEntry(entry: firstContact)
                    }
                }
            } else {
                let parent = self.parent as! ContactListController
                let firstContact = Entry(firstName: self.firstNameTextField.text!, lastName: self.lastNameTextField.text!, longitude: self.location.longitude, latitude: self.location.latitude, relationship: self.relationshipTextField.text!, imageURL: "", lowImageURL: "", number: self.phoneNumberTextField.text!, email: self.emailTextField.text!, key: self.keyOfContact, locationDescription: self.addressDescription.text!)
                
                parent.updateValue(entry: firstContact, image: self.contactImage.image!)
                
                UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                    self.view.removeFromSuperview()
                }, completion: nil)
                
                let imageRef = Storage.storage().reference().child("images/contacts/\(User.currentUser.uid)/\(parent.sortedContacts[parent.selectedIndex].key).jpg")
                let lowImageRef = Storage.storage().reference().child("images/contacts/\(User.currentUser.uid)/\(parent.sortedContacts[parent.selectedIndex].key)low.jpg")
                
                imageRef.delete(completion: nil)
                lowImageRef.delete(completion: nil)
                
                
                let newImageRef = StorageReference.newContactImageReference(key: parent.sortedContacts[parent.selectedIndex].key)
                let newLowImageRef = StorageReference.newLowContactImageReference(key: parent.sortedContacts[parent.selectedIndex].key)
                
                StorageService.uploadHighImage(contactImage.image!, at: newImageRef) { (downloadURL) in
                    guard let downloadURL = downloadURL else {
                        return
                    }
                    StorageService.uploadLowImage(self.contactImage.image!, at: newLowImageRef) { (lowDownloadURL) in
                        guard let lowDownloadURL = lowDownloadURL else {
                            return
                        }
                        let lowURLString = lowDownloadURL.absoluteString
                        let urlString = downloadURL.absoluteString
                        firstContact.lowImageURL = lowURLString
                        firstContact.imageURL = urlString
                        EntryService.editEntry(entry: firstContact)
                    }
                }
            }
        }
    }
    
    //MARK: - Text field delegate functions
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.undoButton.isEnabled = true
        self.backgroundView.layer.backgroundColor = greenColor.cgColor
        self.undoButton.setTitleColor(UIColor.white, for: .normal)
        if textField == addressDescription{
            self.originalLocation = addressDescription.text!
            self.addressDescription.text = ""
            return true
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.undoButton.isEnabled = true
        self.backgroundView.layer.backgroundColor = greenColor.cgColor
        self.undoButton.setTitleColor(UIColor.white, for: .normal)
        
        if self.phoneNumberTextField.text! != ""{
            self.phoneButton.isHidden = false
            self.phoneImageView.isHidden = false
        } else {
            self.phoneButton.isHidden = true
            self.phoneImageView.isHidden = true
        }
        
        if self.emailTextField.text! != ""{
            self.emailButton.isHidden = false
            self.emailImageView.isHidden = false
        } else {
            self.emailButton.isHidden = true
            self.emailImageView.isHidden = true
        }
        
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
