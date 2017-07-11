//
//  MainViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/9/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import Foundation
import UIKit

class MainViewController : UIViewController{
    
    //MARK: - Properties
    
    @IBOutlet weak var contactImage: UIImageView!
    @IBOutlet weak var contactButton: UIButton!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //fititng the photo
        contactImage.layer.cornerRadius = 35
        contactButton.layer.cornerRadius = 15
        contactImage.clipsToBounds = true
    }
}
