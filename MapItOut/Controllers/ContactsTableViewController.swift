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
    let letterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
    var sectionedContacts = [[CNContact]]()
    var specialContacts = [CNContact]()
    var results = [[CNContact]]()
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
        self.sectionedContacts.removeAll()
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
        }
        catch {
            print("unable to fetch contacts")
        }
        for contact in self.contacts{
            let letter = String(describing: contact.givenName.characters.first)
            if sectionedContacts.count == 0{
                self.sectionedContacts.append([contact])
            } else {
                if (String(describing: sectionedContacts[sectionedContacts.count - 1][0].givenName.characters.first)) == letter {
                    self.sectionedContacts[self.sectionedContacts.count - 1].append(contact)
                } else {
                    if (String(contact.givenName.characters.first!)).rangeOfCharacter(from: letterSet as CharacterSet) == nil{
                        self.specialContacts.append(contact)
                    } else {
                    self.sectionedContacts.append([contact])
                    }
                }
            }
        }
        self.results = self.sectionedContacts
        
    }
    
    //MARK: - Search bar delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.results.removeAll()
        if searchBar.text == ""{
            self.results = self.sectionedContacts
        }
        var n = 0
        while n < sectionedContacts.count{
            var i = 0
            while i < sectionedContacts[n].count {
                let name = sectionedContacts[n][i].givenName + sectionedContacts[n][i].familyName
                if name.contains((searchBar.text)!){
                    results[n].remove(at: i)
                }
                i += 1
            }
            n += 1
        }
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        self.results = self.sectionedContacts
        self.tableView.reloadData()
        dismissKeyboard()
    }
    
    // MARK: - Table view data source
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        self.sectionName.removeAll()
        for contactGroup in results {
            let name = String(describing: (contactGroup[0].givenName.characters.first)!)
            sectionName.append(name.capitalized)
        }
        if self.specialContacts.isEmpty == false{
            sectionName.append("#")
        }
        return sectionName
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        performSegue(withIdentifier: "contactSelected", sender: self)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.specialContacts.isEmpty{
            return sectionName.count
        }
        return sectionName.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == results[section].count{
            return specialContacts.count
        }
        return results[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContactsTableViewCell
        cell.nameLabel.text = results[indexPath.section][indexPath.row].givenName + " " + results[indexPath.section][indexPath.row].familyName
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "contactSelected" {
            let indexPath = tableView.indexPathForSelectedRow!
            let contact = results[indexPath.section][indexPath.row]
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








