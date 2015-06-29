//
//  ICAlertView.swift
//  PhotoPicker
//
//  Created by David Schreiber on 6/29/15.
//  Copyright (c) 2015 Metebelis Labs LLC. All rights reserved.
//

import UIKit

// ICAlertView is a wrapper around UIAlertView that takes care of 
// delegation, converting it to a callback
//
// Only caveat: a created ICAlertView instance must be saved in a 
// pointer if you don't want it to go away after you show the alert view

enum ICAlertViewResult
{
    case Cancel
    case Other
}

class ICAlertView : NSObject , UIAlertViewDelegate {
    
    var callback : ((result:ICAlertViewResult) -> ())?
    var alertView : UIAlertView?
    init(title:String,message:String,cancelButtonTitle:String,otherButtonTitle:String? = nil,callback:((result:ICAlertViewResult) -> ())? = nil) {
        
        self.callback = callback
        super.init()
        
        if let otherButtonTitle = otherButtonTitle {
            self.alertView = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelButtonTitle, otherButtonTitles: otherButtonTitle)
        } else {
            self.alertView = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelButtonTitle)
        }
    }
    
    func show() {
        if let alertView = alertView {
            alertView.show()
        }
    }
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if let callback = callback {
            if buttonIndex == 0 {
                callback(result:ICAlertViewResult.Cancel)
            } else {
                callback(result:ICAlertViewResult.Other)
            }
        }
    }
}

