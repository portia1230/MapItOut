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
    var contacts = [CNContact]()
    var results = [CNContact]()
    var contactStore = CNContactStore()
    var sectionName = [String]()
    
    @IBOutlet weak var tableView: UITableView!
    var geocoder = CLGeocoder()
    @IBOutlet weak var searchBar: UISearchBar!
    
    //MARK: - Functions
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: false) {
        }
    }
    
    func dismissKeyboard(){
        view.endEditing(true)
    }
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        
        view.addGestureRecognizer(tap)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.delegate = self
        tableView.dataSource = self
        self.contacts.removeAll()
        self.results.removeAll()
        let keys = [CNContactIdentifierKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey, CNContactImageDataKey, CNContactPhoneNumbersKey, CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName)] as [Any]
        let request = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        
        do {
            try self.contactStore.enumerateContacts(with: request) {
                (contact, stop) in
                self.contacts.append(contact)
                self.contacts = self.contacts.sorted(by: { (contact1, contact2) -> Bool in
                    return contact1.givenName.compare(contact2.givenName) == ComparisonResult.orderedAscending
                })
            }
            self.results = self.contacts
        }
        catch {
            print("unable to fetch contacts")
        }
    }
    
    //MARK: - Search bar delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
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
        
        performSegue(withIdentifier: "contactSelected", sender: self)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContactsTableViewCell
        cell.nameLabel.text = results[indexPath.row].givenName + " " + results[indexPath.row].familyName
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "contactSelected" {
            let indexPath = tableView.indexPathForSelectedRow!
            let contact = self.results[indexPath.row]
            let displayTaskViewController = segue.destination as! AddEntryViewController
            if contact.givenName.isEmpty == false {
                displayTaskViewController.firstName = contact.givenName
            }
            if contact.familyName.isEmpty == false{
                displayTaskViewController.lastName = contact.familyName
            }
            if contact.emailAddresses.isEmpty == false {
                displayTaskViewController.email = contact.emailAddresses[0].value as String
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








