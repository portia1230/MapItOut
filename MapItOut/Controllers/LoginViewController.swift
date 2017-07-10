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
        
        if let current =  {
            
        } else {
        guard let authUI = FUIAuth.defaultAuthUI()
        else { return }
        
        authUI.delegate = self
        
        let authViewController = authUI.authViewController()
        present(authViewController, animated: true)
        }
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
        //report error
        if let error = error {
            assertionFailure("Error signing in: \(error.localizedDescription)")
        }
        // check to see whether user had been authorized
        guard let user = user
            else { return }
        //redirect
        let userRef = Database.database().reference().child("users").child(user.uid)
        userRef.observeSingleEvent(of: .value, with: { [unowned self] (snapshot) in
            if let user = User(snapshot: snapshot) {
                User.setCurrent(user)
                
                let storyboard = UIStoryboard(name: "Main", bundle: .main)
                if let initialViewController = storyboard.instantiateInitialViewController() {
                    self.view.window?.rootViewController = initialViewController
                    self.view.window?.makeKeyAndVisible()
                }
            }
        })
    }
}
