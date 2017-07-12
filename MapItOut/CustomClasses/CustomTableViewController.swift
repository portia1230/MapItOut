//
//  CustomTableViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/11/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuthUI
import Kingfisher
import MapKit

class CustomTableViewController: UITableViewController {

    var keys : [String] = []
    var contacts : [String] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        let ref = Database.database().reference().child("Users").child(User.currentUser.uid).child("Contacts")
        let contactRef = Database.database().reference().child("Contacts").child(User.currentUser.uid)
        
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            let a = snapshot.value.flatMap { return $0 } as! NSDictionary
            print(a)
            let b = a.allValues as! [String]
            self.keys = b
            
            for key in self.keys {
                let refInner = contactRef.child(key)
                refInner.observeSingleEvent(of: .value, with: { (snapshotInner) in
                    let a = snapshotInner.value.flatMap{ return $0 } as! NSDictionary
                    print(a)
                    let b = a.allValues
                    print(b)
                    let entry = Entry(firstName: b[1] as! String, lastName: b[8] as! String, longitude: b[2] as! Double, latitude: b[6] as! Double , relationship: b[7] as! String, imageURL: b[5] as! String, number: b[0] as! String, email: b[3] as! String, key: b[4] as! String)
                    
                    
                    
                })
            }
            
        })
        
        
        }
        
        
    

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 108
    }
        
        
//        
//        let ref = Database.database().reference().child("Contacts")
//        let contactInfo = ref.value(forKey: keys[indexPath.row]) as!  [String : Any]
//        
//        let imageURL = URL(string: contactInfo["imageURL"] as! String)
//        cell.photoImageView.kf.setImage(with: imageURL)
//        cell.addressLabel.text = contactInfo["address"] as! String
//        cell.nameLabel.text = contactInfo["name"] as? String
//        cell.relationshipLabel.text = contactInfo["relationship"] as? String


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
