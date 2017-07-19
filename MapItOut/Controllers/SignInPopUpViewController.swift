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
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        rePasswordTextField.delegate = self
        passwordWarningLabel.isHidden = true
        
        nameTextField.tag = 0
        emailTextField.tag = 1
        passwordTextField.tag = 2
        rePasswordTextField.tag = 3
        
        createButton.layer.cornerRadius = 15
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
    }
    
    //MARK: - Functions
    
    func dismissView(){
        if UIApplication.shared.isKeyboardPresented{
            self.view.endEditing(true)
        } else {
            UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                self.view.removeFromSuperview()
            }, completion: nil)
        }
    }
    
    @IBAction func createButtonTapped(_ sender: Any) {
        let popOverVC = UIStoryboard(name: "login", bundle:nil).instantiateViewController(withIdentifier: "SignInPopUpViewController") as! PopUpViewController
        //let imageURL = URL(string: self.selectedContact.imageURL)
        
        self.addChildViewController(popOverVC)
        popOverVC.view.frame = self.view.frame
        UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
            self.view.addSubview(popOverVC.view)
        }, completion: nil)
        popOverVC.didMove(toParentViewController: self)
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
            } else {
                passwordWarningLabel.isHidden = true
            }
        }
    }

    
    
}
