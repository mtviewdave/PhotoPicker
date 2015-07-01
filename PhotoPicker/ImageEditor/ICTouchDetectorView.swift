//
//  ICTouchDetectorView.swift
//  ImageEditor
//
//  Created by Metebelis Labs LLC on 6/10/15.
//  Copyright (c) 2015 Metebelis Labs LLC. All rights reserved.
//

import UIKit

protocol ICTouchDetectorViewDelegate {
    func shouldHandleTouch(sender : ICTouchDetectorView,pointInDetectorView:CGPoint) -> Bool
    func touchBegan(sender : ICTouchDetectorView,pointInDetectorView:CGPoint)
    func touchMoved(sender : ICTouchDetectorView,pointInDetectorView:CGPoint)
    func touchEnded(sender : ICTouchDetectorView,pointInDetectorView:CGPoint)
}

class ICTouchDetectorView: UIView {
    var touchTrackingInProgress = false
    
    var delegate : ICTouchDetectorViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.userInteractionEnabled = true
        self.backgroundColor = UIColor.clearColor()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        self.init(frame:CGRectMake(0, 0, 1, 1))
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if touchTrackingInProgress {
            return true
        }
        let location = convertPoint(point, toView: self.superview)
        if let delegate = delegate {
            
            if delegate.shouldHandleTouch(self, pointInDetectorView: point) {
                touchTrackingInProgress = true
                return true
            }
        }
        return false
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        if let touch = touches.first as? UITouch,let delegate = delegate {
            delegate.touchBegan(self,pointInDetectorView:touch.locationInView(self))
            touchTrackingInProgress = true
        }
    }
    
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        if !touchTrackingInProgress {
            return
        }
        
        for touchObj in touches {
            if let touch = touchObj as? UITouch {
                delegate?.touchMoved(self,pointInDetectorView:touch.locationInView(self))
            }
        }
    }
    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        super.touchesCancelled(touches, withEvent: event)
        if !touchTrackingInProgress {
            return
        }
        if let touch = touches.first as? UITouch {
            delegate?.touchEnded(self,pointInDetectorView:touch.locationInView(self))
        }
        touchTrackingInProgress = false
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        if !touchTrackingInProgress {
            return
        }
        if let touch = touches.first as? UITouch {
            delegate?.touchEnded(self,pointInDetectorView:touch.locationInView(self))
        }
        touchTrackingInProgress = false

    }
}
