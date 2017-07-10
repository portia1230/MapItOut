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

class AddEntryViewController: UIViewController, MKMapViewDelegate{
    
//MARK: - Properties
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var locationMapView: MKMapView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var uploadPhotoButton: UIButton!
    @IBOutlet weak var addContactButton: UIButton!
    let blueColor = UIColor(red: 74/255, green: 88/255, blue: 178/255, alpha: 1)
    var photoHelper = MGPhotoHelper()
    
//MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationMapView.tintColor = blueColor
        photoImageView.layer.cornerRadius = 77.5
        uploadPhotoButton.layer.cornerRadius = 77.5
        photoImageView.clipsToBounds = true
        addContactButton.layer.cornerRadius = 15
        searchBar.layer.backgroundColor = blueColor.cgColor
        searchBar.layer.borderColor = blueColor.cgColor
        locationMapView.showsUserLocation = true
        locationMapView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //set region/zoom in for map
        let userLocation = locationMapView.userLocation
        
        let region = MKCoordinateRegionMakeWithDistance((userLocation.location?.coordinate)!, 2000, 2000)
        locationMapView.setRegion(region, animated: true)
    }
    
//MARK: - Functions
    
    @IBAction func uploadPhotoButtonTapped(_ sender: UIButton) {
        photoHelper.presentActionSheet(from: self)
        photoHelper.completionHandler = { image in
            self.photoImageView.image = image
        }
    }
    
    
    

    
}
