//
//  FacesControl.swift
//  GhostPics
//
//  Created by CRH on 9/20/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit

class FacesControl : UIView {
    var faces = [UIImageView]()
    let names = ["dog", "husky", "happydog", "cat", "blackcat", "cateyes"]
    var delegate : MessagesViewController?

    override init(frame: CGRect) {
        super.init(frame: frame)
        initIcons()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initIcons()
    }

    func initIcons() {
        self.backgroundColor = Shared.backgroundColor(alpha: 1.0)
        var faceIndex = 0
         for name in names {
            if let image = UIImage(named: name) {
                let imageView = UIImageView()
                let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
                imageView.addGestureRecognizer(tap)
                imageView.isUserInteractionEnabled = true
                imageView.image = image
                imageView.tag = faceIndex
                imageView.layer.cornerRadius = 4.0
                self.addSubview(imageView)
                faces.append(imageView)
            }
            faceIndex += 1
        }
    }

    func sizeIcons() {
        let width = frame.width/CGFloat(faces.count)
        var iconFrame = CGRect(x: (width-32)/2, y: 2, width: 32, height: 32)
        for face in faces {
            face.frame = iconFrame
            iconFrame.origin.x += width
        }
    }

    func tapped(gesture : UITapGestureRecognizer) {
        if let faceIndex = gesture.view?.tag {
            delegate?.faceTapped(name: names[faceIndex])
        }
    }
}
