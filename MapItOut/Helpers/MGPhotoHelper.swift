//
//  MGPhotoHelper.swift
//  MapItOut
//
//  Created by Portia Wang on 6/22/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import UIKit

class MGPhotoHelper: NSObject {
    //MARK: - Properties
    
    
    var view : UIView?
    var completionHandler :((UIImage) -> Void)?
    
    //MARK: - Helper Methods
    
    func presentActionSheet ( from viewController : UIViewController){
        let alertController = UIAlertController(title: nil, message: "Where do you want to get a picture from?", preferredStyle: .actionSheet)
        let defaultImageAction = UIAlertAction(title: "Use default image", style: .default) { (alert) in
            self.completionHandler?(#imageLiteral(resourceName: "noContactImage.png"))
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let capturePhotoAction = UIAlertAction(title: "Take Photo", style: .default, handler: { [unowned self] action in
                self.presentImagePickerController(with: .camera, from: viewController)
            })
            
            alertController.addAction(capturePhotoAction)
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let uploadAction = UIAlertAction(title: "Upload from Library", style: .default, handler: { [unowned self] action in
                self.presentImagePickerController(with: .photoLibrary, from: viewController)
            })
            
            alertController.addAction(uploadAction)
        }
        alertController.addAction(defaultImageAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        
        let popOver = alertController.popoverPresentationController
        popOver?.sourceView  = UIView(frame:CGRect(x: 0, y: 0, width: 40, height: 20))
        popOver?.sourceRect = (popOver?.sourceView?.bounds)!
        popOver?.permittedArrowDirections = UIPopoverArrowDirection.left
        
        viewController.present(alertController, animated: true)
    }
    
    func presentImagePickerController(with sourceType: UIImagePickerControllerSourceType, from viewController: UIViewController) {
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.sourceType = sourceType
        imagePickerController.delegate = self
        viewController.present(imagePickerController, animated: true)
    }
}

extension MGPhotoHelper: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let imagePicked = info[UIImagePickerControllerOriginalImage] as! UIImage
        let imageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 200, height: 200))
        imageView.image = imagePicked
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        let layer: CALayer = imageView.layer
        layer.masksToBounds = true
        layer.cornerRadius = 95
        layer.borderWidth = 0.0
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 0.0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        roundedImage?.draw(in: imageView.bounds)
        UIGraphicsEndImageContext()
        completionHandler?(roundedImage!)
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
