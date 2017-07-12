//
//  CustomTableViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/11/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuthUI
import Kingfisher
import MapKit
import AddressBookUI

class CustomTableViewController: UITableViewController, MKMapViewDelegate, UITextFieldDelegate {
    
    var keys : [String] = []
    var contacts : [Entry] = []
    var locationDescription = ""
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserService.contacts(for: User.currentUser) { (contacts) in
            self.contacts = contacts
            self.tableView.reloadData()
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        return self.contacts.count
    
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableCell
        let contact = self.contacts[indexPath.row]
        let imageURL = URL(string: contact.imageURL)
    
        cell.addressLabel.text = contact.locationDescription
        cell.nameLabel.text = contact.firstName + " " + contact.lastName
        cell.relationshipLabel.text = contact.relationship
        cell.photoImageView.kf.setImage(with: imageURL)
        cell.photoImageView.layer.cornerRadius = 35
        cell.photoImageView.clipsToBounds = true
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 108
        
    }
    
}
