//
//  ICCropBoxView.swift
//  ImageEditor
//
//  Created by Metebelis Labs LLC on 6/10/15.
//  Copyright (c) 2015 Metebelis Labs LLC. All rights reserved.
//

import UIKit

let ICCropBoxViewMargin = CGFloat(3)

class ICCropBoxView: UIView {
    
    let margin = ICCropBoxViewMargin
    let handlesSize = CGFloat(18)
    var showInteriorLines = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setNeedsDisplay()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(showInteriorLines : Bool) {
        self.init(frame:CGRectMake(0, 0, 0,0))
        self.showInteriorLines = showInteriorLines
        self.backgroundColor = UIColor.clearColor()
        self.userInteractionEnabled = false
        self.setNeedsDisplay()
    }

    override func drawRect(rect: CGRect) {
        //super.drawRect(rect)
        
        let path = CGPathCreateMutable()
        let width = self.bounds.width
        let interiorWidth = width - 2*margin
        let height = self.bounds.height
        let interiorHeight = height - 2*margin
        let context = UIGraphicsGetCurrentContext()

        CGContextSetLineWidth(context, 0.5)
        CGContextMoveToPoint(context, margin, margin)
        CGContextAddLineToPoint(context, width-margin, margin)
        CGContextAddLineToPoint(context, width-margin, height-margin)
        CGContextAddLineToPoint(context, margin, height-margin)
        CGContextAddLineToPoint(context, margin, margin)

        if showInteriorLines {
            CGContextMoveToPoint(context, margin+interiorWidth/3, margin)
            CGContextAddLineToPoint(context, margin+interiorWidth/3, interiorHeight+margin)

            CGContextMoveToPoint(context, margin+2*interiorWidth/3, margin)
            CGContextAddLineToPoint(context, margin+2*interiorWidth/3, interiorHeight+margin)

            CGContextMoveToPoint(context, margin, margin+interiorHeight/3)
            CGContextAddLineToPoint(context, margin+interiorWidth, margin+interiorHeight/3)
            
            CGContextMoveToPoint(context, margin, margin+2*interiorHeight/3)
            CGContextAddLineToPoint(context, margin+interiorWidth, margin+2*interiorHeight/3)
            

        }
        CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextStrokePath(context)
        
        CGContextSetLineWidth(context, 0)
        CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)

        // Handles on the corners
        
        // Top-left
        CGContextFillRect(context, CGRectMake(0, 0, margin, handlesSize)) // Down
        CGContextFillRect(context, CGRectMake(0, 0, handlesSize, margin)) // Across

        // Top-right
        CGContextFillRect(context, CGRectMake(width-margin, 0, margin, handlesSize))  // Down
        CGContextFillRect(context, CGRectMake(width-handlesSize, 0, handlesSize, margin)) // Across
        
        // Bottom-right
        CGContextFillRect(context, CGRectMake(width-margin, height-handlesSize, margin, handlesSize))  // Down
        CGContextFillRect(context, CGRectMake(width-handlesSize, height-margin, handlesSize, margin)) // Across
        
        // Bottom-left
        CGContextFillRect(context, CGRectMake(0, height-handlesSize, margin, handlesSize))  // Down
        CGContextFillRect(context, CGRectMake(0, height-margin, handlesSize, margin)) // Across
        
        
    }
    
}
