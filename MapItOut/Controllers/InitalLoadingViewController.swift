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
    var progressText = ""
    //MARK: - Lifecycles
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        progressLabel.text = progressText
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.startTimer), userInfo: nil, repeats: true)
        
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        
        let dispatchGroup = DispatchGroup()
        let i = CoreDataHelper.retrieveItems().count
        
        
        dispatchGroup.enter()
        UserService.items(for: User.currentUser, completion: { (entries) in
            self.progressLabel.text = "\(CoreDataHelper.retrieveItems().count)/\(entries.count)"
            if i == entries.count{
                
                UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                    self.parent?.viewWillAppear(true)
                    self.view.removeFromSuperview()
                })
                
            } else {
            if entries.count != 0{
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
                    
                    //self.progressLabel.text = "\(i)/\(entries.count)"
                    print(i)
                dispatchGroup.leave()
                dispatchGroup.notify(queue: .main) {
                    if i == entries.count - 1{
                        UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                            self.parent?.viewWillAppear(true)
                            self.view.removeFromSuperview()
                        })
                    } else {
                        self.parent?.viewWillAppear(true)
                        self.view.removeFromSuperview()
                    }
                }
            } else {
                self.view.removeFromSuperview()
                self.parent?.viewWillAppear(true)
            }
            }
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
