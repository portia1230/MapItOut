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

class AddEntryViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate{
    
    //MARK: - Properties
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var locationMapView: MKMapView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var uploadPhotoButton: UIButton!
    @IBOutlet weak var addContactButton: UIButton!
    @IBOutlet weak var contactInfoButton: UIButton!
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
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationMapView.delegate = self
        locationMapView.isUserInteractionEnabled = false
        contactInfoButton.layer.cornerRadius = 15
        locationMapView.tintColor = blueColor
        photoImageView.layer.cornerRadius = 77.5
        uploadPhotoButton.layer.cornerRadius = 77.5
        photoImageView.clipsToBounds = true
        addContactButton.layer.cornerRadius = 15
        searchBar.layer.backgroundColor = blueColor.cgColor
        searchBar.layer.borderColor = blueColor.cgColor
        locationMapView.showsUserLocation = true
        

        //testing only to preset location to current
        self.location = getLocation(manager: locationManager)
        //testing only to preset location to current
        
        let coordinate = getLocation(manager: locationManager)
        reverseGeocoding(latitude: coordinate.latitude, longitude: coordinate.longitude)
  
    
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
            self.locationLabel.text = trimmed
        }
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        //Ignore user
        UIApplication.shared.beginIgnoringInteractionEvents()
        //Activity Indicate
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()
        
        self.view.addSubview(activityIndicator)
        
        //hide search bar
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion:  nil)
        
        //create the search request
        let searchRequest = MKLocalSearchRequest()
        searchRequest.naturalLanguageQuery = searchBar.text
        let activeSearch = MKLocalSearch(request: searchRequest)
        activeSearch.start{ (response, error) in
            if response == nil{
                print(error as Any)
            } else {
                //remove existing location annotation
                let annotations = self.locationMapView.annotations
                self.locationMapView.removeAnnotations(annotations)
                //getting data
                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude
                //creating annotation
                let annotaion = MKPointAnnotation()
                annotaion.coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                self.locationMapView.addAnnotation(annotaion)
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //set region/zoom in for map
        let location = self.location
        let coordinate = CLLocationCoordinate2DMake((location!.latitude), (location!.longitude))
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(coordinate, span)
        locationMapView.setRegion(region, animated: true)
    }
    
    //MARK: - Functions
    
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
        dismiss(animated: true) { 
        }
    }
    
    
}
