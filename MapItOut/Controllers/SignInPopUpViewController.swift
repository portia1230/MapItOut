//
//  SignInPopUpViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/19/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseAuthUI
import FirebaseDatabase

typealias FIRUser = FirebaseAuth.User

class SignInPopUpViewController: UIViewController, UITextFieldDelegate, FUIAuthDelegate {
    
    //MARK: - Properties
    

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var rePasswordTextField: UITextField!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var passwordWarningLabel: UILabel!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        rePasswordTextField.delegate = self
        passwordWarningLabel.isHidden = true
        createButton.layer.cornerRadius = 15
        emailTextField.tag = 0
        passwordTextField.tag = 1
        rePasswordTextField.tag = 2
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SignInPopUpViewController.dismissKeyboard))
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(SignInPopUpViewController.dismissKeyboard))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(swipeDown)
        
        //createButton.layer.cornerRadius = 15
    }
    
    //MARK: - Functions
    
    func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    
    @IBAction func returnButtonTapped(_ sender: Any) {
        self.dismiss(animated: true) {
        }
    }
    
    @IBAction func createButtonTapped(_ sender: Any) {
        
        let auth = FUIAuth(uiWith: Auth.auth())
        auth?.delegate = self
        
        auth?.auth?.createUser(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!) { (user, error) in
            if error != nil{
                print(error.debugDescription)
                return
            }
            auth?.auth?.signIn(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!) { (user, error) in
                
                self.authUI(auth!, didSignInWith: user!, error: error)
                if error != nil{
                    print(error.debugDescription)
                }
            }
        }
    }
    
    //MARK: - Text field delegate functions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if let nextTextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextTextField.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
        }
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if textField == rePasswordTextField {
            if passwordTextField.text != textField.text{
                passwordWarningLabel.isHidden = false
                passwordWarningLabel.text = "Passwords do not match!"
            } else {
                if (rePasswordTextField.text?.characters.count)! < 6{
                    passwordWarningLabel.isHidden = false
                    passwordWarningLabel.text = "Password does not exceed 6 characters!"
                } else {
                    passwordWarningLabel.isHidden = true
                }
            }
        }
        
    }

    func authUI(_ authUI: FUIAuth, didSignInWith user: FIRUser?, error: Error?) {
        
        UserService.create(user!, email: (user?.email!
                    )!) { (user) in
                }
                if let error = error {
                    assertionFailure("Error signing in: \(error.localizedDescription)")
        
                }
                // check to see whether user had been authorized
                guard let user = user
                    else { return }
                //redirect
                UserService.show(forUID: user.uid) { (user) in
                    if let user = user {
                        // handle existing user
                        User.setCurrent(user, writeToUserDefaults:  true)
                        let initialViewController = UIStoryboard.initialViewController(for: .main)
                        self.view.window?.rootViewController = initialViewController
                        self.view.window?.makeKeyAndVisible()
                    }
                }

    }
    
}


