//
//  ResetEmailViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/24/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import UIKit
import FirebaseAuth

class ResetEmailViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: - Properties
    
    @IBOutlet weak var popUpView: UIView!
    @IBOutlet weak var emailTextField: UITextField!
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        self.popUpView.layer.cornerRadius = 15
        self.popUpView.clipsToBounds = true
        
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(ResetEmailViewController.dismissView))
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(ResetEmailViewController.dismissView))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        swipeUp.direction = UISwipeGestureRecognizerDirection.up
        view.addGestureRecognizer(swipeDown)
        view.addGestureRecognizer(swipeUp)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.emailTextField.becomeFirstResponder()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - Functions
    
    @IBAction func sendEmailButtonTapped(_ sender: Any) {
        if emailTextField.text == ""{
            let alertController = UIAlertController(title: nil, message: "No email entered", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true)
        } else {
            self.view.endEditing(true)
            UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                self.view.removeFromSuperview()
            }, completion: nil)
            Auth.auth().sendPasswordReset(withEmail: (self.emailTextField.text!)) { error in
                let alertController = UIAlertController(title: nil, message: "An reset password email has been sent to \((self.emailTextField.text!))", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true)
            }
            
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendEmailButtonTapped(self)
        return true
    }
    
    func dismissView(){
        if UIApplication.shared.isKeyboardPresented{
            self.view.endEditing(true)
        } else {
            UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                self.view.removeFromSuperview()
            }, completion: nil)
        }
    }
}
