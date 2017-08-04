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

class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    //MARK: - Properties
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
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
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        UIView.transition(with: self.view, duration: 0.5, options: .transitionCrossDissolve, animations: { _ in
            self.loadingView.isHidden = false
            self.activityView.startAnimating()
            self.backButton.isHidden = true
            self.view.isUserInteractionEnabled = false
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
        }, completion: nil)
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
                } else {
                    parent.reusableVC?.contactLocationDescription = ""
                    parent.reusableVC?.name = ""
                    parent.reusableVC?.organization = ""
                    parent.reusableVC?.type = ""
                    parent.reusableVC?.phone = ""
                    parent.reusableVC?.email = ""
                    parent.reusableVC?.image = #imageLiteral(resourceName: "noContactImage.png")
                    parent.reusableVC?.photoImageView.image = #imageLiteral(resourceName: "noContactImage.png")
                    parent.reusableVC?.photoImageView.alpha = 0
                }
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
                } else {
                    
                    parent.reusableVC?.contactLocationDescription = ""
                    parent.reusableVC?.name = ""
                    parent.reusableVC?.organization = ""
                    parent.reusableVC?.type = ""
                    parent.reusableVC?.phone = ""
                    parent.reusableVC?.email = ""
                    parent.reusableVC?.image = #imageLiteral(resourceName: "noContactImage.png")
                    parent.reusableVC?.photoImageView.alpha = 0
                }
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
}







