//
//  ViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/9/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseAuthUI
import FirebaseDatabase

typealias FIRUser = FirebaseAuth.User

class LoginViewController: UIViewController {
    
    //MARK: - Properties

    @IBOutlet weak var getStartedButton: UIButton!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Funtions
    
    @IBAction func getStartedButtonTapped(_ sender: UIButton) {
        guard let authUI = FUIAuth.defaultAuthUI()
        else { return }
        
        authUI.delegate = self
        
        let authViewController = authUI.authViewController()
        present(authViewController, animated: true)
    }
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getStartedButton.layer.cornerRadius = 15
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension LoginViewController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith user: FIRUser?, error: Error?) {
        if let error = error {
            assertionFailure("Error signing in: \(error.localizedDescription)")
            return
        }
        guard let user = user
            else { return }
        
        //assigning name to model user
        
//        let userRef = Database.database().reference().child("users").child(user.uid)
//        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
//            
//            let name = ["name" : user.displayName]
//            let email = ["email" : user.email]
//            userRef.setValue(name) { (error, userRef) in
//                if let error = error {
//                    assertionFailure(error.localizedDescription)
//                    return
//                }
//            }
//            userRef.setValue(email) { (error, userRef) in
//                if let error = error {
//                    assertionFailure(error.localizedDescription)
//                    return
//                }
//            }
//            print("Welcome back, \(user.displayName!) \(user.email!).")
//            
//        })
        UserService.create(user, name: user.displayName!, email: user.email!) { (user) in
            guard let user = user else { return }
        }
    }
}

