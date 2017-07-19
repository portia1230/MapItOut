//
//  SignInPopUpViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/19/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import UIKit

class SignInPopUpViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: - Properties
    
    @IBOutlet weak var nameTextField: UITextField!
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
        
        nameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        rePasswordTextField.delegate = self
        passwordWarningLabel.isHidden = true
        createButton.layer.cornerRadius = 15
        nameTextField.tag = 0
        emailTextField.tag = 1
        passwordTextField.tag = 2
        rePasswordTextField.tag = 3
        
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
    
    
    
}
