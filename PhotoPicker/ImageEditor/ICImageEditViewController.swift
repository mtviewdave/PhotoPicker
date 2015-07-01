//
//  ICImageEditViewController.swift
//  ImageEditor
//
//  Created by Metebelis Labs LLC on 6/9/15.
//  Copyright (c) 2015 Metebelis Labs LLC. All rights reserved.
//

import UIKit

protocol ICImageEditViewControllerDelegate {
    func imageEditorDidEdit(sender : ICImageEditViewController,image : UIImage)
    func imageEditorDidCancel(sender : ICImageEditViewController)
}


class ICImageEditViewController: UIViewController,UIScrollViewDelegate,ICTouchDetectorViewDelegate {
    var delegate : ICImageEditViewControllerDelegate?

    @IBOutlet var scrollView : UIScrollView!;
    var touchDetectorView = ICTouchDetectorView()
    @IBOutlet var bottomContainerView : UIView!
    
    @IBOutlet var cancelButton : UIButton!
    @IBOutlet var useButton : UIButton!
    @IBOutlet var doneButton : UIButton!
    @IBOutlet var editButton : UIButton!
    @IBOutlet var rotateButton : UIButton!
    @IBOutlet var resetButton : UIButton!
    
    var inEditMode = false

    var imageView = UIImageView()
    
    var croppedImage : UIImage
    var croppedImageView = UIImageView()
    var minZoomScale = CGFloat(1)
    
   // let testImage2 : UIImage = UIImage(named: "IMG_3821.jpg")!
    let originalImage : UIImage
    var currentImage : UIImage // rotated version of currentImage
    
    var maxCropRectForScreen = CGRect()
    var currentMaxCropRect = CGRect()

    let margin = CGFloat(0)
    
    let sideMargins = CGFloat(10)
    let topMargin = CGFloat(10)
    
    var cropView = UIView()
    
    var cropBoxOverlay = ICCropBoxView(showInteriorLines: false)
    var cropBoxOverlayWithLines = ICCropBoxView(showInteriorLines: true)
    var cropFrame = CGRect()
    
    // Used for metrics tracking
    var imageWasCropped = false
    var imageWasRotated = false
    var imageWasEdited = false
    var canceledOutOfEditing = false
    
    init(imageToEdit : UIImage) {
        
        // Do this "rotation" to strip out the orientation information from the image
        UIGraphicsBeginImageContextWithOptions(imageToEdit.size, false, 1)
        imageToEdit.drawAtPoint(CGPointMake(0, 0))
        originalImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        currentImage = originalImage
        croppedImage = currentImage
        super.init(nibName: "ICImageEditViewController", bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoder not supported")
    }
    
    
    var sizerRatio = CGFloat(0)
    let fadeTransitionTime = NSTimeInterval(0.1)
    let moveTransitionTime = NSTimeInterval(0.2)
    
    var prevMinZoom = CGFloat(0)
    var prevZoomScale = CGFloat(0)
    var prevContentOffset = CGPointMake(0, 0)
    var prevRotation : Int = 0
    var prevCropFrame = CGRectMake(0, 0, 0, 0)
    var prevMaxCropRect = CGRectMake(0, 0, 0, 0)
    func switchToEditMode() {
        if inEditMode {
            return
        }
        inEditMode = true
        prevMinZoom = minZoomScale
        prevZoomScale = scrollView.zoomScale
        prevContentOffset = scrollView.contentOffset
        prevRotation = currentRotationInDegrees
        prevCropFrame = cropFrame
        prevMaxCropRect = currentMaxCropRect
        
        self.doneButton.hidden = false
        self.rotateButton.hidden = false
        self.resetButton.hidden = false
        self.imageView.hidden = false
        self.scrollView.hidden = false
        self.scrollView.scrollEnabled = true
        // This enables zooming
        self.scrollView.minimumZoomScale = minZoomScale
        self.scrollView.maximumZoomScale = 1.0
        
        UIView.animateWithDuration(0.1, delay: 0, options: .AllowUserInteraction | .CurveEaseInOut, animations: { () -> Void in
            self.croppedImageView.frame = self.cropFrame
        }) { (done) -> Void in
            UIView.animateWithDuration(self.fadeTransitionTime, delay: 0, options: .AllowUserInteraction, animations: { () -> Void in
                self.doneButton.alpha = 1
                self.rotateButton.alpha = 1
                self.resetButton.alpha = 1
                self.useButton.alpha = 0
                self.editButton.alpha = 0
                self.cropBoxOverlay.alpha = 1
                self.scrollView.alpha = 1
            }) { (done) -> Void in
                self.useButton.hidden = true
                self.editButton.hidden = true
                self.croppedImageView.hidden = true
            }
        }
    }
    
    func switchOutOfEditMode(animated : Bool) {
        if !inEditMode {
            return
        }
        inEditMode = false
        
        let croppedImageViewFrame = croppedImageView.frame
        var centeredCroppedImageViewFrame = croppedImageViewFrame
        centeredCroppedImageViewFrame.origin.x = maxCropRectForScreen.origin.x+(maxCropRectForScreen.size.width-croppedImageViewFrame.size.width)/2.0
        centeredCroppedImageViewFrame.origin.y = maxCropRectForScreen.origin.y+(maxCropRectForScreen.size.height-croppedImageViewFrame.size.height)/2.0

        /*
        self.scrollView.scrollEnabled = false
        // This disables zooming
        self.scrollView.minimumZoomScale = scrollView.zoomScale
        self.scrollView.maximumZoomScale = scrollView.zoomScale
*/
        
        self.useButton.hidden = false
        self.editButton.hidden = false
        self.croppedImageView.hidden = false
        
        if !animated {
            self.doneButton.alpha = 0
            self.rotateButton.alpha = 0
            self.resetButton.alpha = 0
            self.useButton.alpha = 1
            self.editButton.alpha = 1
            self.cropBoxOverlay.alpha = 0
            self.cropBoxOverlayWithLines.alpha = 0
            self.scrollView.alpha = 0
            self.doneButton.hidden = true
            self.rotateButton.hidden = true
            self.resetButton.hidden = true
            self.imageView.hidden = true
            self.scrollView.hidden = true
            self.croppedImageView.frame = centeredCroppedImageViewFrame
            return
        }
        
        UIView.animateWithDuration(fadeTransitionTime, delay: 0, options: .AllowUserInteraction, animations: { () -> Void in
            self.doneButton.alpha = 0
            self.rotateButton.alpha = 0
            self.resetButton.alpha = 0
            self.useButton.alpha = 1
            self.editButton.alpha = 1
            self.cropBoxOverlay.alpha = 0
            self.cropBoxOverlayWithLines.alpha = 0
            self.scrollView.alpha = 0

            }) { (done) -> Void in
                self.doneButton.hidden = true
                self.rotateButton.hidden = true
                self.resetButton.hidden = true
                self.imageView.hidden = true
                self.scrollView.hidden = true
                UIView.animateWithDuration(self.moveTransitionTime, delay: 0, options: .AllowUserInteraction | .CurveEaseInOut, animations: { () -> Void in
                    self.croppedImageView.frame = centeredCroppedImageViewFrame
                    }) { (done) -> Void in
                }
            }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cropBoxOverlay.alpha = 0
        self.cropBoxOverlayWithLines.alpha = 0
        self.view.addSubview(croppedImageView)
        croppedImageView.hidden = true
        
        let screenBounds = UIScreen.mainScreen().bounds
        maxCropRectForScreen = CGRectMake(sideMargins, topMargin, screenBounds.width-2*sideMargins, screenBounds.height - bottomContainerView.frame.height-2*topMargin)
        sizerRatio = maxCropRectForScreen.height/maxCropRectForScreen.width
        
        scrollView.addSubview(imageView)

        setup(true)
        
        self.view.addSubview(cropBoxOverlay)
        self.view.addSubview(cropBoxOverlayWithLines)
        cropBoxOverlayWithLines.hidden = true
        
        self.view.addSubview(touchDetectorView)
        scrollView.scrollEnabled = false
        
        return
    }
    
    func updateCropBox(frame : CGRect) {
        cropFrame = frame
        var cropBoxOverlayFrame = cropFrame
        cropBoxOverlayFrame.origin.x -= ICCropBoxViewMargin
        cropBoxOverlayFrame.origin.y -= ICCropBoxViewMargin
        cropBoxOverlayFrame.size.width += 2*ICCropBoxViewMargin
        cropBoxOverlayFrame.size.height += 2*ICCropBoxViewMargin
        cropBoxOverlay.frame = cropBoxOverlayFrame
        cropBoxOverlayWithLines.frame = cropBoxOverlayFrame
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        touchDetectorView.frame = self.view.bounds
        touchDetectorView.delegate = self
        computeVisibleRect()
        updateCropBox(currentMaxCropRect)
        cropBoxOverlay.setNeedsDisplay()
        cropBoxOverlayWithLines.setNeedsDisplay()
    }
    
    func computeCrop() {
        var frame = self.view.convertRect(cropFrame, toView: imageView)
        
        let imageRef = CGImageCreateWithImageInRect(currentImage.CGImage, frame)
        croppedImage = UIImage(CGImage: imageRef)!
        
        croppedImageView.frame = cropFrame
        croppedImageView.image = croppedImage
        croppedImageView.hidden = false
    }
    
    func rectString(rect : CGRect) -> String {
        return String(format: "(%g,%g,%g,%g)",arguments:[rect.origin.x,rect.origin.y,rect.size.width,rect.size.height])
    }
    
    func computeVisibleRect() {
        var visibleRect = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
        let visibleRect2 = scrollView.convertRect(scrollView.bounds, toView: self.view)

        let scale = 1.0 / scrollView.zoomScale
        visibleRect.origin.x *= scale
        visibleRect.origin.y *= scale
        visibleRect.size.width *= scale
        visibleRect.size.height *= scale
    
        visibleRect.size.width = min(visibleRect.size.width,currentImage.size.width)
        visibleRect.size.height = min(visibleRect.size.height,currentImage.size.height  )
        
        let imageViewInParent = imageView.convertRect(imageView.bounds, toView: self.view)
 
        currentMaxCropRect = CGRectIntersection(imageViewInParent, maxCropRectForScreen)

        cropView.frame = currentMaxCropRect
    }
    
    func setup(firstTime : Bool) {
        let oldScale = scrollView.zoomScale
        let oldMinScale = scrollView.minimumZoomScale
        var containerWidth = CGFloat(0)
        var containerHeight =  CGFloat(0)
        if(maxCropRectForScreen.width/maxCropRectForScreen.height < currentImage.size.width / currentImage.size.height) {
            containerWidth = currentImage.size.width*1.1
            containerHeight = containerWidth*(maxCropRectForScreen.height/maxCropRectForScreen.width)
        } else {
            containerHeight = currentImage.size.height*1.1
            containerWidth = containerHeight*(maxCropRectForScreen.width/maxCropRectForScreen.height)
        }
        
        var frame = CGRectMake((containerWidth-currentImage.size.width)/2.0,(containerHeight-currentImage.size.height)/2.0,currentImage.size.width,currentImage.size.height)
     
        imageView.removeFromSuperview()
        imageView = UIImageView(frame: CGRectMake(0, 0, currentImage.size.width, currentImage.size.height))
        imageView.image = currentImage
        scrollView.addSubview(imageView)
        let screenBounds = UIScreen.mainScreen().bounds
        minZoomScale = min(screenBounds.width/containerWidth,screenBounds.height/containerHeight)

        let leftInset = minZoomScale * (containerWidth-currentImage.size.width)/2.0
        
        scrollView.contentInset = UIEdgeInsetsMake(
            minZoomScale*(containerHeight-currentImage.size.height)/2.0,
            minZoomScale*(containerWidth-currentImage.size.width)/2.0,
            minZoomScale*(containerHeight-currentImage.size.height)/2.0 + bottomContainerView.bounds.height ,
            minZoomScale*(containerWidth-currentImage.size.width)/2.0)


        let imageSize = currentImage.size

        //let newZoomScale = firstTime ? minZoomScale: (oldScale/oldMinScale)*minZoomScale
        let newZoomScale = minZoomScale
        // Set up the zoom scale, but disabled zooming until the user enters edit mode
        scrollView.minimumZoomScale = newZoomScale
        scrollView.maximumZoomScale = newZoomScale
        scrollView.zoomScale = newZoomScale

        NSLog("Minscale: %f",minZoomScale)
    }
   
    func scrollViewDidZoom(scrollView: UIScrollView) {
        computeVisibleRect()
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        computeVisibleRect()
    }
    
    func rotateImage(origImage : UIImage,rotationInRadians : CGFloat) -> UIImage {
        let origSize = originalImage.size
        let oHeight = CGImageGetHeight(originalImage.CGImage)
        let sizerBox = UIView(frame: CGRectMake(0, 0, originalImage.size.width, originalImage.size.height))
        sizerBox.transform = CGAffineTransformMakeRotation(rotationInRadians)
        let rotatedSize = sizerBox.frame.size

        UIGraphicsBeginImageContextWithOptions(rotatedSize, false  , 1)
        
        let context = UIGraphicsGetCurrentContext()
        
        CGContextTranslateCTM(context, rotatedSize.width/2, rotatedSize.height/2)
        CGContextRotateCTM(context, rotationInRadians)
        CGContextScaleCTM(context, 1.0, -1.0)
        CGContextDrawImage(context, CGRectMake(-origSize.width/2, -origSize.height/2, origSize.width, origSize.height), originalImage.CGImage)

        
        let result = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return result
    }
    var currentRotationInDegrees = Int(0)
    
    func deg2rad(degrees : Int) -> CGFloat {
        return CGFloat(degrees) * CGFloat(M_PI / 180.0)
    }
    
    func makeCurrentImageFromRotatingOriginalImage(degrees : Int) {
        self.currentImage = self.rotateImage(self.originalImage, rotationInRadians: self.deg2rad(degrees))
        
        self.setup(false)
        self.scrollView.minimumZoomScale = minZoomScale
        self.scrollView.maximumZoomScale = 1
        updateCropBox(currentMaxCropRect)
        cropBoxOverlay.setNeedsDisplay()
        cropBoxOverlayWithLines.setNeedsDisplay()
    }
    
    @IBAction func rotateTapped() {
        imageWasRotated = true
        currentRotationInDegrees -= 90
        if currentRotationInDegrees < 0 {
            currentRotationInDegrees += 360
        }
        
        makeCurrentImageFromRotatingOriginalImage(currentRotationInDegrees)
    }
    
    var lastLocation = CGPoint()
    
    var movingLeftEdge = false
    var movingRightEdge = false
    var movingTopEdge = false
    var movingBottomEdge = false
    
    let touchZoneMargins = CGFloat(15)

    func touchBegan(sender : ICTouchDetectorView,pointInDetectorView: CGPoint) {
        let point = sender.convertPoint(pointInDetectorView, toView: self.view)
        self.cropBoxOverlayWithLines.hidden = false
        UIView.animateWithDuration(0.1, delay: 0, options: .AllowUserInteraction, animations: { () -> Void in
            self.cropBoxOverlayWithLines.alpha = 1
            }) { (done) -> Void in
                if done {
                    self.cropBoxOverlay.hidden = true
                }
        }
        var innerTouchZone = cropFrame
        innerTouchZone.origin.x += touchZoneMargins
        innerTouchZone.origin.y += touchZoneMargins
        innerTouchZone.size.width -= touchZoneMargins*2
        innerTouchZone.size.height -= touchZoneMargins*2
        
        if point.x < innerTouchZone.origin.x {
            movingLeftEdge = true
        } else if point.x > innerTouchZone.origin.x + innerTouchZone.size.width  {
            movingRightEdge = true
        }
        
        if point.y < innerTouchZone.origin.y {
            movingTopEdge = true
        } else if point.y > innerTouchZone.origin.y + innerTouchZone.size.height {
            movingBottomEdge = true
        }
        
        lastLocation = point

    }
    
    func touchMoved(sender : ICTouchDetectorView,pointInDetectorView: CGPoint) {
        let point = sender.convertPoint(pointInDetectorView, toView: self.view)
        adjustCropBox(point)
    }
    
    func touchEnded(sender : ICTouchDetectorView,pointInDetectorView: CGPoint) {
        let point = sender.convertPoint(pointInDetectorView, toView: self.view)
        movingTopEdge = false
        movingBottomEdge = false
        movingLeftEdge = false
        movingRightEdge = false
        
        confineCropBox()
        
        self.cropBoxOverlay.hidden = false
        UIView.animateWithDuration(0.1, delay: 0, options: .AllowUserInteraction, animations: { () -> Void in
            self.cropBoxOverlayWithLines.alpha = 0
            }) { (done) -> Void in
                if done {
                    self.cropBoxOverlayWithLines.hidden = true
                }
        }
    }
    func shouldHandleTouch(sender : ICTouchDetectorView,pointInDetectorView: CGPoint) -> Bool {
        let point = sender.convertPoint(pointInDetectorView, toView: self.view)
        if !inEditMode {
            return false
        }
        var outerTouchZone = cropFrame
        outerTouchZone.origin.x -= touchZoneMargins
        outerTouchZone.origin.y -= touchZoneMargins
        outerTouchZone.size.width += touchZoneMargins*2
        outerTouchZone.size.height += touchZoneMargins*2
        
        if !CGRectContainsPoint(outerTouchZone, point) {
            return false
        }
        
        var innerTouchZone = cropFrame
        innerTouchZone.origin.x += touchZoneMargins
        innerTouchZone.origin.y += touchZoneMargins
        innerTouchZone.size.width -= touchZoneMargins*2
        innerTouchZone.size.height -= touchZoneMargins*2
        
        if CGRectContainsPoint(innerTouchZone, point) {
            return false
        }
        
        imageWasCropped = true

        return true
    }
    
    let minCropBoxDimension = CGFloat(60)
    
    func adjustCropBox(point : CGPoint) {
        let deltaX = point.x - lastLocation.x
        let deltaY = point.y - lastLocation.y
        var frame = cropFrame
        if movingTopEdge {
            frame.origin.y += deltaY
            frame.size.height -= deltaY
        } else if movingBottomEdge {
            frame.size.height += deltaY
        }
        
        if movingLeftEdge {
            frame.origin.x += deltaX
            frame.size.width -= deltaX
        } else if movingRightEdge {
            frame.size.width += deltaX
        }
        if frame.size.width < minCropBoxDimension || frame.size.height < minCropBoxDimension {
            return
        }
        updateCropBox(frame)
        cropBoxOverlay.setNeedsDisplay()
        cropBoxOverlayWithLines.setNeedsDisplay()
        lastLocation = point
    }
    
    func confineCropBox() {
        UIView.animateWithDuration(0.15, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.updateCropBox(CGRectIntersection(self.cropFrame, self.currentMaxCropRect))
            }, completion: {(done) -> Void in
                self.cropBoxOverlay.setNeedsDisplay()
        })
    }

    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat) {
     //   computeCrop()
        confineCropBox()

    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            confineCropBox()
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        confineCropBox()

    }
    
    @IBAction func doneTapped() {
        computeCrop()
        switchOutOfEditMode(true)
    }
    
    @IBAction func useTapped() {
        if let delegate = delegate {
            delegate.imageEditorDidEdit(self, image: croppedImage)
        }
    }
    @IBAction func cancelTapped() {
        if inEditMode {
            canceledOutOfEditing = true
            imageWasRotated = false
            imageWasCropped = false
            makeCurrentImageFromRotatingOriginalImage(prevRotation)
            currentRotationInDegrees = prevRotation
            scrollView.minimumZoomScale = prevMinZoom
            updateCropBox(prevCropFrame)
            currentMaxCropRect = prevMaxCropRect
            scrollView.zoomScale = prevZoomScale
            scrollView.contentOffset = prevContentOffset
            
            computeCrop()
            switchOutOfEditMode(false)
        } else {
            if let delegate = delegate {
                delegate.imageEditorDidCancel(self)
            }
        }
    }
    
    
    @IBAction func resetTapped() {
        currentRotationInDegrees = 0
        makeCurrentImageFromRotatingOriginalImage(0)
        imageWasRotated = false
        imageWasCropped = false

    }
    
    @IBAction func editTapped() {
        imageWasEdited = true
        canceledOutOfEditing = false
        switchToEditMode()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
