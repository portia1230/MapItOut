//
//  popUpViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 7/16/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import AddressBookUI
import FirebaseStorage
import FirebaseDatabase
import MessageUI

class PopUpViewController : UIViewController, MKMapViewDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, MKLocalSearchCompleterDelegate, UITableViewDelegate, UISearchBarDelegate, UITableViewDataSource{
    
    //MARK: - Properties
    
    var item: Item!
    @IBOutlet weak var resultTableView: UITableView!
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var changeImageButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var organizationTextField: UITextField!
    @IBOutlet weak var typeTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var contactMapView: MKMapView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var emailButton: UIButton!
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var phoneImageView: UIImageView!
    @IBOutlet weak var emailImageView: UIImageView!
    
    var OName = ""
    var OOrganization = ""
    var OType = ""
    var OPhone = "No number entered"
    var OEmail = "No email entered"
    var OAddress = ""
    var OLongitude = 0.0
    var OLatitude = 0.0
    var OContactPhoto = UIImage()
    var OOriginalLocation = ""
    var OLocation = CLLocationCoordinate2D()
    var isPhotoUpdated = false
    
    var name = ""
    var organization = ""
    var type = ""
    var phone = "No number entered"
    var email = "No email entered"
    var address = ""
    var longitude = 0.0
    var latitude = 0.0
    var contactPhoto = UIImage()
    var originalLocation = ""
    var locationManager = CLLocationManager()
    var location = CLLocationCoordinate2D()
    var photoHelper = MGPhotoHelper()
    var keyOfItem = ""
    
    var markerText = ""
    
    var greenColor = UIColor(red: 90/255, green: 196/255, blue: 128/255, alpha: 1)
    var greyColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
    var darkTextColor = UIColor(red: 90/255, green: 92/255, blue: 92/255, alpha: 1)
    var pickOption = ["Close Friend", "Co-worker", "Family", "Food", "Friend"]
    
    //MARK: - Local delegate location
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text != ""{
            self.resultTableView.isHidden = false
            searchCompleter.queryFragment = searchText
        } else {
            self.resultTableView.isHidden = true
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.resultTableView.isHidden = true
        searchBar.text = self.originalLocation
        self.dismissKeyboard()
    }
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.originalLocation = searchBar.text!
        self.searchBar.showsCancelButton = true
        self.searchBar.text = ""
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = false
        if searchBar.text == ""{
            self.resultTableView.isHidden = true
            searchBar.text = self.originalLocation
        }
        self.dismissKeyboard()
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        resultTableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        //error
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if searchResults.count == 0 {
            tableView.isHidden = true
        }
        tableView.isHidden = false
        let searchResult = searchResults[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LocationTableViewCell
        cell.locationLabel.text = searchResult.title
        cell.subLabel.text = searchResult.subtitle
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.searchBar.showsCancelButton = false
        self.undoButton.isEnabled = true
        self.undoButton.setTitleColor(UIColor.white, for: .normal)
        self.searchBar.resignFirstResponder()
        self.dismissKeyboard()
        let cell = tableView.cellForRow(at: indexPath) as! LocationTableViewCell
        self.originalLocation = cell.locationLabel.text! + " " + cell.subLabel.text!
        self.searchBar.text = cell.locationLabel.text! + " " + cell.subLabel.text!
        //self.searchResults[indexPath.row].
        
        let searchRequest = MKLocalSearchRequest(completion: self.searchResults[indexPath.row])
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            let coordinate = response?.mapItems[0].placemark.coordinate
            self.contactMapView.removeAnnotations(self.contactMapView.annotations)
            let anno = MKPointAnnotation()
            anno.coordinate = coordinate!
            let span = MKCoordinateSpanMake(0.1, 0.1)
            self.location = coordinate!
            let region = MKCoordinateRegion(center: anno.coordinate, span: span)
            self.contactMapView.setRegion(region, animated: true)
            self.contactMapView.addAnnotation(anno)
            
            self.longitude = anno.coordinate.longitude
            self.latitude = anno.coordinate.latitude
        }
        tableView.isHidden = true
        
    }
    
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        resultTableView.delegate = self
        
        var pickerView = UIPickerView()
        pickerView = UIPickerView(frame: CGRect(x: 0, y: 200, width: view.frame.width, height: 214))
        //pickerView.backgroundColor = .white
        //pickerView.showsSelectionIndicator = true
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PopUpViewController.donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let addTypeButton = UIBarButtonItem(title: "Add type", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PopUpViewController.addtype))
        
        toolBar.setItems([addTypeButton,spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        pickerView.delegate = self
        searchBar.delegate = self
        searchCompleter.delegate = self
        
        contactMapView.delegate = self
        nameTextField.delegate = self
        organizationTextField.delegate = self
        typeTextField.delegate = self
        phoneTextField.delegate = self
        emailTextField.delegate = self
        
        typeTextField.inputView = pickerView
        typeTextField.inputAccessoryView = toolBar
        
        nameTextField.tag = 0
        organizationTextField.tag = 1
        phoneTextField.tag = 2
        emailTextField.tag = 3
        
        phoneTextField.isUserInteractionEnabled = true
        nameTextField.isUserInteractionEnabled = true
        typeTextField.isUserInteractionEnabled = true
        organizationTextField.isUserInteractionEnabled = true
        emailTextField.isUserInteractionEnabled = true
        changeImageButton.isEnabled = true
        
        
        //dismiss keyboard gesture recognizer
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(PopUpViewController.dismissView))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        view.addGestureRecognizer(swipeDown)
        
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        deleteButton.layer.cornerRadius = 15
    }
    
    func donePicker(){
        self.typeTextField.resignFirstResponder()
    }
    
    func addtype(){
        let popOverVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewController(withIdentifier: "AddTypePopUpViewController" ) as! AddTypePopUpViewController
        self.addChildViewController(popOverVC)
        popOverVC.view.frame = self.view.frame
        UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
            self.view.addSubview(popOverVC.view)
        }, completion: nil)
        popOverVC.didMove(toParentViewController: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.startTimer), userInfo: nil, repeats: true)
        
        self.undoButton.setTitleColor(UIColor.clear, for: .normal)
        self.undoButton.isEnabled = false
        self.undoButton.layer.cornerRadius = 30
        self.itemImage.layer.cornerRadius = 70
        self.changeImageButton.layer.cornerRadius = 70
        self.itemImage.clipsToBounds = true
        contactMapView.isUserInteractionEnabled = false
        self.nameTextField.text = name
        self.organizationTextField.text = organization
        self.typeTextField.text = type
        self.phoneTextField.text = phone
        self.emailTextField.text = email
        self.searchBar.text = address
        let location = CLLocationCoordinate2DMake(latitude, longitude)
        self.location = location
        let annos = contactMapView.annotations
        let anno = MKPointAnnotation()
        self.itemImage.image = self.contactPhoto
        
        
        anno.coordinate = location
        
        if self.phoneTextField.text! == ""{
            self.phoneButton.isHidden = true
            self.phoneImageView.isHidden = true
        }
        
        if self.emailTextField.text! == ""{
            self.emailButton.isHidden = true
            self.emailImageView.isHidden = true
        }
        
        contactMapView.removeAnnotations(annos)
        contactMapView.addAnnotation(anno)
        
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(location, span)
        self.contactMapView.setRegion(region, animated: false)
        
        self.originalLocation = self.searchBar.text!
        
        if isPhotoUpdated{
            self.undoButton.isEnabled = true
            self.undoButton.setTitleColor(UIColor.white, for: .normal)
        } else {
            self.OContactPhoto = self.contactPhoto
        }
        
        self.OName = self.name
        self.OOrganization = self.organization
        self.OType = self.type
        self.OEmail = self.email
        self.OPhone = self.phone
        self.OAddress = self.originalLocation
        self.OLatitude = self.latitude
        self.OLongitude = self.longitude
        self.OLocation = self.location
        self.OOriginalLocation = self.originalLocation
        
    }
    
    
    
    
    //MARK: - VC Functions
    
    @IBAction func dimissButtonTapped(_ sender: Any) {
        self.dismissButton.isEnabled = false
        self.view.isUserInteractionEnabled = false
        dismissView()
    }
    @IBAction func undoButtonTapped(_ sender: Any) {
        self.nameTextField.text = self.OName
        self.organizationTextField.text = self.OOrganization
        self.typeTextField.text = self.OType
        self.emailTextField.text = self.OEmail
        self.phoneTextField.text = self.OPhone
        self.itemImage.image = self.OContactPhoto
        self.searchBar.text = self.OOriginalLocation
        let annotations = self.contactMapView.annotations
        self.contactMapView.removeAnnotations(annotations)
        self.searchBar.text = self.OOriginalLocation
        let anno = MKPointAnnotation()
        anno.coordinate = CLLocationCoordinate2D(latitude: self.OLatitude, longitude: self.OLongitude)
        let span = MKCoordinateSpanMake(0.1, 0.1)
        self.location = anno.coordinate
        let region = MKCoordinateRegion(center: anno.coordinate, span: span)
        self.contactMapView.setRegion(region, animated: true)
        self.contactMapView.addAnnotation(anno)
        self.undoButton.setTitleColor(UIColor.clear, for: .normal)
        self.undoButton.isEnabled = false
        self.isPhotoUpdated = false
    }
    
    @IBAction func mapButtonTapped(_ sender: Any) {
        
        let regionDistance:CLLocationDistance = 100000
        let coordinates = CLLocationCoordinate2DMake(self.location.latitude, self.location.longitude)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = self.nameTextField.text!
        mapItem.openInMaps(launchOptions: options)
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func phoneButtonTapped(_ sender: Any) {
        let composeVC = MFMessageComposeViewController()
        let name = self.nameTextField.text!
        composeVC.messageComposeDelegate = self
        composeVC.recipients = [self.phoneTextField.text!]
        composeVC.body = "Hey \(name), "
        self.present(composeVC, animated: true,completion: nil)
    }
    
    
    @IBAction func emailButtonTapped(_ sender: Any) {
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        // Configure the fields of the interface.
        composeVC.setToRecipients([self.emailTextField.text!])
        //composeVC.setSubject("")
        composeVC.setMessageBody("Hey \(self.nameTextField.text!)", isHTML: false)
        
        // Present the view controller modally.
        self.present(composeVC, animated: true, completion: nil)
        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        // Check the result or perform other tasks.
        
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        let items = CoreDataHelper.retrieveItems()
        for item in items{
            if item.key == self.keyOfItem{
                CoreDataHelper.deleteItems(item: item)
                if defaults.string(forKey: "isLoggedIn") == "true" {
                    let imageRef = Storage.storage().reference().child("images/items/\(User.currentUser.uid)/\(keyOfItem).jpg")
                    imageRef.delete(completion: nil)
                    ItemService.deleteEntry(key: self.keyOfItem)
                }
            }
        }
        
        UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
            self.view.removeFromSuperview()
        }, completion: nil)
        self.parent?.viewWillAppear(true)
    }
    
    @IBAction func changeImageButton(_ sender: Any) {
        photoHelper.presentActionSheet(from: self)
        photoHelper.completionHandler = { image in
            self.itemImage.image = image
            self.isPhotoUpdated = true
            self.contactPhoto = image
        }
    }
    
    func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    func dismissView(){
        if UIApplication.shared.isKeyboardPresented{
            self.view.endEditing(true)
            self.view.endEditing(true)
            if self.searchBar.text == ""{
                self.searchBar.text = OOriginalLocation
            }
        } else {
            if self.undoButton.isEnabled == true{
                
                if self.parent is MainViewController{
                    
                    let parent = self.parent as! MainViewController
                    CoreDataHelper.deleteItems(item: self.item)
                    
                    let item = CoreDataHelper.newItem()
                    item.email = self.emailTextField.text
                    item.image = self.itemImage.image
                    item.key = self.keyOfItem
                    item.latitude = self.latitude
                    item.longitude = self.longitude
                    item.name = self.nameTextField.text
                    item.locationDescription = self.searchBar.text
                    item.organization = self.organizationTextField.text
                    item.type = self.typeTextField.text
                    item.phone = self.phoneTextField.text
                    
                    CoreDataHelper.saveItem()
                    parent.updateValue(item: item)
                    
                    UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                        self.view.removeFromSuperview()
                    }, completion: nil)
                    
                    if defaults.string(forKey: "isLoggedIn") == "true"{
                        
                        let imageRef = Storage.storage().reference().child("images/items/\(User.currentUser.uid)/\((parent.selectedItem.key)!).jpg")
                        imageRef.delete(completion: nil)
                        let newImageRef = StorageReference.newContactImageReference(key: parent.selectedItem.key!)
                        
                        StorageService.uploadHighImage(itemImage.image!, at: newImageRef) { (downloadURL) in
                            guard let downloadURL = downloadURL else {
                                return
                            }
                            let urlString = downloadURL.absoluteString
                            let entry = Entry(name: self.nameTextField.text!, organization: self.organizationTextField.text!, longitude: self.longitude, latitude: self.latitude, type: self.typeTextField.text!, imageURL: urlString, phone: self.phoneTextField.text!, email: self.emailTextField.text!, key: self.keyOfItem, locationDescription: self.searchBar.text!)
                            ItemService.editEntry(entry: entry)
                        }
                        
                    }
                } else {
                    
                    let parent = self.parent as! ContactListController
                    CoreDataHelper.deleteItems(item: self.item)
                    
                    let item = CoreDataHelper.newItem()
                    
                    item.email = self.emailTextField.text
                    item.image = self.itemImage.image
                    item.key = self.keyOfItem
                    item.latitude = self.latitude
                    item.longitude = self.longitude
                    item.name = self.nameTextField.text
                    item.locationDescription = self.searchBar.text
                    item.organization = self.organizationTextField.text
                    item.type = self.typeTextField.text
                    item.phone = self.phoneTextField.text
                    
                    CoreDataHelper.saveItem()
                    parent.updateValue(item: item)
                    
                    UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                        self.view.removeFromSuperview()
                    }, completion: nil)
                    
                    if defaults.string(forKey: "isLoggedIn") == "true"{
                        
                        let imageRef = Storage.storage().reference().child("images/items/\(User.currentUser.uid)/\(item.key!).jpg")
                        imageRef.delete(completion: nil)
                        let newImageRef = StorageReference.newContactImageReference(key: item.key!)
                        
                        StorageService.uploadHighImage(itemImage.image!, at: newImageRef) { (downloadURL) in
                            guard let downloadURL = downloadURL else {
                                return
                            }
                            let urlString = downloadURL.absoluteString
                            let entry = Entry(name: self.nameTextField.text!, organization: self.organizationTextField.text!, longitude: self.longitude, latitude: self.latitude, type: self.typeTextField.text!, imageURL: urlString, phone: self.phoneTextField.text!, email: self.emailTextField.text!, key: self.keyOfItem, locationDescription: self.searchBar.text!)
                            ItemService.editEntry(entry: entry)
                        }
                    }
                }
            } else {
                UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                    self.view.removeFromSuperview()
                }, completion: nil)
            }
        }
    }
    
    //MARK: - Text field delegate functions
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.markerText = textField.text!
        self.undoButton.isEnabled = true
        self.undoButton.setTitleColor(UIColor.white, for: .normal)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if self.markerText != textField.text!{
            
            self.undoButton.isEnabled = true
            self.undoButton.setTitleColor(UIColor.white, for: .normal)
            
            if self.phoneTextField.text! != ""{
                self.phoneButton.isHidden = false
                self.phoneImageView.isHidden = false
            } else {
                self.phoneButton.isHidden = true
                self.phoneImageView.isHidden = true
            }
            
            if self.emailTextField.text! != ""{
                self.emailButton.isHidden = false
                self.emailImageView.isHidden = false
            } else {
                self.emailButton.isHidden = true
                self.emailImageView.isHidden = true
            }
        } else {
            if (textField.text == OPhone) || (textField.text == OEmail) || (textField.text == OName) || (textField.text == OType){
                self.undoButton.isEnabled = false
                self.undoButton.setTitleColor(UIColor.clear, for: .normal)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if let nextTextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextTextField.becomeFirstResponder()
            if nextTextField.tag == 5 {
                self.originalLocation = nextTextField.text!
                nextTextField.text = ""
            }
            
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
        }
        return false
    }
    
    //MARK: - Map View delegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        if !(annotation is MKPointAnnotation){
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "pinIdentifier")
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "pinIdentifier")
            annotationView!.canShowCallout = true
        } else {
            annotationView!.annotation = annotation
        }
        let pinImage = UIImage(named: "200*274pin")
        
        annotationView!.image = UIImage(cgImage: (pinImage?.cgImage)!, scale: 200/30, orientation: .up)
        return annotationView
        
    }
    
    //MARK: - Picker View functions
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickOption.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickOption[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        typeTextField.text = pickOption[row]
    }
    
    //MARK: - Reverse Geocoding
    func reverseGeocoding(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        var address = ""
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) -> Void in
            if error != nil{
                print(error as Any)
                return
            } else if (placemarks?.count)! > 0 {
                let pm = placemarks![0].addressDictionary
                let addressLine = pm?["FormattedAddressLines"] as? [String]
                address = (addressLine?.joined(separator: ", "))!
            }
            self.searchBar.text = address
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

extension UIApplication {
    var isKeyboardPresented: Bool {
        if let keyboardWindowClass = NSClassFromString("UIRemoteKeyboardWindow"), self.windows.contains(where: { $0.isKind(of: keyboardWindowClass) }) {
            return true
        } else {
            return false
        }
    }
}
