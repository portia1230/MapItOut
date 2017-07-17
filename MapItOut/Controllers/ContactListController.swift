//
//  CustomTableViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/11/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Kingfisher
import MapKit
import AddressBookUI
import ContactsUI

class ContactListController: UIViewController, MKMapViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var popUpTableView: UIView!
    //MARK: - Properties
    
    @IBOutlet weak var tableView: UITableView!
    var keys : [String] = []
    var contacts : [Entry] = []
    var locationDescription = ""
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    var contactStore = CNContactStore()
    
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        UserService.contacts(for: User.currentUser) { (contacts) in
            if contacts == nil{
                self.viewWillAppear(true)
            } else {
            let sortedContacts = LocationService.rankDistance(entries: contacts)
            self.contacts = sortedContacts
            self.tableView.reloadData()
            }
        }
        
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        return self.contacts.count
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        let popOverVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewController(withIdentifier: "PopUpViewController") as! PopUpViewController
        let selectedContact = contacts[indexPath.row]
        
        let imageURL = URL(string: selectedContact.imageURL)
        popOverVC.firstName = selectedContact.firstName
        popOverVC.lastName = selectedContact.lastName
        popOverVC.address = selectedContact.locationDescription
        popOverVC.relationship = selectedContact.relationship
        popOverVC.contactPhoto.kf.setImage(with: imageURL!)
        popOverVC.email = selectedContact.email
        popOverVC.phoneNumber = selectedContact.number
        popOverVC.latitude = selectedContact.latitude
        popOverVC.longitude = selectedContact.longitude
        popOverVC.keyOfContact = selectedContact.key
        
        if popOverVC.contactPhoto.image == nil{
            popOverVC.contactPhoto.kf.setImage(with: imageURL!)
        }
        
        self.addChildViewController(popOverVC)
        popOverVC.view.frame = self.view.frame
        UIView.transition(with: self.view, duration: 0.3, options: .transitionCrossDissolve, animations: { _ in
            self.view.addSubview(popOverVC.view)
        }, completion: nil)
        popOverVC.didMove(toParentViewController: self)
    }
    
    
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "bigCell", for: indexPath) as! SelectedTableViewCell
//        let contact = self.contacts[indexPath.row]
//        let imageURL = URL(string: contact.imageURL)
//        let locationManager = CLLocationManager()
//        let myCoordinate = LocationService.getLocation(manager: locationManager)
//        let myLocation = CLLocation(latitude: myCoordinate.latitude, longitude: myCoordinate.longitude)
//        let contactLocation = CLLocation(latitude: contacts[indexPath.row].latitude, longitude: contacts[indexPath.row].longitude)
//        let distance = myLocation.distance(from: contactLocation)
//        
//        if distance > 1000.0
//        {
//            cell.distanceLabel.text = " \(Int(distance/1000)) KM away"
//        } else {
//            cell.distanceLabel.text = " \(Int((distance * 1000).rounded())/1000) M away"
//        }
//        
//        cell.photoImageView.layer.cornerRadius = 62.5
//        cell.addressLabel.text = contact.locationDescription
//        cell.nameLabel.text = contact.firstName + " " + contact.lastName
//        cell.relationshipLabel.text = contact.relationship
//        cell.photoImageView.kf.setImage(with: imageURL)
//        cell.photoImageView.clipsToBounds = true
//
//    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if (tableView.cellForRow(at: indexPath)?.isSelected)!{
//            return 200
//        }
        return 108
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath){
        if editingStyle == .delete{
            let ref = Database.database().reference().child("Contacts").child(User.currentUser.uid).child(contacts[indexPath.row].key)
            ref.removeValue()
            viewWillAppear(true)
            
        }
    }
    
    
    @IBAction func mapButtonTapped(_ sender: Any) {
        dismiss(animated: false) {
        }
    }
    @IBAction func addButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: "How would you like to create a new contact", preferredStyle: .actionSheet)
        
        //Import from Contacts segue
        alert.addAction(UIAlertAction(title: "Import from Contacts", style: .default, handler:  { action in
            let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
            switch authorizationStatus {
            case .authorized:
                print("Authorized")
                self.performSegue(withIdentifier: "contactsSegue", sender: self)
            case .notDetermined: // needs to ask for authorization
                self.contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (accessGranted, error) -> Void in
                    if error != nil{
                        let alertController = UIAlertController(title: nil, message:
                            "We do not have access to your Contacts, please go to Settings/ Privacy/ Contacts and give us permission", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "Okay!", style: UIAlertActionStyle.cancel,handler: nil ))
                        self.present(alertController, animated: true, completion: nil)
                    }
                })
            default:
                let alertController = UIAlertController(title: nil, message:
                    "We do not have access to your Contacts, please go to Settings/ Privacy/ Contacts and give us permission", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Okay!", style: .cancel,handler: nil ))
                self.present(alertController, animated: true, completion: nil)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Create new contact", style: .default, handler:  { action in self.performSegue(withIdentifier: "addContactSegue", sender: self) }))
        alert.addAction(UIAlertAction(title: "Back", style: .cancel , handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
}
