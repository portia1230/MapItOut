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
import CoreData
import FirebaseStorage

class ContactListController: UIViewController, MKMapViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - Properties
    
    @IBOutlet weak var tableView: UITableView!
    var keys : [String] = []
    var sortedItems : [Item] = []
    var locationDescription = ""
    var selectedIndex = 0
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
        let items = CoreDataHelper.retrieveItems()
        self.sortedItems = LocationService.rankDistance(items: items)
        self.tableView.reloadData()
        
    }
    
    func updateValue(item: Item){
        self.sortedItems[selectedIndex] = item
        self.sortedItems = LocationService.rankDistance(items: self.sortedItems)
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sortedItems.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableCell
            let item = self.sortedItems[indexPath.row]
            cell.addressLabel.text = item.locationDescription
            cell.nameLabel.text = item.name
            cell.typeLabel.text = item.type
            cell.photoImageView.image = item.image as? UIImage
            cell.photoImageView.layer.cornerRadius = 35
            cell.photoImageView.clipsToBounds = true
            return cell
        }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        var i = 0
        var items = CoreDataHelper.retrieveItems()
        while i < items.count {
            if sortedItems[indexPath.row].key == items[i].key{
                self.selectedIndex = i
            }
            i += 1
        }

        let popOverVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewController(withIdentifier: "PopUpViewController") as! PopUpViewController
        let selectedItem = self.sortedItems[indexPath.row]
        
        popOverVC.item = selectedItem
        popOverVC.name = selectedItem.name!
        popOverVC.organization = selectedItem.organization!
        popOverVC.address = selectedItem.locationDescription!
        popOverVC.type = selectedItem.type!
        popOverVC.contactPhoto = (selectedItem.image as? UIImage)!
        popOverVC.email = selectedItem.email!
        popOverVC.phone = selectedItem.phone!
        
        popOverVC.latitude = selectedItem.latitude
        popOverVC.longitude = selectedItem.longitude
        popOverVC.keyOfItem = selectedItem.key!
        
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
            CoreDataHelper.deleteItems(item: self.sortedItems[selectedIndex])
            
            self.tableView.reloadData()
            
            
            let imageRef = Storage.storage().reference().child("images/items/\(User.currentUser.uid)/\(sortedItems[selectedIndex].key!).jpg")
            imageRef.delete(completion: nil)
            ItemService.deleteEntry(key: sortedItems[selectedIndex].key!)
        }
    }
    
    @IBAction func settingButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Settings", message: nil, preferredStyle: .actionSheet)
        let signOutAction = UIAlertAction(title: "Sign out", style: .default) { _ in
            do {
                try Auth.auth().signOut()
                var items = CoreDataHelper.retrieveItems()
                items.removeAll()
                CoreDataHelper.saveItem()
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
