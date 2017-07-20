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
    var sortedContacts : [Entry] = []
    var locationDescription = ""
    var selectedIndex = 0
    var images = [UIImage]()
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
        
        self.images.removeAll()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        UserService.contacts(for: User.currentUser) { (contacts) in
            let sortedContacts = LocationService.rankDistance(entries: contacts)
            self.sortedContacts = sortedContacts
            //self.tableView.reloadData()
            var i = 0
            var imageView = UIImageView()
            while i < self.sortedContacts.count{
                let imageURL = URL(string
                    : contacts[i].lowImageURL)
                imageView.kf.setImage(with: imageURL)
                
                if imageView.image == nil{
                    self.viewWillAppear(true)
                } else {
                    self.images.append(imageView.image!)
                    if (self.images.count == User.currentUser.entries.count ) && ( self.sortedContacts.count == User.currentUser.entries.count ){
                        self.tableView.reloadData()
                    }
                }
                i += 1
            }
        }
    }
    
    func updateValue(entry: Entry, image : UIImage){
        User.currentUser.entries.remove(at: self.selectedIndex)
        User.currentUser.entries.append(entry)
        self.sortedContacts = LocationService.rankDistance(entries: User.currentUser.entries)
        self.images.remove(at: self.selectedIndex)
        self.images.insert(image, at: self.selectedIndex)
        
        self.tableView.reloadData()
        
        UserService.contacts(for: User.currentUser) { (contacts) in
            let ref = Database.database().reference().child("Contacts").child(User.currentUser.uid).child(entry.key)
            let dictValue = entry.dictValue
            ref.updateChildValues(dictValue)
        }
        
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        return self.sortedContacts.count
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableCell
            let contact = self.sortedContacts[indexPath.row]
            cell.addressLabel.text = contact.locationDescription
            cell.nameLabel.text = contact.firstName + " " + contact.lastName
            cell.relationshipLabel.text = contact.relationship
            cell.photoImageView.image = self.images[indexPath.row]
            cell.photoImageView.layer.cornerRadius = 35
            cell.photoImageView.clipsToBounds = true
            self.images.append(cell.photoImageView.image!)
            return cell
        
        }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        var i = 0
        while i < User.currentUser.entries.count{
            if sortedContacts[indexPath.row].key == User.currentUser.entries[i].key{
                self.selectedIndex = i
            }
            i += 1
        }
        let popOverVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewController(withIdentifier: "PopUpViewController") as! PopUpViewController
        let selectedContact = self.sortedContacts[indexPath.row]
        
        popOverVC.firstName = selectedContact.firstName
        popOverVC.lastName = selectedContact.lastName
        popOverVC.address = selectedContact.locationDescription
        popOverVC.relationship = selectedContact.relationship
        popOverVC.contactPhoto.image = self.images[indexPath.row]
        popOverVC.email = selectedContact.email
        popOverVC.phoneNumber = selectedContact.number
        popOverVC.latitude = selectedContact.latitude
        popOverVC.longitude = selectedContact.longitude
        popOverVC.keyOfContact = selectedContact.key
        
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
            let ref = Database.database().reference().child("Contacts").child(User.currentUser.uid).child(self.sortedContacts[indexPath.row].key)
            ref.removeValue()
            var i = 0
            while i <  User.currentUser.entries.count{
                if User.currentUser.entries[i].key == self.sortedContacts[indexPath.row].key{
                    User.currentUser.entries.remove(at: i)
                }
                i += 1
            }
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
        let resetPasswordAction = UIAlertAction(title: "Reset password", style: .default) { _ in
            do {
                Auth.auth().sendPasswordReset(withEmail: (Auth.auth().currentUser?.email)!) { error in
                    let alertController = UIAlertController(title: nil, message: "An reset password email has been sent to \((Auth.auth().currentUser?.email)!)", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true)
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(signOutAction)
        alertController.addAction(resetPasswordAction)
        self.present(alertController, animated: true)

    }
    
    @IBAction func mapButtonTapped(_ sender: Any) {
        dismiss(animated: false) {
            self.parent?.viewWillAppear(true)
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
