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
import FirebaseAuth

class ContactListController: UIViewController, MKMapViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - Properties
    
    @IBOutlet weak var tableView: UITableView!
    var keys : [String] = []
    var contacts : [Entry] = []
    var locationDescription = ""
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    var contactStore = CNContactStore()
    var authHandle: AuthStateDidChangeListenerHandle?
    
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        authHandle = Auth.auth().addStateDidChangeListener() { [unowned self] (auth, user) in
            guard user == nil else { return }
            
            let loginViewController = UIStoryboard.initialViewController(for: .login)
            self.view.window?.rootViewController = loginViewController
            self.view.window?.makeKeyAndVisible()
        }
        
    }
    
    deinit {
        if let authHandle = authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        UserService.contacts(for: User.currentUser) { (contacts) in
//            if contacts == nil{
//                self.viewWillAppear(true)
//            } else {
            let sortedContacts = LocationService.rankDistance(entries: contacts)
            self.contacts = sortedContacts
            self.tableView.reloadData()
            //}
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
        UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
            self.view.addSubview(popOverVC.view)
        }, completion: nil)
        popOverVC.didMove(toParentViewController: self)
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 108
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath){
        if editingStyle == .delete{
            let ref = Database.database().reference().child("Contacts").child(User.currentUser.uid).child(contacts[indexPath.row].key)
            ref.removeValue()
            viewWillAppear(true)
            
        }
    }
    
    
    @IBAction func settingButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Settings", message: nil, preferredStyle: .actionSheet)
        let signOutAction = UIAlertAction(title: "Sign out", style: .default) { _ in
            do {
                try Auth.auth().signOut()
            } catch let error as NSError {
                assertionFailure("Error signing out: \(error.localizedDescription)")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(signOutAction)
        self.present(alertController, animated: true)
    }
    
    @IBAction func mapButtonTapped(_ sender: Any) {
        dismiss(animated: false) {
        }
    }
    @IBAction func addButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: "How would you like to create a new contact", preferredStyle: .alert)
        
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
