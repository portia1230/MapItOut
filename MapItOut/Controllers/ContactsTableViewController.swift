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

class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    //MARK: - Properties
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    var contacts = [CNContact]()
    var contactStore = CNContactStore()
    @IBOutlet weak var tableView: UITableView!
    
    
    //MARK: - Functions

    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: false) {
        }
    }

    //MARK: - Lifecycles

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.delegate = self
        tableView.dataSource = self
        let keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName) ]
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        do {
            try self.contactStore.enumerateContacts(with: request) {
                (contact, stop) in
                self.contacts.append(contact)
            }
        }
        catch {
            print("unable to fetch contacts")
        }
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContactsTableViewCell
        cell.nameLabel.text = contacts[indexPath.row].givenName + " " + contacts[indexPath.row].familyName
        
        return cell
    }

}
