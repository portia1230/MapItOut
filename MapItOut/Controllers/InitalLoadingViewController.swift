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
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        circularProgress.startAngle = -90
        //circularProgress.progress = 10
        var items = CoreDataHelper.retrieveItems()
        items.removeAll()
        CoreDataHelper.saveItem()
        
        UserService.items(for: User.currentUser, completion: { (entries) in
            var i = 0
            let increaseAngle = Double( 350 / (entries.count) )
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
                
                if i == entries.count - 1{
                    self.circularProgress.animate(fromAngle: self.circularProgress.angle, toAngle: 360, duration: 1.0, completion: { (bool) in
                        UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                            self.parent?.viewWillAppear(true)
                            self.view.removeFromSuperview()
                        }, completion: nil)
                        
                    })
                } else {
                    self.circularProgress.animate(toAngle: self.circularProgress.angle + increaseAngle, duration: 0.5, completion:  nil)
                }
                i += 1
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
