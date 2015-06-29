//
//  ICPhotoAlbumAccess.swift
//  PhotoPicker
//
//  Created by David Schreiber on 6/29/15.
//  Copyright (c) 2015 Metebelis Labs LLC. All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary

private var icAlert : ICAlertView?

func authorizePhotoAlbumAccess(explainerText : String,completion : ((accessGranted : Bool)->()) ) {
    
    // iOS >= 8.0
    if objc_getClass("PHPhotoLibrary") != nil {
        switch PHPhotoLibrary.authorizationStatus() {
        case .NotDetermined:
            PHPhotoLibrary.requestAuthorization({ (authStatus) -> Void in
                completion(accessGranted: (authStatus == .Authorized))
            });
        case .Authorized:
            completion(accessGranted:true)
        case .Denied:
            // In iOS >= 8, you can take the user to their Settings to allow them to 
            // enable permissions
            let newICAlert = ICAlertView(title:"We need your permission",message:"Ingerchat does not have permission to access your photos. " + explainerText + ", you will need to go to the Settings app and give Ingerchat permission.", cancelButtonTitle: "Never Mind", otherButtonTitle: "Go to Settings",callback: { (result) -> () in
                if result == ICAlertViewResult.Other {
                    UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                }
                icAlert = nil
            })
            icAlert = newICAlert
            newICAlert.show()
        case .Restricted:
            UIAlertView(title: nil, message: "You do not have permission to access the photo album.", delegate: nil, cancelButtonTitle: "OK").show()
        }
    } else {
        switch ALAssetsLibrary.authorizationStatus() {
        case .NotDetermined:
            completion(accessGranted: true)  // A clever lie; will cause authorization alert to appear
        case .Authorized:
            completion(accessGranted: true)
        case .Denied:
            UIAlertView(title: "We need your permission", message: "Ingerchat does not have permission to access your photos. " + explainerText + ", you will need to go to the Settings app and give Ingerchat permission.", delegate: nil, cancelButtonTitle: "OK").show()
        case .Restricted:
            UIAlertView(title: nil, message: "You do not have permission to access the photo album.", delegate: nil, cancelButtonTitle: "OK").show()
        }
    }
}