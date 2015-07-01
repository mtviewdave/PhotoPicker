//
//  ViewController.swift
//  PhotoPicker
//
//  Created by Metebelis Labs LLC on 6/29/15.
//  Copyright (c) 2015 Metebelis Labs LLC. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate,ICImageEditViewControllerDelegate {
    var imageView : UIImageView = UIImageView()
    var imagePicker : UIImagePickerController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(imageView)
        self.view.backgroundColor = UIColor.darkGrayColor()
    }

    @IBAction func choosePhotoButtonTapped() {
        authorizePhotoAlbumAccess("If you would you like to send a photo") { (accessGranted) -> () in
            if accessGranted {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .PhotoLibrary
                imagePicker.mediaTypes = [kUTTypeImage]
                self.presentViewController(imagePicker, animated: true, completion: nil)
                self.imagePicker = imagePicker
            }
        }
    }
    
    // UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        if let chosenImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let imageEditor = ICImageEditViewController(imageToEdit:chosenImage)
            imageEditor.delegate = self
            picker.presentViewController(imageEditor, animated: true, completion: nil)
        } else {
            picker.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // ICImageEditViewControllerDelegate
    func imageEditorDidCancel(sender: ICImageEditViewController) {
        sender.dismissViewControllerAnimated(true, completion: nil)
        sender.delegate = nil
    }
    
    // Image editor finished successfully. Size the image view
    // to display it
    func imageEditorDidEdit(sender: ICImageEditViewController, image: UIImage) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
        let screenSize = self.view.bounds.size
        
        let maxImageWidth = screenSize.width * 0.9
        let maxImageHeight = screenSize.height * 0.5
        
        let imageWidth : CGFloat
        let imageHeight : CGFloat
        if image.size.width/image.size.height > maxImageWidth/maxImageHeight {
            imageWidth = maxImageWidth
            imageHeight = (image.size.height / image.size.width) * maxImageWidth
        } else {
            imageHeight = maxImageHeight
            imageWidth = (image.size.width / image.size.height) * maxImageHeight
        }
        
        self.imageView.frame = CGRectMake((screenSize.width - imageWidth)/2, 50, imageWidth, imageHeight)
        self.imageView.image = image
        sender.delegate = nil
    }
    
}

