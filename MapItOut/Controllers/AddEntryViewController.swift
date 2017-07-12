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

class AddEntryViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate, UITextFieldDelegate{
    
    //MARK: - Properties
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var locationMapView: MKMapView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var uploadPhotoButton: UIButton!
    @IBOutlet weak var addContactButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    var location : CLLocationCoordinate2D!
    
    let locationManager = CLLocationManager()
    //let blueColor = UIColor(red: 74/255, green: 88/255, blue: 178/255, alpha: 1)
    let greenColor = UIColor(red: 173/255, green: 189/255, blue: 240/255, alpha: 0.2)
    let blueColor = UIColor(red: 76, green: 109, blue: 255, alpha: 1)
    var photoHelper = MGPhotoHelper()
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    
    //MARK: - IBoutlets for text fields
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var relationshipTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        locationMapView.delegate = self
        locationMapView.isUserInteractionEnabled = false
        locationMapView.tintColor = blueColor
        photoImageView.layer.cornerRadius = 60
        uploadPhotoButton.layer.cornerRadius = 60
        photoImageView.clipsToBounds = true
        addContactButton.layer.cornerRadius = 15
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
        
        //dismiss keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        var swipeDown = UISwipeGestureRecognizer(target: self, action: "dismissKeyboard")
        var swipeUp = UISwipeGestureRecognizer(target: self, action: "dismissKeyboard")
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        swipeUp.direction = UISwipeGestureRecognizerDirection.up
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(swipeDown)
        view.addGestureRecognizer(swipeUp)
        
        //testing only to preset location to current
        self.location = getLocation(manager: locationManager)
        //testing only to preset location to current
        
        let coordinate = getLocation(manager: locationManager)
        self.locationLabel.text = LocationService.reverseGeocoding(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //set region/zoom in for map
        let location = self.location
        let coordinate = CLLocationCoordinate2DMake((location!.latitude), (location!.longitude))
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(coordinate, span)
        locationMapView.setRegion(region, animated: false)
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
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchBar.text!) { (placemarks:[CLPlacemark]?, error: Error?) in
            if error == nil{
                let placemark = placemarks?.first
                let anno = MKPointAnnotation()
                anno.coordinate = (placemark?.location?.coordinate)!
                anno.title = self.searchBar.text!
                
                let annotations = self.locationMapView.annotations
                
                //centering and clearing other annotations
                let span = MKCoordinateSpanMake(0.075, 0.075)
                let region = MKCoordinateRegion(center: anno.coordinate, span: span)
                self.locationMapView.setRegion(region, animated: true)
                self.locationMapView.removeAnnotations(annotations)
                self.locationMapView.addAnnotation(anno)
                self.locationLabel.text = LocationService.reverseGeocoding(latitude: anno.coordinate.latitude, longitude: anno.coordinate.longitude)
                
            } else {
                print(error?.localizedDescription ?? "error" )
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
            self.lastNameTextField.text != "" {
            if photoImageView.image == nil {
                photoImageView.image = #imageLiteral(resourceName: "Rory.jpg")
            }
            let imageRef = StorageReference.newPostImageReference()
            StorageService.uploadImage(photoImageView.image!, at: imageRef) { (downloadURL) in
                guard let downloadURL = downloadURL else {
                    return
                }
                
                let urlString = downloadURL.absoluteString
                
                let entry = Entry(firstName: self.firstNameTextField.text!, lastName: self.lastNameTextField.text!, longitude: self.locationMapView.annotations[0].coordinate.longitude, latitude: self.locationMapView.annotations[0].coordinate.latitude, relationship: self.relationshipTextField.text!, imageURL: urlString , number: self.phoneTextField.text!, email: self.emailTextField.text!, key: "")
                EntryService.addEntry(entry: entry)
                self.dismiss(animated: true) {
                }
            }
        } else {
            
            let alertController = UIAlertController(title: "", message:
                "Did you put in a first name and last name?", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "No?", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
            
            
        }
        
    }
    
}
