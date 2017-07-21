//
//  InitalLoadingViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/21/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import UIKit

class InitalLoadingViewController: UIViewController {

    
    //MARK: - Properties
    
    @IBOutlet weak var circularProgress: CustomCircularProgress!
    
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    
    override func viewWillAppear(_ animated: Bool) {
        circularProgress.startAngle = 0
        UserService.items(for: User.currentUser, completion: { (entries) in
            var i = 0
            let increaseAngle = Int( 360 / (entries.count))
            while i < entries.count{
                let imageView = UIImageView()
                let url = URL(string: entries[i].imageURL)
                let imageData:NSData = NSData(contentsOf: url!)!
                imageView.image = UIImage(data: imageData as Data)
                
                let item = CoreDataHelper.newItem()
                item.email = entries[i].email
                item.name = entries[i].name
                item.type = entries[i].type
                item.phone = entries[i].phone
                item.organization = entries[i].organization
                item.latitude = entries[i].latitude
                item.longitude = entries[i].longitude
                item.locationDescription = entries[i].locationDescription
                item.key = entries[i].key
                item.image = imageView.image
                CoreDataHelper.saveItem()
                i += 1
                if i == entries.count - 1{
                    circularProgress.animate(toAngle: 360, duration: 0.5, completion:  nil)
                    self.dismiss(animated: true, completion: nil)
                } else {
                circularProgress.animate(toAngle: circularProgress.angle + increaseAngle, duration: 0.5, completion:  nil)
                }
            }
            
            self.viewWillAppear(true)
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
