//
//  ICTouchDetectorView.swift
//  ImageEditor
//
//  Created by Metebelis Labs LLC on 6/10/15.
//
//  Copyright 2015 Metebelis Labs LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

// This is a view that sits on top of the image editor's scrollview
// and handles touch events that are intended for the crop box (which
// is defined as touch events that fall on the edge of the crop box,
// plus/minus a margin)

import UIKit

protocol ICTouchDetectorViewDelegate {
    func shouldHandleTouch(sender : ICTouchDetectorView,pointInDetectorView:CGPoint) -> Bool
    func touchBegan(sender : ICTouchDetectorView,pointInDetectorView:CGPoint)
    func touchMoved(sender : ICTouchDetectorView,pointInDetectorView:CGPoint)
    func touchEnded(sender : ICTouchDetectorView,pointInDetectorView:CGPoint)
}

// This is placed on top of the scroll view
// It detects touches, determines if the touch should be 
// handled by the scroll view. If not, it handles the touch.
class ICTouchDetectorView: UIView {
    var touchTrackingInProgress = false
    
    var delegate : ICTouchDetectorViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.userInteractionEnabled = true
        self.backgroundColor = UIColor.clearColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        self.init(frame:CGRectMake(0, 0, 1, 1))
    }
    
    // pointInside() is true if we should be handling this touch, and
    // not really about whether the point is "inside" this
    // view. We let the delegate decide if the touch should be handled
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if touchTrackingInProgress {
            return true
        }
        if let delegate = delegate {
            
            if delegate.shouldHandleTouch(self, pointInDetectorView: point) {
                touchTrackingInProgress = true
                return true
            }
        }
        // Touch will handled by the scroll view
        return false
    }
    
    // If a touch is to be handled, it will be handled by these methods
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        if let touch = touches.first as UITouch! {
            delegate?.touchBegan(self,pointInDetectorView:touch.locationInView(self))
            touchTrackingInProgress = true
        }
    }
    
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        if !touchTrackingInProgress {
            return
        }
        
        for touch in touches {
            delegate?.touchMoved(self,pointInDetectorView:touch.locationInView(self))
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        if !touchTrackingInProgress {
            return
        }
        if let touch = touches.first as UITouch! {
            delegate?.touchEnded(self,pointInDetectorView:touch.locationInView(self))
        }
        touchTrackingInProgress = false
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        if !touchTrackingInProgress {
            return
        }
        if let touch = touches.first as UITouch! {
            delegate?.touchEnded(self,pointInDetectorView:touch.locationInView(self))
        }
        touchTrackingInProgress = false

    }
}
