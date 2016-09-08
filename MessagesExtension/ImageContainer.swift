          //
//  ImageContainer
//  GhostPics
//
//  Created by CRH on 9/2/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit

class ImageContainer {
    private var _animation : AnimationClass?
    private var _baseImage : UIImage?

    var size : CGSize {
        get {
            return _baseImage!.size
        }
    }

    init(image: UIImage) {
        _animation = AnimationClass(baseImage: image, filterType: .None, value: 0, alpha: 1.0)
        _baseImage = image
    }

    init(data : NSData) {
        _animation = AnimationClass(data: data)
    }

    func getImage(filter : ImageFilterType, value: Int, alpha: CGFloat) -> UIImage {
        _animation = AnimationClass(baseImage: _baseImage!, filterType: filter, value: value, alpha: alpha)
       return _animation!.asImage()!
    }

    func getImage() -> UIImage {
        return _animation!.asImage()!
    }

    func asData() -> NSData? {
        return _animation!.asData(baseImage: _baseImage!)
    }
}
