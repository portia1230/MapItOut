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
    
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var rePasswordTextField: UITextField!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var passwordWarningLabel: UILabel!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    var greenColor = UIColor(red: 90/255, green: 196/255, blue: 128/255, alpha: 1)
    var grayColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    
    //MARK: - Lifecycles
    
    override func viewWillAppear(_ animated: Bool) {
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.startTimer), userInfo: nil, repeats: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.greenColor = buttonView.backgroundColor!
        self.buttonView.layer.cornerRadius = 15
        self.buttonView.clipsToBounds = true
        self.buttonView.isHidden = true
        emailTextField.delegate = self
        passwordTextField.delegate = self
        rePasswordTextField.delegate = self
        passwordWarningLabel.isHidden = true
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
        
        self.buttonView.backgroundColor = grayColor
        self.view.isUserInteractionEnabled = false
        self.activityView.isHidden = false
        self.activityView.startAnimating()
        self.createButton.setTitle("", for: .normal)
        
        let auth = FUIAuth(uiWith: Auth.auth())
        auth?.delegate = self
        
        auth?.auth?.createUser(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!) { (user, error) in
            if error != nil{
                
                self.buttonView.backgroundColor = self.greenColor
                self.view.isUserInteractionEnabled = true
                self.activityView.isHidden = true
                self.createButton.setTitle("Create!", for: .normal)
                
                print(error.debugDescription)
                let alertController = UIAlertController(title: nil, message: error?.localizedDescription, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true)
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
                self.buttonView.isHidden = true
            } else {
                if (rePasswordTextField.text?.characters.count)! < 6{
                    passwordWarningLabel.isHidden = false
                    passwordWarningLabel.text = "Password does not exceed 6 characters!"
                    self.buttonView.isHidden = true
                } else {
                    passwordWarningLabel.isHidden = true
                    self.buttonView.isHidden = false
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
    
    //MARK: - Timer
    func startTimer(){
        if InternetConnectionHelper.connectedToNetwork() == false{
            let alertController = UIAlertController(title: "No internet connection", message: nil, preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Retry", style: .default, handler: { (alert) in
                if InternetConnectionHelper.connectedToNetwork() == true{
                    self.dismiss(animated: true, completion: nil)
                }
            })
            alertController.addAction(cancel)
            present(alertController, animated: true, completion: nil)
        }
    }
    
}


