//
//  ImageEditor.swift
//  GhostPics
//
//  Created by CRH on 9/21/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit

class ImageEditor : UIImageView {
    private var _baseImage : UIImage?
    private var faces = [Face]()

    var baseImage : UIImage? {
        get {
            return _baseImage
        }
        set(newImage) {
            _baseImage = newImage
            self.image = newImage
        }
    }

    func composite() -> UIImage? {
        if faces.count > 0 {
            UIGraphicsBeginImageContext(_baseImage!.size)
            if let context = UIGraphicsGetCurrentContext() {
                UIGraphicsPushContext(context)
                _baseImage!.draw(at: CGPoint(x: 0, y: 0))
                let hRatio = _baseImage!.size.width/self.frame.width
                let vRatio = _baseImage!.size.height/self.frame.height
                for view in self.subviews {
                    if let face = view as? Face {
                        let fframe = CGRect(x: face.frame.origin.x*hRatio, y: face.frame.origin.y*vRatio, width: face.frame.width*hRatio, height: face.frame.height*vRatio)
                        face.image!.draw(in: fframe)
                    }
                }
                UIGraphicsPopContext()
            }
            let bgImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return bgImage
        } else {

            return _baseImage
        }
    }

    func activateFace(activate : Face) {
        for face in faces {
            face.activate(doActivate: face == activate)
        }
        self.bringSubview(toFront: activate)
    }

    func deactivateFaces() {
        for face in faces {
            face.activate(doActivate: false)
        }
    }

    func clearFaces() {
        for face in faces {
            face.removeFromSuperview()
        }
    }


    func removeFace(face : Face) {
        for i in 0...faces.count-1 {
            let indexFace = faces[i]
            if indexFace == face {
                faces.remove(at: i)
                face.removeFromSuperview()
                break
            }
        }
    }

    func addFace(name : String) {
        let imageRect = CGRect(x: (frame.width - 64)/2, y: (frame.height - 64)/2, width: 64, height: 64)
        let newFace = Face(editor: self, name: name, frame: imageRect)
        for face in faces {
            face.activate(doActivate: false)
        }
        faces += [newFace]
        self.addSubview(newFace)
    }
}

class Face : UIImageView {
    internal var cornerViews = [IEObjectCorner]()
    internal var editor : ImageEditor?

    init(editor: ImageEditor, name: String, frame: CGRect) {
        super.init(frame: frame)
        self.editor = editor
        self.frame = frame
        self.backgroundColor = UIColor.clear
        self.layer.borderColor = UIColor.red.cgColor
        self.layer.borderWidth = 1.0
        self.isUserInteractionEnabled = true

        if let image = UIImage(named: name + "256") {
            self.image = image

            // Add drag corners
            cornerViews += [IEObjectCorner(corner: .TopLeft, parent: self)]
            cornerViews += [IEObjectCorner(corner: .BottomRight, parent: self)]
            cornerViews[0].sizeToParent(parentSize: frame.size)
            cornerViews[1].sizeToParent(parentSize: frame.size)
        }
        let drag = UILongPressGestureRecognizer(target: self, action: #selector(self.dragFace))
        drag.minimumPressDuration = 0
        drag.numberOfTapsRequired = 0
        self.addGestureRecognizer(drag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func activate(doActivate : Bool) {
        for corner in cornerViews {
            corner.isHidden = !doActivate
        }
        self.layer.borderColor = doActivate ? UIColor.red.cgColor : UIColor.clear.cgColor
    }

    private  var startPt = CGPoint()
    private var lastResize = NSDate()
    func dragFace(gesture : UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            startPt = gesture.location(in: self.superview!)
            editor?.activateFace(activate: self)
            break;
        case .changed:
             let newPt = gesture.location(in: self.superview!)
            let movedPt = CGSize(width: newPt.x - startPt.x, height: newPt.y - startPt.y)
            self.moveFace(moved: movedPt, gesture: gesture)
            startPt = newPt
        case .ended:
            let newPt = gesture.location(in: self.superview!)
            let movedPt = CGSize(width: newPt.x - startPt.x, height: newPt.y - startPt.y)
            self.moveFace(moved: movedPt, gesture: gesture)
        default:
            break
        }
    }
    // Don't allow resizing text past bottom/right edges of image
    func moveFace(moved: CGSize, gesture : UILongPressGestureRecognizer) {
        var  newFrame = self.frame
        newFrame.origin.x += moved.width
        newFrame.origin.y += moved.height
        var superFrame = self.superview!.frame
        superFrame.origin = CGPoint(x: 0, y: 0)
        if superFrame.contains(newFrame) {
            self.frame = newFrame
        }
    }

    //-----------------------------------------  Corner Handles  -----------------------------------------

    func cornersDragged(gesture : UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            lastResize = NSDate()
            startPt = gesture.location(in: self)
            if let corner = gesture.view as? IEObjectCorner {
                // Remove image if close box tapped
                if corner.corner == .TopLeft  && corner.isHidden == false {
                      editor?.removeFace(face: self)
                }
            }
            break;
        case .changed:
            // If we resize view continioulsy we run out of memory and crash
            // probably because iOS can't release temp memory being used for images
            // Waiting a small amount of time between each time view is resized it
            // appears to allow IOS enough time for garbage cleanup.
            let now = NSDate()
            let newPt = gesture.location(in: self)
            if now.timeIntervalSince(lastResize as Date) > 0.1 {
                let movedPt = CGSize(width: newPt.x - startPt.x, height: newPt.y - startPt.y)
                self.resizeView(moved: movedPt, gesture: gesture)
                lastResize = now
            } else {
                let movedPt = CGSize(width: newPt.x - startPt.x, height: newPt.y - startPt.y)
                let newSize = self.cornerMovedResize(moved: movedPt, gesture: gesture)
                resizeCorners(viewSize: newSize)
            }
            startPt = newPt
        case .ended:
            // Resize view will resize to the new font size that matches rect
            // but can leave excess space in one dimension, so calc size first for font size
            // and then again to "snap" to minimum text rect
            let newPt = gesture.location(in: self)
            let movedPt = CGSize(width: newPt.x - startPt.x, height: newPt.y - startPt.y)
            self.resizeView(moved: movedPt, gesture: gesture)
            resizeCorners(viewSize: self.frame.size)
        default:
            break
        }
    }

    // Don't allow resizing text past bottom/right edges of image
    func resizeView(moved: CGSize, gesture : UILongPressGestureRecognizer) {
        if let gestureView = gesture.view {
            if let corner = gestureView as? IEObjectCorner {
                var  newFrame = corner.resizeToReleasePoint(moved: moved, parent: self)

                // Clip to image frame
                let imageFrame = self.frame
                newFrame = newFrame.intersection(imageFrame)
                self.frame = newFrame
                //_ = self.frame.size
            }
        }
    }

    // Calculate movement from last point in corner
    func cornerMovedResize(moved: CGSize, gesture : UILongPressGestureRecognizer) -> CGSize {
        var newSize = self.frame.size
        if let gestureView = gesture.view {
            if let corner = gestureView as? IEObjectCorner {
                let newFrame = corner.resizeToReleasePoint(moved: moved, parent: self)
                self.frame = newFrame
                newSize = newFrame.size
                resizeCorners(viewSize: newSize)
            }
        }
        return newSize
    }

    // called during drags between timers so we dont' overwhelm memory
    func resizeCorners(viewSize: CGSize) {
        for corner in cornerViews {
             // HIde close box when too small
            let hideIt = (viewSize.width < 60 && viewSize.height < 60)
            corner.hideCorner(hideIt: hideIt)
            corner.sizeToParent(parentSize: viewSize)
        }
    }
}
