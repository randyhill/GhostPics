//
//  CameraOverlay.swift
//  GhostPics
//
//  Created by CRH on 9/16/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit

enum CameraControl : Int {
    case Rotate = 0, Snap, Pictures
}

class CameraOverlay : UIView {
    let cameraControls = UISegmentedControl()

    init(frame: CGRect, isCompact: Bool) {

        super.init(frame: frame)
        cameraControls.insertSegment(with: UIImage(named: "rotate"), at: 0, animated: false)
        cameraControls.insertSegment(with: UIImage(named: "snap48"), at: 1, animated: false)
        cameraControls.insertSegment(with: UIImage(named: "landscape-picture"), at: 2, animated: false)
        cameraControls.isMomentary = true
        cameraControls.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        cameraControls.layer.cornerRadius = 8.0
        cameraControls.layer.borderWidth = 0.0

        // Remove borders
        self.sizeControls(frame: frame, isCompact: isCompact)
        cameraControls.setDividerImage(imageWithColor(color: UIColor.clear), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: UIBarMetrics.default)
        for borderView in cameraControls.subviews {
            let upperBorder = CALayer()
            upperBorder.backgroundColor = UIColor.black.cgColor
            upperBorder.frame = CGRect(x: 0,  y: borderView.frame.size.height-1, width: borderView.frame.size.width, height: 1)
            borderView.layer.addSublayer(upperBorder)
        }
        self.cameraControls.tintColor = UIColor.white
        self.addSubview(cameraControls)
    }

    func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 72)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor);
        context!.fill(rect);
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image!
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func sizeControls(frame: CGRect, isCompact: Bool) {
        self.frame = frame
        let defaultSize : CGFloat = 72.0
        let width = frame.width > defaultSize * 3 ? defaultSize * 3 : frame.width
        self.cameraControls.frame = CGRect(x: (frame.width-width)/2, y: 4, width: width, height: defaultSize)
    }
}
