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
    
    @IBOutlet weak var label: UILabel!
    //MARK: - Lifecycles
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.startTimer), userInfo: nil, repeats: true)
        
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        
        UserService.items(for: User.currentUser, completion: { (entries) in
            
            self.label.text = "Loading \(entries.count) images, do not close this app"
            
            UserService.items(for: User.currentUser, completion: { (entries) in
                var i = 0
                while i < entries.count{
                    let imageView = UIImageView()
                    let url = URL(string: entries[i].imageURL)
                    let imageData:NSData = NSData(contentsOf: url!) ?? NSData()
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
                }
                
                UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                    self.parent?.viewWillAppear(true)
                    self.view.removeFromSuperview()
                })
            })
            
        })
            
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Timer
    func startTimer(){
        if InternetConnectionHelper.connectedToNetwork() == false{
            let alertController = UIAlertController(title: "No internet connection", message: nil, preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Retry", style: .default, handler: { (alert) in
                if InternetConnectionHelper.connectedToNetwork() == true{
                    self.dismiss(animated: true, completion: nil)
                }
            })
            alertController.addAction(cancel)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    
    
}
