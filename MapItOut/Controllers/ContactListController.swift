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

class ContactListController: UIViewController, MKMapViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate {
    
    //MARK: - Properties
    @IBOutlet weak var numberCountLabel: UILabel!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var typeTextField: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var pickerUIView: UIView!
    
    var keys : [String] = []
    var sortedItems : [Item] = []
    var items = [Item]()
    var filteredItems : [Item] = []
    var locationDescription = ""
    var selectedIndex = 0
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    var contactStore = CNContactStore()
    var authHandle: AuthStateDidChangeListenerHandle?
    var pickerOptions = ["All items"]
    
    
    //MARK: - Functions
    
    @IBAction func filterButtonTapped(_ sender: Any) {
        if pickerUIView.isHidden == true {
            pickerOptions.removeAll()
            pickerOptions.append("All items")
            self.items = CoreDataHelper.retrieveItems()
            for item in self.items {
                if pickerOptions.contains(item.type!) == false{
                    self.pickerOptions.append(item.type!)
                    self.pickerOptions.sort()
                }
                self.pickerView.reloadAllComponents()
            }
            self.pickerUIView.isHidden = false
        } else {
            pickerUIView.isHidden = true
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerOptions.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.pickerOptions[row]
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        typeTextField.text = pickerOptions[row]
        defaults.set(typeTextField.text, forKey: "type")
        self.filteredItems.removeAll()
        if pickerOptions[row] == "All items"{
            self.filteredItems = self.sortedItems
        } else {
            for item in self.sortedItems{
                if item.type == self.typeTextField.text!{
                    self.filteredItems.append(item)
                }
            }
        }
        self.numberCountLabel.text = "(" + String(self.filteredItems.count) + ")"
        self.tableView.reloadData()
        self.pickerUIView.isHidden = true
    }
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        pickerView.delegate = self
        
        authHandle = Auth.auth().addStateDidChangeListener() { [unowned self] (auth, user) in
            guard user == nil else { return }
            
            let loginViewController = UIStoryboard.initialViewController(for: .login)
            self.view.window?.rootViewController = loginViewController
            self.view.window?.makeKeyAndVisible()
            defaults.set("false", forKey:"loadedItems")
        }
        
        
        
    }
    
    deinit {
        if let authHandle = authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.startTimer), userInfo: nil, repeats: true)
        
        if (CLLocationManager.authorizationStatus() == .restricted) || (CLLocationManager.authorizationStatus() == .denied)  {
            let alertController = UIAlertController(title: nil, message:
                "We do not have access to your location, please go to Settings/ Privacy/ Location and give us permission", preferredStyle: UIAlertControllerStyle.alert)
            let cancel = UIAlertAction(title: "I authorized", style: .cancel, handler: { (action) in
                self.viewWillAppear(true)
            })
            alertController.addAction(cancel)
            self.present(alertController, animated: true, completion: nil)
        }
        
        self.typeTextField.text = defaults.string(forKey: "type")
        self.pickerUIView.isHidden = true
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.items = CoreDataHelper.retrieveItems()
        self.sortedItems = LocationService.rankDistance(items: self.items)
        filterItems(type: self.typeTextField.text!)
    }
    
    func updateValue(item: Item){
        
        self.sortedItems.remove(at: self.selectedIndex)
        self.sortedItems.append(item)
        self.sortedItems = LocationService.rankDistance(items: self.sortedItems)
        filterItems(type: self.typeTextField.text!)
        
    }
    
    func filterItems(type : String){
        self.sortedItems = LocationService.rankDistance(items: CoreDataHelper.retrieveItems())
        self.filteredItems.removeAll()
        if type == "All items"{
            self.filteredItems = self.sortedItems
        } else {
            for item in self.sortedItems{
                if item.image == nil{
                    item.image = #imageLiteral(resourceName: "noContactImage.png")
                    CoreDataHelper.saveItem()
                }
                if item.type == type{
                    self.filteredItems.append(item)
                }
            }
        }
        self.numberCountLabel.text = "(" + String(self.filteredItems.count) + ")"
        self.tableView.reloadData()
    }
    
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredItems.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableCell
        let item = self.filteredItems[indexPath.row]
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
        self.items = CoreDataHelper.retrieveItems()
        while i < self.filteredItems.count {
            if self.filteredItems[indexPath.row].key == self.items[i].key{
                self.selectedIndex = i
            }
            i += 1
        }
        
        let popOverVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewController(withIdentifier: "PopUpViewController") as! PopUpViewController
        let selectedItem = self.filteredItems[indexPath.row]
        
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
            let imageRef = Storage.storage().reference().child("images/items/\(User.currentUser.uid)/\(sortedItems[selectedIndex].key!).jpg")
            imageRef.delete(completion: nil)
            
            ItemService.deleteEntry(key: sortedItems[selectedIndex].key!)
            self.filteredItems.remove(at: indexPath.row)
            CoreDataHelper.deleteItems(item: self.sortedItems[selectedIndex])
            self.tableView.reloadData()
        }
    }
    
    @IBAction func settingButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Settings", message: nil, preferredStyle: .actionSheet)
        let signOutAction = UIAlertAction(title: "Sign out", style: .default) { _ in
            do {
                try Auth.auth().signOut()
                defaults.set("false", forKey:"loadedItems")
                self.items = CoreDataHelper.retrieveItems()
                for item in self.items {
                    CoreDataHelper.deleteItems(item: item)
                }
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
            defaults.set(self.typeTextField.text!, forKey:"type")
            self.parent?.viewWillAppear(true)
            
        }
    }
    @IBAction func addButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: "How would you like to create a new item", preferredStyle: .alert)
        
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
                    } else {
                        self.performSegue(withIdentifier: "contactsSegue", sender: self)
                    }
                })
            default:
                let alertController = UIAlertController(title: nil, message:
                    "We do not have access to your Contacts, please go to Settings/ Privacy/ Contacts and give us permission", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Okay!", style: .cancel,handler: nil ))
                self.present(alertController, animated: true, completion: nil)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Create new item", style: .default, handler:  { action in self.performSegue(withIdentifier: "addContactSegue", sender: self) }))
        alert.addAction(UIAlertAction(title: "Back", style: .cancel , handler: nil))
        self.present(alert, animated: true, completion: nil)
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
