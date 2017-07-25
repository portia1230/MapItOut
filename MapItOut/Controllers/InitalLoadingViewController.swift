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
    
    @IBOutlet weak var progressLabel: UILabel!
    
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        
        UserService.items(for: User.currentUser, completion: { (entries) in
            
            var i = 0 {
                didSet {
                    DispatchQueue.main.async {
                        self.progressLabel.text = "\(i)/\(entries.count)"
                    }
                }
            }
            
            self.progressLabel.text = "0/\(entries.count)"
            if entries.count != 0{
                let increaseAngle = Float( 1.0/(Double(entries.count)) )
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
                        UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                            self.parent?.viewWillAppear(true)
                            self.view.removeFromSuperview()
                        })
                    }
                    i += 1
                }
            } else{
                self.parent?.viewWillAppear(true)
                self.view.removeFromSuperview()
            }
        })
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
