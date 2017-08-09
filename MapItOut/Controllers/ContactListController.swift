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
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var numberCountLabel: UILabel!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var typeTextField: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var pickerUIView: UIView!
    @IBOutlet weak var plusImageView: UIImageView!
    
    var reusableVC : AddEntryViewController?
    var reusableContactsVC: ContactsViewController?
    var reusableAboutVC: AboutViewController?
    var popOverVC: PopUpViewController?
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
    var numberCount = ""
    
    
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
        defaults.set(numberCountLabel.text, forKey: "count")
        defaults.set(typeTextField.text, forKey: "type")
        self.tableView.reloadData()
        self.pickerUIView.isHidden = true
    }
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        pickerView.delegate = self
        
        if defaults.string(forKey: "isLoggedIn") == "true"{
            authHandle = Auth.auth().addStateDidChangeListener() { [unowned self] (auth, user) in
                guard user == nil else { return }
                
                let loginViewController = UIStoryboard.initialViewController(for: .login)
                self.view.window?.rootViewController = loginViewController
                self.view.window?.makeKeyAndVisible()
                defaults.set("false", forKey:"loadedItems")
            }
        }
        
    }
    
    deinit {
        if let authHandle = authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.backgroundView.isHidden = true
        self.plusImageView.isHidden = false
        self.pickerUIView.isHidden = true
        self.view.isUserInteractionEnabled = true
        self.typeTextField.text = defaults.string(forKey: "type")
        if defaults.string(forKey: "isCanceledAction") == "false"{
            self.numberCountLabel.text = "-"
        }
        if defaults.string(forKey: "isCanceledAction") == "false"{
            self.view.isUserInteractionEnabled = false
            self.plusImageView.isHidden = true
            self.filteredItems.removeAll()
            self.items.removeAll()
            self.sortedItems.removeAll()
            self.tableView.reloadData()
            if numberCount != "0"{
                self.numberCountLabel.text = numberCount
                numberCount = "0"
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if defaults.string(forKey: "isCanceledAction") == "false"{
            super.viewDidAppear(animated)
            _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.startTimer), userInfo: nil, repeats: true)
            
            if (CLLocationManager.authorizationStatus() == .restricted) || (CLLocationManager.authorizationStatus() == .denied)  {
                let alertController = UIAlertController(title: nil, message:
                    "We do not have access to your location, please go to Settings/ Privacy/ Location and give us permission", preferredStyle: UIAlertControllerStyle.alert)
                let cancel = UIAlertAction(title: "I authorized", style: .cancel, handler: { (action) in
                    self.reloadView()
                })
                alertController.addAction(cancel)
                self.present(alertController, animated: true, completion: nil)
            }
            self.pickerUIView.isHidden = true
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.items = CoreDataHelper.retrieveItems()
            self.sortedItems = LocationService.rankDistance(items: self.items)
            filterItems(type: self.typeTextField.text!)
        } else {
            defaults.set("false", forKey: "isCanceledAction")
        }
        
        self.view.isUserInteractionEnabled = true
        self.plusImageView.isHidden = false
    }
    
    func reloadView(){
        if defaults.string(forKey: "isCanceledAction") == "false"{
            _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.startTimer), userInfo: nil, repeats: true)
            
            if (CLLocationManager.authorizationStatus() == .restricted) || (CLLocationManager.authorizationStatus() == .denied)  {
                let alertController = UIAlertController(title: nil, message:
                    "We do not have access to your location, please go to Settings/ Privacy/ Location and give us permission", preferredStyle: UIAlertControllerStyle.alert)
                let cancel = UIAlertAction(title: "I authorized", style: .cancel, handler: { (action) in
                    self.viewDidAppear(true)
                })
                alertController.addAction(cancel)
                self.present(alertController, animated: true, completion: nil)
            }
            self.pickerUIView.isHidden = true
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.items = CoreDataHelper.retrieveItems()
            self.sortedItems = LocationService.rankDistance(items: self.items)
            filterItems(type: self.typeTextField.text!)
        } else {
            defaults.set("false", forKey: "isCanceledAction")
        }
        
        self.view.isUserInteractionEnabled = true

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
            if self.filteredItems.count == 0 {
                self.typeTextField.text = "All items"
                self.filteredItems = self.sortedItems
                defaults.set("All items", forKey: "type")
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
        if cell.photoImageView.image == nil{
            cell.photoImageView.image = #imageLiteral(resourceName: "noContactImage.png")
        }
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
        
        if self.popOverVC == nil{
            self.popOverVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewController(withIdentifier: "PopUpViewController") as? PopUpViewController
        }
        let selectedItem = self.filteredItems[indexPath.row]
        popOverVC?.item = selectedItem
        popOverVC?.name = selectedItem.name!
        popOverVC?.organization = selectedItem.organization!
        popOverVC?.address = selectedItem.locationDescription!
        popOverVC?.type = selectedItem.type!
        popOverVC?.contactPhoto = (selectedItem.image as? UIImage) ?? #imageLiteral(resourceName: "noContactImage.png")
        if selectedItem.image == nil{
            selectedItem.image = #imageLiteral(resourceName: "noContactImage.png")
            CoreDataHelper.saveItem()
        }
        popOverVC?.email = selectedItem.email!
        popOverVC?.phone = selectedItem.phone!
        
        popOverVC?.latitude = selectedItem.latitude
        popOverVC?.longitude = selectedItem.longitude
        popOverVC?.keyOfItem = selectedItem.key!
        popOverVC?.url = selectedItem.url!
        popOverVC?.view.endEditing(true)
        
        if self.popOverVC?.email != ""{
            if let emailURL:URL = URL(string: "mailto:qingfeng1230@gmail.com") {
                let application:UIApplication = UIApplication.shared
                if !(application.canOpenURL(emailURL)) {
                    self.popOverVC?.emailButton.isHidden = true
                    self.popOverVC?.emailImageView.isHidden = true
                } else {
                    self.popOverVC?.emailButton.isHidden = false
                    self.popOverVC?.emailImageView.isHidden = false
                }
            }
        }
        
        if self.popOverVC?.phone != ""{
            if let emailURL:URL = URL(string: "tel:111") {
                let application:UIApplication = UIApplication.shared
                if !(application.canOpenURL(emailURL)) {
                    self.popOverVC?.phoneButton.isHidden = true
                    self.popOverVC?.phoneImageView.isHidden = true
                } else {
                    self.popOverVC?.phoneButton.isHidden = false
                    self.popOverVC?.phoneImageView.isHidden = false
                }
            }
        }
        
        self.addChildViewController((self.popOverVC)!)
        popOverVC?.view.frame = self.view.frame
        self.backgroundView.isHidden = false
        popOverVC?.didMove(toParentViewController: self)
        
        UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
            self.view.addSubview((self.popOverVC?.view)!)
        }, completion: nil)
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 108
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath){
        
        if editingStyle == .delete{
            if defaults.string(forKey: "isLoggedIn") == "true"{
                let imageRef = Storage.storage().reference().child("images/items/\(User.currentUser.uid)/\(sortedItems[selectedIndex].key!).jpg")
                imageRef.delete(completion: nil)
                ItemService.deleteEntry(key: sortedItems[indexPath.row].key!)
            }
            
            CoreDataHelper.deleteItems(item: self.filteredItems[indexPath.row])
            self.items = CoreDataHelper.retrieveItems()
            self.sortedItems = LocationService.rankDistance(items: self.items)
            self.filteredItems.remove(at: indexPath.row)
            self.numberCountLabel.text = "(" + String(self.filteredItems.count) + ")"
            if self.filteredItems.count == 0 {
                self.typeTextField.text = "All items"
                self.filteredItems = self.sortedItems
                defaults.set("All items", forKey: "type")
                self.numberCountLabel.text = "(" + String(self.filteredItems.count) + ")"
            }
            self.tableView.reloadData()
        }
    }
    
    @IBAction func settingButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Settings", message: nil, preferredStyle: .actionSheet)
        
        let popOver = alertController.popoverPresentationController
        popOver?.sourceView  = sender as? UIView
        popOver?.sourceRect = (sender as! UIView).bounds
        popOver?.permittedArrowDirections = UIPopoverArrowDirection.any
        
        let viewContactsAction = UIAlertAction(title: "Import from Contacts", style: .default) { (alert) in
            let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
            switch authorizationStatus {
            case .authorized:
                print("Authorized")
                
                if self.reusableContactsVC == nil {
                    let storyboard = UIStoryboard.init(name: "Main", bundle: .main)
                    let addVC = storyboard.instantiateViewController(withIdentifier: "ContactsViewController")
                    self.reusableContactsVC = addVC as? ContactsViewController
                    self.reusableContactsVC?.modalTransitionStyle = .crossDissolve
                    self.addChildViewController(self.reusableContactsVC!)
                    UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                        self.view.addSubview((self.reusableContactsVC?.view)!)
                    }, completion: nil)
                } else {
                    UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                        self.view.addSubview((self.reusableContactsVC?.view)!)
                    }, completion: nil)
                }
                
            case .denied, .restricted: // needs to ask for authorization
                let alertController = UIAlertController(title: nil, message:
                    "We do not have access to your Contacts, please go to Settings/ Privacy/ Contacts and give us permission", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Okay!", style: UIAlertActionStyle.cancel,handler: nil ))
                self.present(alertController, animated: true, completion: nil)
            default:
                let alertController = UIAlertController(title: nil, message:
                    "We do not have access to your Contacts, please go to Settings/ Privacy/ Contacts and give us permission", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Okay!", style: .cancel,handler: nil ))
                self.present(alertController, animated: true, completion: nil)
            }
            
        }
        
        alertController.addAction(viewContactsAction)
        if defaults.string(forKey: "isLoggedIn") == "true"{
            let signOutAction = UIAlertAction(title: "Sign out", style: .default) { _ in
                do {
                    try Auth.auth().signOut()
                    defaults.set("false", forKey:"loadedItems")
                    defaults.set("notSet", forKey: "isLoggedIn")
                    self.items = CoreDataHelper.retrieveItems()
                    for item in self.items {
                        CoreDataHelper.deleteItems(item: item)
                    }
                    //CoreDataHelper.saveItem()
                } catch let error as NSError {
                    assertionFailure("Error signing out: \(error.localizedDescription)")
                }
            }
            let resetPasswordAction = UIAlertAction(title: "Reset password", style: .default) { _ in
                do {
                    Auth.auth().sendPasswordReset(withEmail: (Auth.auth().currentUser?.email)!) { error in
                        if error != nil{
                            let alertController = UIAlertController(title: nil, message: "Error: \(error.debugDescription)", preferredStyle: .alert)
                            let cancelAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
                            alertController.addAction(cancelAction)
                            self.present(alertController, animated: true)
                        } else {
                            
                            let alertController = UIAlertController(title: nil, message: "An reset password email has been sent to \((Auth.auth().currentUser?.email)!)", preferredStyle: .alert)
                            let cancelAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
                            alertController.addAction(cancelAction)
                            self.present(alertController, animated: true)
                        }
                    }
                }
            }
            alertController.addAction(signOutAction)
            alertController.addAction(resetPasswordAction)
        } else {
            let addAccount = UIAlertAction(title: "Create account", style: .default, handler: { (alert) in
                let confirmAlert = UIAlertController(title: "Warning!", message: "NO ITEMS YOU ENTERED WILL BE SAVED", preferredStyle: .alert)
                let confirm = UIAlertAction(title: "Confirm", style: .default, handler: { (alert) in
                    for item in CoreDataHelper.retrieveItems(){
                        CoreDataHelper.deleteItems(item: item)
                        CoreDataHelper.saveItem()
                    }
                    let loginViewController = UIStoryboard.initialViewController(for: .login)
                    self.view.window?.rootViewController = loginViewController
                    self.view.window?.makeKeyAndVisible()
                    defaults.set("false", forKey:"loadedItems")
                    defaults.set("notSet", forKey: "isLoggedIn")
                })
                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (alert) in
                    self.dismiss(animated: true, completion: {
                    })
                })
                confirmAlert.addAction(confirm)
                confirmAlert.addAction(cancel)
                self.present(confirmAlert, animated: true, completion: {
                })
            })
            alertController.addAction(addAccount)
        }
        let aboutButton = UIAlertAction(title: "About", style: .default) { (alert) in
            if self.reusableAboutVC == nil {
                let storyboard = UIStoryboard.init(name: "Main", bundle: .main)
                let addVC = storyboard.instantiateViewController(withIdentifier: "AboutViewController")
                self.reusableAboutVC = addVC as? AboutViewController
                self.reusableAboutVC?.modalTransitionStyle = .crossDissolve
                self.addChildViewController(self.reusableAboutVC!)
                UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                    self.backgroundView.isHidden = false
                    self.view.addSubview((self.reusableAboutVC?.view)!)
                }, completion: nil)
            } else {
                UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                    self.backgroundView.isHidden = false
                    self.view.addSubview((self.reusableAboutVC?.view)!)
                }, completion: nil)
            }
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(aboutButton)
        self.present(alertController, animated: true)
    }
    
    @IBAction func mapButtonTapped(_ sender: Any) {
        defaults.set(self.typeTextField.text!, forKey:"type")
        dismiss(animated: false) {
        }
    }
    @IBAction func addButtonTapped(_ sender: Any) {
        if reusableVC == nil {
            let storyboard = UIStoryboard.init(name: "Main", bundle: .main)
            let addVC = storyboard.instantiateViewController(withIdentifier: "AddEntryViewController")
            reusableVC = addVC as? AddEntryViewController
            reusableVC?.modalTransitionStyle = .coverVertical
            present(reusableVC!, animated: true, completion: nil)
        } else {
            reusableVC?.contactLocationDescription = ""
            reusableVC?.name = ""
            reusableVC?.organization = ""
            reusableVC?.type = ""
            reusableVC?.phone = ""
            reusableVC?.email = ""
            reusableVC?.image = #imageLiteral(resourceName: "noContactImage.png")
            reusableVC?.photoImageView.image = #imageLiteral(resourceName: "noContactImage.png")
            reusableVC?.photoImageView.alpha = 0
            
            present(reusableVC!, animated: true, completion: nil)
        }
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
