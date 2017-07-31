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

var defaults: UserDefaults = UserDefaults.standard

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: - Properties
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    var greenColor = UIColor(red: 90/255, green: 196/255, blue: 128/255, alpha: 1)
    var grayColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    //MARK: - Functions
    
    @IBAction func resetButtonTapped(_ sender: Any) {
        let popOverVC = UIStoryboard(name: "Login", bundle:nil).instantiateViewController(withIdentifier: "ResetEmailViewController") as! ResetEmailViewController
        self.addChildViewController(popOverVC)
        popOverVC.view.frame = self.view.frame
        UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
            self.view.addSubview(popOverVC.view)
        }, completion: nil)
        popOverVC.didMove(toParentViewController: self)
    }
    
    @IBAction func getStartedButtonTapped(_ sender: UIButton) {
        
        guard let authUI = FUIAuth.defaultAuthUI()
            else { return }
        authUI.delegate = self
        
        let authViewController = authUI.authViewController()
        present(authViewController, animated: true)
        
    }
    @IBAction func withoutAccountButtonTapped(_ sender: Any) {
        defaults.set("true", forKey:"loadedItems")
        defaults.set("false", forKey: "isLoggedIn")
        
        let initialViewController = UIStoryboard.initialViewController(for: .main)
        self.view.window?.rootViewController = initialViewController
        self.view.window?.makeKeyAndVisible()
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        print("login button tapped")
        
        self.buttonView.backgroundColor = grayColor
        self.view.isUserInteractionEnabled = false
        self.activityView.isHidden = false
        self.activityView.startAnimating()
        self.loginButton.setTitle("", for: .normal)
        
        if (emailTextField.text == "" )||(passwordTextField.text == ""){
            
            self.loginButton.isSelected = false
            self.activityView.isHidden = true
            self.buttonView.backgroundColor = self.greenColor
            self.view.isUserInteractionEnabled = true
            self.loginButton.setTitle("Log in", for: .normal)
            
            let alert = UIAlertController(title: "Did you enter in an email and password?", message: nil , preferredStyle: .alert)
            let cancel = UIAlertAction(title: "No?", style: .cancel, handler: { (action) in
                
            })
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
        } else {
            Auth.auth().signIn(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!) { (user, error) in
                if error != nil{
                    print(error.debugDescription)
                    self.loginButton.isSelected = false
                    self.activityView.isHidden = true
                    self.buttonView.backgroundColor = self.greenColor
                    self.view.isUserInteractionEnabled = true
                    self.loginButton.setTitle("Log in", for: .normal)
                    let alert = UIAlertController(title: "Incorrect email or password!", message: nil , preferredStyle: .alert)
                    let cancel = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
                    alert.addAction(cancel)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    
                    guard let user = user
                        else { return }
                    //redirect
                    defaults.set("false", forKey:"loadedItems")
                    defaults.set("true", forKey: "isLoggedIn")
                    
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
    
    override func viewWillAppear(_ animated: Bool) {
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.startTimer), userInfo: nil, repeats: true)
        self.loginButton.isSelected = false
        self.activityView.isHidden = true
        self.buttonView.backgroundColor = greenColor
        self.view.isUserInteractionEnabled = true
        self.loginButton.setTitle("Log in", for: .normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.greenColor = buttonView.backgroundColor!
        self.buttonView.clipsToBounds = true
        self.buttonView.layer.cornerRadius = 15
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

extension LoginViewController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith user: FIRUser?, error: Error?) {
        //report error
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
