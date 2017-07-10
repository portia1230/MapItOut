//
//  AddEntryViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/10/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import Foundation
import UIKit

class AddEntryViewController: UIViewController{
    
//MARK: - Properties
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var uploadPhotoButton: UIButton!
    @IBOutlet weak var addContactButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photoImageView.layer.cornerRadius = 77.5
        uploadPhotoButton.layer.cornerRadius = 77.5
    }
}
