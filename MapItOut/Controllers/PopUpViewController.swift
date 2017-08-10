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
import CoreTelephony

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
    
    var isChanged = false
    
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
    var url = ""
    var OUrl = ""
    
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
    var pickOption = ["Family", "Food", "Friend"]
    
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
        if self.searchBar.text != ""{
            self.originalLocation = self.searchBar.text!
        }
        self.searchBar.text = ""
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text == ""{
            self.resultTableView.isHidden = true
            searchBar.text = self.originalLocation
            self.contactMapView.removeAnnotations(self.contactMapView.annotations)
            let anno = MKPointAnnotation()
            anno.coordinate.latitude = self.latitude
            anno.coordinate.longitude = self.longitude
            self.contactMapView.addAnnotation(anno)
            let coordinate = CLLocationCoordinate2DMake(self.latitude, self.longitude)
            let span = MKCoordinateSpanMake(0.1, 0.1)
            let region = MKCoordinateRegionMake(coordinate, span)
            self.contactMapView.setRegion(region, animated: true)
            self.location = coordinate
        }
        if self.searchResults.count == 0{
            self.searchBar.text = self.originalLocation
            self.resultTableView.isHidden = true
        } else {
            self.searchBar.text = self.searchResults[0].title + " " + self.searchResults[0].subtitle
            self.resultTableView.isHidden = true
            
            let searchRequest = MKLocalSearchRequest(completion: self.searchResults[0])
            let search = MKLocalSearch(request: searchRequest)
            search.start { (response, error) in
                let coordinate = response?.mapItems[0].placemark.coordinate
                self.contactMapView.removeAnnotations(self.contactMapView.annotations)
                let anno = MKPointAnnotation()
                anno.coordinate = CLLocationCoordinate2DMake((coordinate?.latitude)!, (coordinate?.longitude)!)
                let span = MKCoordinateSpanMake(0.1, 0.1)
                self.location = coordinate!
                let region = MKCoordinateRegion(center: anno.coordinate, span: span)
                self.contactMapView.setRegion(region, animated: true)
                self.contactMapView.addAnnotation(anno)
                self.longitude = anno.coordinate.longitude
                self.latitude = anno.coordinate.latitude
                self.originalLocation = self.searchBar.text!
            }
            
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
        self.resultTableView.isHidden = true
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
            var coordinate = response?.mapItems[0].placemark.coordinate
            //let calibratedCoordinate = LocationTransformHelper.wgs2gcj(wgsLat: (coordinate?.latitude)!, wgsLng: (coordinate?.longitude)!)
            coordinate?.longitude = (coordinate?.longitude)!
            coordinate?.latitude = (coordinate?.latitude)!
            self.contactMapView.removeAnnotations(self.contactMapView.annotations)
            let anno = MKPointAnnotation()
            anno.coordinate = coordinate!
            let span = MKCoordinateSpanMake(0.1, 0.1)
            self.location = coordinate!
            let region = MKCoordinateRegion(center: anno.coordinate, span: span)
            self.contactMapView.setRegion(region, animated: true)
            self.contactMapView.addAnnotation(anno)
            self.longitude = (coordinate?.longitude)!
            self.latitude = (coordinate?.latitude)!
            self.resultTableView.isHidden = true
            
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
        let addTypeButton = UIBarButtonItem(title: "Add category", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PopUpViewController.addtype))
        
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
        
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.0)
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
        
        if self.parent is ContactListController{
            let parent = self.parent as! ContactListController
            parent.backgroundView.isHidden = false
        } else {
            let parent = self.parent as! MainViewController
            parent.backgroundView.isHidden = false
        }
        
        
        pickOption = ["Family", "Food", "Friend"]
        for item in CoreDataHelper.retrieveItems(){
            var i = 0
            var isPresent = false
            while i < pickOption.count{
                if (pickOption[i] == item.type){
                    isPresent = true
                }
                i += 1
            }
            if isPresent == false{
                self.pickOption.append(item.type!)
            }
        }
        var i = 0
        while i < pickOption.count{
            if (pickOption[i] != typeTextField.text!) && (i == pickOption.count-1){
                self.pickOption.append(typeTextField.text!)
                break
            }
            i += 1
        }
        
        if let phoneCallURL:URL = URL(string: "tel:111") {
            let application:UIApplication = UIApplication.shared
            if !(application.canOpenURL(phoneCallURL)) {
            self.phoneButton.isHidden = true
            self.phoneImageView.isHidden = true
            }
        }
        
        if let emailURL:URL = URL(string: "mailto:qingfeng1230@gmail.com") {
            let application:UIApplication = UIApplication.shared
            if !(application.canOpenURL(emailURL)) {
                self.emailButton.isHidden = true
                self.emailImageView.isHidden = true
            }
        }
        
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.startTimer), userInfo: nil, repeats: true)
        
        self.resultTableView.isHidden = true
        self.undoButton.setTitleColor(UIColor.clear, for: .normal)
        self.undoButton.layer.cornerRadius = 30
        self.itemImage.layer.cornerRadius = 70
        self.changeImageButton.layer.cornerRadius = 70
        self.itemImage.clipsToBounds = true
        contactMapView.isUserInteractionEnabled = true
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
        self.view.isUserInteractionEnabled = true
        self.dismissButton.isEnabled = true
        
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
        
        if isChanged{
            self.undoButton.isEnabled = true
            self.undoButton.setTitleColor(UIColor.white, for: .normal)
        } else {
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
        self.OUrl = self.url
        }
        
        self.view.endEditing(true)
    }
    
    
    
    
    //MARK: - VC Functions
    
    @IBAction func dimissButtonTapped(_ sender: Any) {
        self.dismissButton.isEnabled = false
        self.view.isUserInteractionEnabled = false
        dismissView()
    }
    @IBAction func undoButtonTapped(_ sender: Any) {
        self.isChanged = false
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
        
        if self.OPhone == ""{
            self.phoneButton.isHidden = true
            self.phoneImageView.isHidden = true
        } else {
            self.phoneButton.isHidden = false
            self.phoneImageView.isHidden = false
        }
        if self.OEmail == ""{
            self.emailButton.isHidden = true
            self.emailImageView.isHidden = true
        } else {
            self.emailButton.isHidden = false
            self.emailImageView.isHidden = false
        }
        
        
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
        controller.dismiss(animated: true) {
        }
    }
    
    @IBAction func phoneButtonTapped(_ sender: Any) {
        var string = phoneTextField.text?.replacingOccurrences(of: "(", with: "")
        string = string?.replacingOccurrences(of: ")", with: "")
        string = string?.replacingOccurrences(of: "-", with: "")
        string = string?.components(separatedBy: .whitespacesAndNewlines).joined()
        if let phoneCallURL:URL = URL(string: "tel:\(string!))") {
            let application:UIApplication = UIApplication.shared
            if (application.canOpenURL(phoneCallURL)) {
                    application.open(phoneCallURL, options: [:], completionHandler: nil)
            }
        } else {
            let alert = UIAlertController(title: "An error occurred", message: nil, preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: {
            })
        }
    }
    
    @IBAction func emailButtonTapped(_ sender: Any) {
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        composeVC.setToRecipients([self.emailTextField.text!])
        composeVC.setMessageBody("Hey \(self.nameTextField.text!)", isHTML: false)
        self.present(composeVC, animated: true, completion: nil)
        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        
        CoreDataHelper.deleteItems(item: self.item)
        
        if defaults.string(forKey: "isLoggedIn") == "true"{
            let imageRef = Storage.storage().reference().child("images/items/\(User.currentUser.uid)/\(self.keyOfItem).jpg")
            imageRef.delete(completion: { (error) in
                ItemService.deleteEntry(key: self.keyOfItem)
                UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                    self.parent?.viewWillAppear(true)
                    self.parent?.viewDidAppear(true)
                    self.view.removeFromSuperview()
                }, completion: nil)
            })
        } else {
            UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                self.parent?.viewWillAppear(true)
                self.parent?.viewDidAppear(true)
                self.view.removeFromSuperview()
            }, completion: nil)
        }
        
    }
    
    @IBAction func changeImageButton(_ sender: Any) {
        photoHelper.presentActionSheet(from: self)
        
        photoHelper.completionHandler = { image in
            self.itemImage.image = image
            self.item.image = image
            self.isPhotoUpdated = true
            self.contactPhoto = image
            self.undoButton.isEnabled = true
            self.undoButton.setTitleColor(.white, for: .normal)
        }
    }
    
    func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    func dismissView(){
        if (UIApplication.shared.isKeyboardPresented)||(self.resultTableView.isHidden == false){
            self.view.endEditing(true)
            self.typeTextField.resignFirstResponder()
            self.dismissKeyboard()
            if (self.searchBar.text == "") || (self.resultTableView.isHidden == false){
                self.searchBar.text = OOriginalLocation
                self.resultTableView.isHidden = true
            }
            if (phoneTextField.text! != OPhone) || (emailTextField.text! != OEmail) || (organizationTextField.text! != OOrganization) || (nameTextField.text! != OName) || (typeTextField.text! != OType) || ( searchBar.text != OOriginalLocation){
                self.undoButton.isEnabled = true
                self.undoButton.setTitleColor(UIColor.white, for: .normal)
            } else {
                self.undoButton.isEnabled = false
                self.undoButton.setTitleColor(UIColor.clear, for: .normal)
            }
            self.dismissButton.isEnabled = true
            self.view.isUserInteractionEnabled = true
            
            searchBarCancelButtonClicked(searchBar)
        } else {
            self.isChanged = false
            self.isPhotoUpdated = false
            if self.undoButton.isEnabled == true {
                self.undoButton.isEnabled = false
                self.undoButton.setTitleColor(.clear, for: .normal)
                self.dismissButton.isEnabled = false
                self.view.isUserInteractionEnabled = false
                if self.parent is MainViewController{
                    
                    let parent = self.parent as! MainViewController
                    CoreDataHelper.deleteItems(item: self.item)
                    if defaults.string(forKey: "isLoggedIn") == "true"{
                        if self.OContactPhoto != self.itemImage.image{
                            let imageRef = Storage.storage().reference().child("images/items/\(User.currentUser.uid)/\(self.keyOfItem).jpg")
                            imageRef.delete(completion: nil)
                            let newImageRef = StorageReference.newContactImageReference(key: self.keyOfItem)
                            
                            StorageService.uploadHighImage(itemImage.image!, at: newImageRef) { (downloadURL) in
                                guard let downloadURL = downloadURL else {
                                    return
                                }
                                let urlString = downloadURL.absoluteString
                                self.url = downloadURL.absoluteString
                                let entry = Entry(name: self.nameTextField.text!, organization: self.organizationTextField.text!, longitude: self.longitude, latitude: self.latitude, type: self.typeTextField.text!, imageURL: urlString, phone: self.phoneTextField.text!, email: self.emailTextField.text!, key: self.keyOfItem, locationDescription: self.searchBar.text!, contactKey: self.item.contactKey!)
                                
                                ItemService.editEntry(entry: entry)
                                
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
                                item.url = urlString
                                
                                CoreDataHelper.saveItem()
                                parent.updateValue(item: item)
                                
                                if self.view.superview != nil{
                                    parent.backgroundView.isHidden = true
                                    parent.view.isUserInteractionEnabled = true
                                    UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
                                        self.view.frame.origin.y = self.view.frame.height
                                    }, completion: { (bool) -> Void in
                                        self.view.removeFromSuperview()
                                        self.dismissButton.isEnabled = true
                                        self.view.isUserInteractionEnabled = true
                                    })
                                }
                            }
                        } else {
                            let entry = Entry(name: self.nameTextField.text!, organization: self.organizationTextField.text!, longitude: self.longitude, latitude: self.latitude, type: self.typeTextField.text!, imageURL: self.OUrl, phone: self.phoneTextField.text!, email: self.emailTextField.text!, key: self.keyOfItem, locationDescription: self.searchBar.text!, contactKey: self.item.contactKey!)
                            ItemService.editEntry(entry: entry)
                            
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
                            item.url = self.OUrl
                            
                            CoreDataHelper.saveItem()
                            parent.updateValue(item: item)
                            
                            if self.view.superview != nil{
                                parent.backgroundView.isHidden = true
                                parent.view.isUserInteractionEnabled = true
                                
                                UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
                                    self.view.frame.origin.y = self.view.frame.height
                                }, completion: { (bool) -> Void in
                                    self.view.removeFromSuperview()
                                    self.dismissButton.isEnabled = true
                                    self.view.isUserInteractionEnabled = true
                                })
                            }
                        }
                    } else {
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
                        item.url = ""
                        
                        CoreDataHelper.saveItem()
                        parent.updateValue(item: item)
                        
                        if self.view.superview != nil{
                            parent.backgroundView.isHidden = true
                            parent.view.isUserInteractionEnabled = true
                            
                            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
                                self.view.frame.origin.y = self.view.frame.height
                            }, completion: { (bool) -> Void in
                                parent.view.isUserInteractionEnabled = true
                                self.view.removeFromSuperview()
                                self.dismissButton.isEnabled = true
                                self.view.isUserInteractionEnabled = true
                            })
                        }

                    }
                    
                } else {
                    let parent = self.parent as! ContactListController
                    CoreDataHelper.deleteItems(item: self.item)
                    if defaults.string(forKey: "isLoggedIn") == "true"{
                        if self.OContactPhoto != self.itemImage.image{
                            let imageRef = Storage.storage().reference().child("images/items/\(User.currentUser.uid)/\(self.keyOfItem).jpg")
                            imageRef.delete(completion: nil)
                            let newImageRef = StorageReference.newContactImageReference(key: self.keyOfItem)
                            
                            StorageService.uploadHighImage(itemImage.image!, at: newImageRef) { (downloadURL) in
                                guard let downloadURL = downloadURL else {
                                    return
                                }
                                let urlString = downloadURL.absoluteString
                                self.url = downloadURL.absoluteString
                                let entry = Entry(name: self.nameTextField.text!, organization: self.organizationTextField.text!, longitude: self.longitude, latitude: self.latitude, type: self.typeTextField.text!, imageURL: urlString, phone: self.phoneTextField.text!, email: self.emailTextField.text!, key: self.keyOfItem, locationDescription: self.searchBar.text!, contactKey: self.item.contactKey!)
                                ItemService.editEntry(entry: entry)
                                
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
                                item.url = urlString
                                
                                CoreDataHelper.saveItem()
                                parent.updateValue(item: item)
                                parent.backgroundView.isHidden = true
                                if self.view.superview != nil{
                                    UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                                        self.view.removeFromSuperview()
                                        self.dismissButton.isEnabled = true
                                        self.view.isUserInteractionEnabled = true
                                    }, completion: nil)
                                }
                            }
                        } else {
                            let entry = Entry(name: self.nameTextField.text!, organization: self.organizationTextField.text!, longitude: self.longitude, latitude: self.latitude, type: self.typeTextField.text!, imageURL: self.OUrl, phone: self.phoneTextField.text!, email: self.emailTextField.text!, key: self.keyOfItem, locationDescription: self.searchBar.text!, contactKey: self.item.contactKey!)
                            ItemService.editEntry(entry: entry)
                            
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
                            item.url = OUrl
                            
                            CoreDataHelper.saveItem()
                            parent.updateValue(item: item)
                            parent.backgroundView.isHidden = true
                            if self.view.superview != nil{
                                UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                                    self.view.removeFromSuperview()
                                    self.dismissButton.isEnabled = true
                                    self.view.isUserInteractionEnabled = true
                                }, completion: nil)
                            }
                        }
                    } else {
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
                        item.url = ""
                        
                        CoreDataHelper.saveItem()
                        parent.updateValue(item: item)
                        parent.backgroundView.isHidden = true
                        if self.parent is MainViewController {
                            self.dismissButton.isEnabled = true
                            if self.view.superview != nil{
                                UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
                                    self.view.frame.origin.y = self.view.frame.height
                                }, completion: { (bool) -> Void in
                                    self.view.removeFromSuperview()
                                    self.dismissButton.isEnabled = true
                                    self.view.isUserInteractionEnabled = true
                                })
                            }
                        } else {
                            self.dismissButton.isEnabled = true
                            if self.view.superview != nil{
                                UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                                    self.view.removeFromSuperview()
                                    self.dismissButton.isEnabled = true
                                    self.view.isUserInteractionEnabled = true
                                }, completion: nil)
                            }
                        }
                        
                    }
                }
            } else {
                if self.parent is MainViewController {
                self.item.url = OUrl
                CoreDataHelper.saveItem()
                self.dismissButton.isEnabled = true
                let parent = self.parent as! MainViewController
                parent.view.isUserInteractionEnabled = true
                parent.backgroundView.isHidden = true
                if self.view.superview != nil{
                    UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
                        self.view.frame.origin.y = self.view.frame.height
                    }, completion: { (bool) -> Void in
                        self.view.removeFromSuperview()
                        self.dismissButton.isEnabled = true
                        self.view.isUserInteractionEnabled = true
                    })
                }
                } else {
                    self.item.url = OUrl
                    CoreDataHelper.saveItem()
                    self.dismissButton.isEnabled = true
                    let parent = self.parent as! ContactListController
                    parent.view.isUserInteractionEnabled = true
                    parent.backgroundView.isHidden = true
                    if self.view.superview != nil{
                        UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
                            parent.backgroundView.isHidden = true
                            self.view.removeFromSuperview()
                            self.dismissButton.isEnabled = true
                            self.view.isUserInteractionEnabled = true
                        }, completion: nil)
                    }
                    
                }
            }
        }
        if (phoneTextField.text! != OPhone) || (emailTextField.text! != OEmail) || (organizationTextField.text! != OOrganization) || (nameTextField.text! != OName) || (typeTextField.text! != OType) || ( searchBar.text != OOriginalLocation){
            self.undoButton.isEnabled = true
            self.undoButton.setTitleColor(UIColor.white, for: .normal)
        } else {
            self.undoButton.isEnabled = false
            self.undoButton.setTitleColor(UIColor.clear, for: .normal)
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
        self.view.isUserInteractionEnabled = true
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
            
            self.name = self.nameTextField.text!
            self.organization = self.organizationTextField.text!
            self.type = self.typeTextField.text!
            self.address = self.searchBar.text!
            self.phone = self.phoneTextField.text!
            self.email = self.emailTextField.text!
            self.isChanged = true
            
            if let phoneCallURL:URL = URL(string: "tel:111") {
                let application:UIApplication = UIApplication.shared
                if !(application.canOpenURL(phoneCallURL)) {
                    self.phoneButton.isHidden = true
                    self.phoneImageView.isHidden = true
                } else {
                    if self.phoneTextField.text != "" {
                        self.phoneButton.isHidden = false
                        self.phoneImageView.isHidden = false
                    }
                }
            }
            
            if let emailURL:URL = URL(string: "mailto:qingfeng1230@gmail.com") {
                let application:UIApplication = UIApplication.shared
                if !(application.canOpenURL(emailURL)) {
                    self.emailButton.isHidden = true
                    self.emailImageView.isHidden = true
                } else {
                    if self.emailTextField.text != "" {
                        self.emailButton.isHidden = false
                        self.emailImageView.isHidden = false
                    }
                }
            }
            
        } else {
            if (textField.text == OPhone) || (textField.text == OEmail) || (textField.text == OName) || (textField.text == OType){
                self.undoButton.isEnabled = false
                self.undoButton.setTitleColor(UIColor.clear, for: .normal)
            }
        }
        self.dismissButton.isEnabled = true
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
        self.type = pickOption[row]
        
        if defaults.string(forKey: "type") != self.type{
            var count = defaults.string(forKey: "count")
            count = count?.replacingOccurrences(of: "(", with: "")
            count = count?.replacingOccurrences(of: ")", with: "")
            let number = Int(count!)
            defaults.set("(" + String(describing: number! - 1) + ")", forKey: "count")
        }
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
