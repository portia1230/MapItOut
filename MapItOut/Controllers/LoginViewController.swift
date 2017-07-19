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

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: - Properties
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    //MARK: - Funtions
    
    @IBAction func getStartedButtonTapped(_ sender: UIButton) {
        
        guard let authUI = FUIAuth.defaultAuthUI()
            else { return }
        
        authUI.delegate = self
        
        let authViewController = authUI.authViewController()
        present(authViewController, animated: true)
        
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        print("login button tapped")
        if (emailTextField.text == "" )||(passwordTextField.text == ""){
            let alert = UIAlertController(title: "Did you enter in an email and password?", message: nil , preferredStyle: .alert)
            let cancel = UIAlertAction(title: "No?", style: .cancel, handler: nil)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
        } else {
            Auth.auth().signIn(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!) { (user, error) in
                if error != nil{
                    let alert = UIAlertController(title: "Incorrect email or password!", message: nil , preferredStyle: .alert)
                    let cancel = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
                    alert.addAction(cancel)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    guard let user = user
                        else { return }
                    //redirect
                    UserService.show(forUID: user.uid) { (user) in
                        if let user = user {
                            User.setCurrent(user, writeToUserDefaults:  true)
                            let initialViewController = UIStoryboard.initialViewController(for: .main)
                            self.view.window?.rootViewController = initialViewController
                            self.view.window?.makeKeyAndVisible()
                        }
                    }
                    
                }
            }
        }
    }
    
    func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
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
    
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordTextField.delegate = self
        emailTextField.delegate = self
        emailTextField.tag = 0
        passwordTextField.tag = 1
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard))
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(swipeDown)
        self.loginButton.layer.cornerRadius = 15
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

extension LoginViewController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith user: FIRUser?, error: Error?) {
        //report error
        UserService.create(user!, name: (user?.displayName!)!, email: (user?.email!
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
