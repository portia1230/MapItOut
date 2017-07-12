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

class CustomTableViewController: UITableViewController {
    
    var keys : [String] = []
    var contacts : [Entry] = []
    var location = ""
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let ref = Database.database().reference().child("Users").child(User.currentUser.uid).child("Contacts")
        let contactRef = Database.database().reference().child("Contacts").child(User.currentUser.uid)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            let a = snapshot.value.flatMap { return $0 } as! NSDictionary
            print(a)
            let b = a.allValues as! [String]
            self.keys = b
            
            for key in self.keys {
                let refInner = contactRef.child(key)
                refInner.observeSingleEvent(of: .value, with: { (snapshotInner) in
                    let a = snapshotInner.value.flatMap{ return $0 } as! NSDictionary
                    //print(a)
                    let b = a.allValues
                    //print(b)
                    let entry = Entry(firstName: b[1] as! String, lastName: b[8] as! String, longitude: b[2] as! Double, latitude: b[6] as! Double , relationship: b[7] as! String, imageURL: b[5] as! String, number: b[0] as! String, email: b[3] as! String, key: b[4] as! String)
                    
                    self.contacts.append(entry)
                    
                })
            }
            
        })
        
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
        
        reverseGeocoding(latitude: contact.latitude, longitude: contact.longitude)
        cell.addressLabel.text = self.location
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
    
    func reverseGeocoding(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        var trimmed = ""
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) -> Void in
            if error != nil{
                print(error as Any)
                return
            } else if (placemarks?.count)! > 0 {
                let pm = placemarks![0]
                let address = ABCreateStringWithAddressDictionary(pm.addressDictionary!, false)
                trimmed = address
            }
            trimmed = trimmed.replacingOccurrences(of: "\n", with: ", ")
            self.location = trimmed
        }
    }
    
}
