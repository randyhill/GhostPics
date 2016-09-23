//
//  IEObjectCorner
//  PictureKeys
//
//  Created by CRH on 7/21/15.
//  Copyright (c) 2015 CRH. All rights reserved.
//

import Foundation
import UIKit

enum ITCorner : Int { case TopLeft = 0, TopRight, BottomLeft, BottomRight}

class IEObjectCorner : UIView {
    var corner = ITCorner.BottomRight
    private var hHandle = UIView()
    private var vHandle = UIView()
    private let sideLength = CGFloat(20)
    private var closeIcon : UIImageView?
    private var face : Face?

    //-----------------------------------------  Init  -----------------------------------------
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(corner: ITCorner, parent: Face) {
        super.init(frame:  CGRect(x: 0, y: 0, width: 0, height: 0))
        self.face = parent
        self.corner = corner
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = false
        self.isUserInteractionEnabled = true
        parent.addSubview(self)
        self.addDragRecognizer(parent: parent)

        if corner == .TopLeft {
            if let closeImage = UIImage(named: "closeIcon") {
                closeIcon = UIImageView(image: closeImage)
                self.addSubview(closeIcon!)
                self.bringSubview(toFront: closeIcon!)
            }
        } else {
            hHandle.backgroundColor = UIColor.red
            vHandle.backgroundColor = UIColor.red
            self.addSubview(hHandle)
            self.addSubview(vHandle)
        }
    }

    func hideCorner(hideIt : Bool) {
        if let _ = closeIcon {
            self.isHidden = hideIt
        }
    }

    //-----------------------------------------  Accessors  -----------------------------------------
    func addDragRecognizer(parent: Face) {
        // Setup a press recognizer
        let drag = UILongPressGestureRecognizer(target: parent, action: #selector(parent.cornersDragged))
        drag.minimumPressDuration = 0
        drag.numberOfTapsRequired = 0
        self.addGestureRecognizer(drag)
    }

    func sizeToParent(parentSize: CGSize) {
        // Size to rect in corner of parent
        var theFrame = CGRect(x: 0, y: 0, width: sideLength, height: sideLength)

        switch (corner) {
        case .TopLeft:
            break;
        case .TopRight:
            theFrame.origin.x = parentSize.width - (closeIcon?.frame.width)!
        case .BottomLeft:
            theFrame.origin.y = parentSize.height - sideLength
        case .BottomRight:
            theFrame.origin.x = parentSize.width - sideLength
            theFrame.origin.y = parentSize.height - sideLength
        }
        self.frame = theFrame

        // Size handles on corners with handles
        if corner != .TopRight {
            let handleThickness = CGFloat(4.0)
            let handleFrame = CGRect(x: 0, y: 0, width: sideLength, height: sideLength)
            hHandle.frame = handleFrame
            vHandle.frame = handleFrame
            hHandle.frame.size.height = handleThickness
            vHandle.frame.size.width = handleThickness

            switch (corner) {
            case .TopLeft:
                break;
            case .TopRight:
                break
            case .BottomLeft:
                hHandle.frame.origin.y = sideLength - handleThickness
            case .BottomRight:
                vHandle.frame.origin.x = sideLength - handleThickness
                hHandle.frame.origin.y = sideLength - handleThickness
            }

            self.bringSubview(toFront: vHandle)
            self.bringSubview(toFront: hHandle)
        }
    }

    // Resize text view depending on movement of our corner
    func resizeToReleasePoint(moved: CGSize, parent: UIView) -> CGRect {
        var newFrame = (parent.frame)
        var sized = newFrame.size
        switch (self.corner) {
        case .TopLeft:
            sized.width -= moved.width
            sized.height -= moved.height
            newFrame.origin.x += moved.width
            newFrame.origin.y += moved.height
        case .TopRight:
            sized.width += moved.width
            sized.height += moved.height
            newFrame.origin.y += moved.height
        case .BottomLeft:
            sized.width -= moved.width
            sized.height += moved.height
            newFrame.origin.x += moved.width
        case .BottomRight:
            sized.width += moved.width
            sized.height += moved.height
        }
        newFrame.size = sized
        let minimumSize : CGFloat = 24.0
        if newFrame.size.height < minimumSize {
            newFrame.size.height = minimumSize
        }
        if newFrame.size.width < minimumSize {
            newFrame.size.width = minimumSize
        }
        return newFrame
    }
}
