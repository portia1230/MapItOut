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
    @IBOutlet weak var contactName: UILabel!
    @IBOutlet weak var relationshipLabel: UILabel!
    @IBOutlet weak var contactAddress: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        
        //fititng the photo
        self.contactImage.layer.cornerRadius = 35
        self.contactButton.layer.cornerRadius = 15
        self.contactImage.clipsToBounds = true
    }
}
