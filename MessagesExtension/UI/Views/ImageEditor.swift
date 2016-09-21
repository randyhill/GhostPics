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
        return _baseImage
    }
}

class Face : UIImageView {

}
