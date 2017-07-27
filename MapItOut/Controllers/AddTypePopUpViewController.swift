//
//  AddTypePopUpViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/24/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import UIKit

class AddTypePopUpViewController: UIViewController, UITextFieldDelegate{
    
    //MARK：- Properties
    
    @IBOutlet weak var popUpView: UIView!
    @IBOutlet weak var typeTextField: UITextField!
    
    //MARK: - Lifecycles
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        typeTextField.delegate = self
        self.popUpView.layer.cornerRadius = 22.5
        self.popUpView.clipsToBounds = true
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.typeTextField.becomeFirstResponder()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AddTypePopUpViewController.dismissView))
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(AddTypePopUpViewController.dismissView))
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(AddTypePopUpViewController.dismissView))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        swipeUp.direction = UISwipeGestureRecognizerDirection.up
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(swipeDown)
        view.addGestureRecognizer(swipeUp)
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: - Functions
    
    func dismissView(){
            self.view.endEditing(true)
            UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                self.view.removeFromSuperview()
            }, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let parent = self.parent as! AddEntryViewController
        parent.pickOption.append(typeTextField.text!)
        parent.typeTextField.text = typeTextField.text!
        self.view.endEditing(true)
        UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
            self.view.removeFromSuperview()
        }, completion: nil)
        return true
    }
}
