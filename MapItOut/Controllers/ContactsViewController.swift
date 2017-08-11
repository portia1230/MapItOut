//
//  ContactsTableViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/13/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import UIKit
import ContactsUI
import Foundation
import CoreLocation
import FirebaseStorage
import Firebase

class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    //MARK: - Properties
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBOutlet weak var loadingStackView: UIStackView!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    var contacts = [CNContact]()
    var results = [CNContact]()
    var contactStore = CNContactStore()
    @IBOutlet weak var tableView: UITableView!
    var geocoder = CLGeocoder()
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var importContactActivityView: UIActivityIndicatorView!
    @IBOutlet weak var importContactsLabel: UILabel!
    
    @IBOutlet weak var importAllButton: UIButton!
    @IBOutlet weak var importContactsView: UIStackView!
    //MARK: - Functions
    
    @IBAction func backButtonTapped(_ sender: Any) {
        UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
            self.view.removeFromSuperview()
        }, completion: nil)
    }
    
    func dismissKeyboard(){
        view.endEditing(true)
    }
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        self.importAllButton.layer.cornerRadius = 15
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        UIView.transition(with: self.view, duration: 0.5, options: .transitionCrossDissolve, animations: { _ in
            self.loadingView.isHidden = false
            self.activityView.startAnimating()
            self.backButton.isHidden = true
            self.view.isUserInteractionEnabled = false
            self.importContactsView.isHidden = true
            self.importAllButton.isHidden = true
            self.loadingStackView.isHidden = false
        })
        tableView.delegate = self
        tableView.dataSource = self
        self.contacts.removeAll()
        self.results.removeAll()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let keys = [CNContactIdentifierKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey, CNContactImageDataKey, CNContactPhoneNumbersKey, CNContactOrganizationNameKey,CNContactImageDataKey, CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName)] as [Any]
        let request = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        
        do {
            try self.contactStore.enumerateContacts(with: request) {
                (contact, stop) in
                if contact.postalAddresses.isEmpty == false{
                    self.contacts.append(contact)
                }
                self.loadingLabel.text = "Finding Contacts with addresses"
            }
        }
        catch {
            print("unable to fetch contacts")
        }
        loadContacts()
    }
    
    
    //Functions
    
    func loadContacts(){
        self.contacts = self.contacts.sorted(by: { (contact1, contact2) -> Bool in
            return contact1.givenName.compare(contact2.givenName) == ComparisonResult.orderedAscending
        })
        self.results = self.contacts
        UIView.transition(with: self.view, duration: 0.5, options: .transitionCrossDissolve, animations: { _ in
            self.view.isUserInteractionEnabled = true
            self.loadingView.isHidden = true
            self.backButton.isHidden = false
            self.tableView.reloadData()
            self.importAllButton.isHidden = false
            self.loadingStackView.isHidden = true
        }, completion: nil)
    }
    
    @IBAction func importAllButtonTapped(_ sender: Any) {
        self.importContactActivityView.startAnimating()
        self.importContactsView.isHidden = false
        self.loadingView.isHidden = false
        self.view.isUserInteractionEnabled = false
        
        self.importContactsLabel.text = "Filtering \(self.results.count) contacts"
        var i = 0
        var count = 0
        var filteredContacts = self.contacts
        var index = 0
        while i < self.contacts.count {
            //var thisIsGood = false
            for item in CoreDataHelper.retrieveItems(){
                if item.contactKey! == self.contacts[i].identifier{
                    filteredContacts.remove(at: i+index)
                    index -= 1
                    break
                }
            }
            i += 1
        }
        i = 0
        count = filteredContacts.count
        self.importContactsLabel.text = "Imported 0/\(count) new contacts"
        if count > 0{
            while i < count{
                self.importContactsLabel.text = "Imported \(i+1)/\(count) new contacts"
                let contact = filteredContacts[i]
                let newItem = CoreDataHelper.newItem()
                
                if contact.givenName.isEmpty == false{
                    newItem.name = contact.givenName
                } else{
                    newItem.name = ""
                }
                if contact.familyName.isEmpty == false {
                    if newItem.name == ""{
                        newItem.name = contact.familyName
                    } else {
                        newItem.name = newItem.name! + " " + contact.familyName
                    }
                }
                if contact.emailAddresses.isEmpty == false {
                    newItem.email = contact.emailAddresses[0].value as String
                } else {
                    newItem.email = ""
                }
                if contact.organizationName.isEmpty == false{
                    newItem.organization = contact.organizationName
                } else {
                    newItem.organization = ""
                }
                if contact.phoneNumbers.count != 0 {
                    newItem.phone = contact.phoneNumbers[0].value.stringValue
                } else {
                    newItem.phone = ""
                }
                if contact.imageData?.isEmpty == false {
                    newItem.image = UIImage(data: contact.imageData!)!
                } else {
                    newItem.image = #imageLiteral(resourceName: "noContactImage.png")
                }
                
                newItem.type = "Phone Contacts"
                newItem.key = ""
                newItem.url = ""
                newItem.contactKey = contact.identifier
                CoreDataHelper.saveItem()
                
                if contact.postalAddresses.count != 0 {
                    let address = contact.postalAddresses[0].value
                    let string = address.street + " " + address.city + " " + address.state + " " + address.country
                    let simpleString = address.city + " " + address.state + " " + address.country
                    let dumbedString = address.city + " " + address.country
                    newItem.locationDescription = string
                    getCoordinate(addressString: string, simpleString: simpleString, dumbedString: dumbedString, country: address.country, completionHandler: { (location, error) in
                        newItem.latitude = location.latitude
                        newItem.longitude = location.longitude
                        CoreDataHelper.saveItem()
                        
                        if defaults.string(forKey: "isLoggedIn") == "true"{
                            
                            let currentUser = User.currentUser
                            let entryRef = Database.database().reference().child("Contacts").child(currentUser.uid).childByAutoId()
                            newItem.key = entryRef.key
                            CoreDataHelper.saveItem()
                            
                            let imageRef = StorageReference.newContactImageReference(key: newItem.key!)
                            StorageService.uploadHighImage(newItem.image as! UIImage, at: imageRef) { (downloadURL) in
                                guard let downloadURL = downloadURL else {
                                    return
                                }
                                let urlString = downloadURL.absoluteString
                                newItem.url = urlString
                                CoreDataHelper.saveItem()
                                if defaults.string(forKey: "type") == newItem.type{
                                    var count = defaults.string(forKey: "count")
                                    count = count?.replacingOccurrences(of: "(", with: "")
                                    count = count?.replacingOccurrences(of: ")", with: "")
                                    let number = Int(count!)
                                    defaults.set("(" + String(describing: number! + 1) + ")", forKey: "count")
                                }
                                
                                let entry = Entry(name: newItem.name!, organization: newItem.organization!, longitude: newItem.longitude, latitude: newItem.latitude, type: "Phone Contacts", imageURL: newItem.url!, phone: newItem.phone!, email: newItem.email!, key: newItem.key!, locationDescription: newItem.locationDescription!, contactKey: newItem.contactKey!)
                                ItemService.addEntry(entry: entry)
                                
                                if i == filteredContacts.count{
                                    
                                    if self.parent is MainViewController{
                                        let parent = self.parent as! MainViewController
                                        parent.viewWillAppear(true)
                                        parent.viewDidAppear(true)
                                    }
                                    if self.parent is ContactListController{
                                        let parent = self.parent as! ContactListController
                                        parent.viewWillAppear(true)
                                        parent.viewDidAppear(true)
                                    }
                                    if self.view.superview != nil{
                                        self.importContactsView.isHidden = true
                                        self.loadingView.isHidden = true
                                        self.view.isUserInteractionEnabled = true
                                        self.loadingStackView.isHidden = false
                                        UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                                            self.view.removeFromSuperview()
                                        }, completion: nil)
                                    }
                                }
                            }
                        } else {
                            
                            if self.parent is MainViewController{
                                let parent = self.parent as! MainViewController
                                parent.viewWillAppear(true)
                                parent.viewDidAppear(true)
                            }
                            if self.parent is ContactListController{
                                let parent = self.parent as! ContactListController
                                parent.viewWillAppear(true)
                                parent.viewDidAppear(true)
                            }
                            
                            if defaults.string(forKey: "type") == newItem.type{
                                var count = defaults.string(forKey: "count")
                                count = count?.replacingOccurrences(of: "(", with: "")
                                count = count?.replacingOccurrences(of: ")", with: "")
                                let number = Int(count!)
                                defaults.set("(" + String(describing: number! + 1) + ")", forKey: "count")
                            }
                            if i == filteredContacts.count-1 {
                                
                                self.importContactsView.isHidden = true
                                self.loadingView.isHidden = true
                                self.view.isUserInteractionEnabled = true
                                self.loadingStackView.isHidden = false
                                if self.view.superview != nil{
                                    
                                    UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                                        self.view.removeFromSuperview()
                                    }, completion: nil)
                                }
                            }
                        }
                        
                    })
                }
                
                i += 1
            }
        } else {
            self.importContactsView.isHidden = true
            self.loadingView.isHidden = true
            self.view.isUserInteractionEnabled = true
            self.loadingStackView.isHidden = false
            if self.view.superview != nil{
                UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                    self.view.removeFromSuperview()
                }, completion: nil)
            }
        }
    }
    
    //MARK: - Search bar delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.results.removeAll()
        
        if searchBar.text == ""{
            self.results = self.contacts
            self.tableView.reloadData()
        }
        else {
            var i = 0
            while i < contacts.count {
                let name = contacts[i].givenName + contacts[i].familyName
                if name.contains((searchBar.text)!){
                    self.results.append(contacts[i])
                }
                i += 1
            }
            self.tableView.reloadData()
        }
    }
    
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.results.removeAll()
        if searchBar.text == ""{
            self.results = self.contacts
        }
        var i = 0
        while i < contacts.count {
            let name = contacts[i].givenName + contacts[i].familyName
            if name.contains((searchBar.text)!){
                results.append(contacts[i])
            }
            i += 1
        }
        self.tableView.reloadData()
        dismissKeyboard()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        self.results = self.contacts
        self.tableView.reloadData()
        dismissKeyboard()
    }
    
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
            self.view.removeFromSuperview()
            if self.parent is MainViewController{
                let parent = self.parent as! MainViewController
                let contact = self.results[indexPath.row]
                if parent.reusableVC == nil {
                    let storyboard = UIStoryboard.init(name: "Main", bundle: .main)
                    let addVC = storyboard.instantiateViewController(withIdentifier: "AddEntryViewController")
                    parent.reusableVC = addVC as? AddEntryViewController
                    parent.reusableVC?.modalTransitionStyle = .coverVertical
                }
                parent.reusableVC?.contactLocationDescription = ""
                parent.reusableVC?.name = ""
                parent.reusableVC?.organization = ""
                parent.reusableVC?.type = ""
                parent.reusableVC?.phone = ""
                parent.reusableVC?.email = ""
                parent.reusableVC?.image = #imageLiteral(resourceName: "noContactImage.png")
                parent.reusableVC?.type = "Phone Contacts"
                if contact.givenName.isEmpty == false{
                    parent.reusableVC?.name = contact.givenName
                }
                if contact.familyName.isEmpty == false {
                    if parent.reusableVC?.name == ""{
                        parent.reusableVC?.name = contact.familyName
                    } else {
                        parent.reusableVC?.name.append(" " + contact.familyName)
                    }
                }
                if contact.emailAddresses.isEmpty == false {
                    parent.reusableVC?.email = contact.emailAddresses[0].value as String
                }
                if contact.organizationName.isEmpty == false{
                    parent.reusableVC?.organization = contact.organizationName
                }
                if contact.phoneNumbers.count != 0 {
                    parent.reusableVC?.phone = contact.phoneNumbers[0].value.stringValue
                }
                if contact.imageData?.isEmpty == false {
                    
                    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                    imageView.image = UIImage(data: contact.imageData!)!
                    imageView.contentMode = UIViewContentMode.scaleAspectFill
                    let layer: CALayer = imageView.layer
                    layer.masksToBounds = true
                    layer.cornerRadius = 100
                    UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 0.0)
                    layer.render(in: UIGraphicsGetCurrentContext()!)
                    let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    roundedImage?.draw(in: imageView.bounds)
                    UIGraphicsEndImageContext()
                    parent.reusableVC?.image = roundedImage!
                    // parent.reusableVC?.photoImageView.image = UIImage(data: contact.imageData!)!
                }
                
                if contact.postalAddresses.count != 0 {
                    let address = contact.postalAddresses[0].value
                    let string = address.street + " " + address.city + " " + address.state + " " + address.country + " " + address.postalCode
                    parent.reusableVC?.contactLocationDescription = string
                }
                parent.present(parent.reusableVC!, animated: true, completion: nil)
            } else {
                let contact = self.results[indexPath.row]
                let parent = self.parent as! ContactListController
                if parent.reusableVC == nil {
                    let storyboard = UIStoryboard.init(name: "Main", bundle: .main)
                    let addVC = storyboard.instantiateViewController(withIdentifier: "AddEntryViewController")
                    parent.reusableVC = addVC as? AddEntryViewController
                    parent.reusableVC?.modalTransitionStyle = .coverVertical
                }
                
                parent.reusableVC?.contactLocationDescription = ""
                parent.reusableVC?.name = ""
                parent.reusableVC?.organization = ""
                parent.reusableVC?.type = ""
                parent.reusableVC?.phone = ""
                parent.reusableVC?.email = ""
                parent.reusableVC?.image = #imageLiteral(resourceName: "noContactImage.png")
                parent.reusableVC?.type = "Phone Contacts"
                if contact.givenName.isEmpty == false{
                    parent.reusableVC?.name = contact.givenName
                }
                if contact.familyName.isEmpty == false {
                    if parent.reusableVC?.name == ""{
                        parent.reusableVC?.name = contact.familyName
                    } else {
                        parent.reusableVC?.name.append(" " + contact.familyName)
                    }
                }
                if contact.emailAddresses.isEmpty == false {
                    parent.reusableVC?.email = contact.emailAddresses[0].value as String
                }
                if contact.organizationName.isEmpty == false{
                    parent.reusableVC?.organization = contact.organizationName
                }
                if contact.phoneNumbers.count != 0 {
                    parent.reusableVC?.phone = contact.phoneNumbers[0].value.stringValue
                }
                if contact.imageData?.isEmpty == false {
                    parent.reusableVC?.image = UIImage(data: contact.imageData!)!
                }
                
                if contact.postalAddresses.count != 0 {
                    let address = contact.postalAddresses[0].value
                    let string = address.street + " " + address.city + " " + address.state + " " + address.country + " " + address.postalCode
                    parent.reusableVC?.contactLocationDescription = string
                }
                parent.present(parent.reusableVC!, animated: true, completion: nil)
            }
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        weak var cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? ContactsTableViewCell
        cell?.nameLabel.text = results[indexPath.row].givenName + " " + results[indexPath.row].familyName
        let value = results[indexPath.row].postalAddresses[0].value
        cell?.addressLabel.text = value.street + " " + value.city + " " + value.state + " " + value.country + " " + value.postalCode
        cell?.checkImageView.image! = #imageLiteral(resourceName: "unchecked.png")
        for item in CoreDataHelper.retrieveItems(){
            if item.contactKey! == results[indexPath.row].identifier{
                cell?.checkImageView.image! = #imageLiteral(resourceName: "checked.png")
            }
        }
        
        return cell!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "contactSelected" {
            let indexPath = tableView.indexPathForSelectedRow!
            let contact = self.results[indexPath.row]
            let displayTaskViewController = segue.destination as! AddEntryViewController
            if contact.givenName.isEmpty == false{
                displayTaskViewController.name = contact.givenName
            }
            if contact.familyName.isEmpty == false {
                if displayTaskViewController.name == ""{
                    displayTaskViewController.name = contact.familyName
                } else {
                    displayTaskViewController.name.append(" " + contact.familyName)
                }
            }
            if contact.emailAddresses.isEmpty == false {
                displayTaskViewController.email = contact.emailAddresses[0].value as String
            }
            if contact.organizationName.isEmpty == false{
                displayTaskViewController.organization = contact.organizationName
            }
            if contact.phoneNumbers.count != 0 {
                displayTaskViewController.phone = contact.phoneNumbers[0].value.stringValue
            }
            if contact.imageData?.isEmpty == false {
                displayTaskViewController.image = UIImage(data: contact.imageData!)!
            }
            
            if contact.postalAddresses.count != 0 {
                let address = contact.postalAddresses[0].value
                let string = address.street + " " + address.city + " " + address.state + " " + address.country + " " + address.postalCode
                displayTaskViewController.contactLocationDescription = string
            }
        }
        
    }
    
    
    func getCoordinate( addressString : String, simpleString: String, dumbedString:String, country: String,
                        completionHandler: @escaping(CLLocationCoordinate2D, NSError?) -> Void ) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressString) { (placemarks, error) in
            if error == nil {
                if let placemark = placemarks?[0] {
                    let location = placemark.location!
                    //let converted = LocationTransformHelper.wgs2gcj(wgsLat: location.coordinate.latitude, wgsLng: location.coordinate.longitude)
                    //let coordinate = CLLocationCoordinate2D(latitude: converted.gcjLat, longitude: converted.gcjLng)
                    let coordinate = location.coordinate
                    completionHandler(coordinate, nil)
                    return
                }
            } else {
                print(error.debugDescription)
                geocoder.geocodeAddressString(simpleString, completionHandler: { (placemarks, error) in
                    if error == nil {
                        if let placemark = placemarks?[0] {
                            let location = placemark.location!
                            let coordinate = location.coordinate
                            completionHandler(coordinate, nil)
                            return
                        }
                    } else {
                        geocoder.geocodeAddressString(dumbedString, completionHandler: { (placemarks, error) in
                            if error == nil {
                                if let placemark = placemarks?[0] {
                                    let location = placemark.location!
                                    let coordinate = location.coordinate
                                    completionHandler(coordinate, nil)
                                    return
                                }
                            } else {
                                geocoder.geocodeAddressString(country, completionHandler: { (placemarks, error) in
                                    if error == nil {
                                        if let placemark = placemarks?[0] {
                                            let location = placemark.location!
                                            let coordinate = location.coordinate
                                            completionHandler(coordinate, nil)
                                            return
                                        }
                                    }
                                })
                            }
                            
                        })
                        
                    }
                })
            }
            
        }
    }
    
}

