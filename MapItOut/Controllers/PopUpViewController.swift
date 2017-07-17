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

class PopUpViewController : UIViewController{
    //MARK: - Properties
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var relationshipTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var addressDescription: UITextView!
    @IBOutlet weak var contactMapView: MKMapView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var contactImage: UIImageView!
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        deleteButton.layer.cornerRadius = 15
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        self.view.removeFromSuperview()
    }
}
