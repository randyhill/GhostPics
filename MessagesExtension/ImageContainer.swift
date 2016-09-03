          //
//  ImageContainer
//  GhostPics
//
//  Created by CRH on 9/2/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit

enum ImageFilterType {
    case None, Flash, Blinds

    static func fromInt(filterIndex : Int) -> ImageFilterType {
        switch filterIndex {
        case 0:
            return .None
        case 1:
            return .Flash
        case 2:
            return .Blinds
        default :
            return .None
        }
    }
}

class ImageContainer {
    private var image : UIImage?
    var size : CGSize {
        get {
            return image!.size
        }
    }

    init(image : UIImage) {
        self.image = image
    }

    func getImage(filter : ImageFilterType, value: Int) -> UIImage {
        switch (filter) {
        case .Flash:
            return flashAnimation(self.image!, value: value)!
        case .Blinds:
            return blindsAnimation(self.image!, value: value)!
        default:
            return self.image!;
        }
    }

    func flashAnimation(_ image : UIImage, value: Int) -> UIImage? {
        var images = [UIImage]()

        // Create background
        UIGraphicsBeginImageContext(image.size)
        if let context = UIGraphicsGetCurrentContext() {
            UIGraphicsPushContext(context)
            let rectPath = UIBezierPath(rect: CGRect(origin: CGPoint(x: 0, y:0), size:image.size))
            UIColor.black.setFill()
            rectPath.fill()
            UIGraphicsPopContext()
        }
        guard let bgImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()

        // Create animation
        images.append(bgImage)
        images.append(image)
        images.append(bgImage)
        let duration = 10.0/Double(value)
        return UIImage.animatedImage(with: images, duration: duration)
    }

    func blindsAnimation(_ image : UIImage, value : Int) -> UIImage? {
        var images = [UIImage]()

        let sliceHeight = image.size.height/CGFloat(value)

        if let newImage = createBlindImage(image: image, offset: 0, slices: CGFloat(value)) {
            images += [newImage]
        }
        if let newImage = createBlindImage(image: image, offset: sliceHeight/2, slices: CGFloat(value)) {
            images += [newImage]
        }
        if let newImage = createBlindImage(image: image, offset: -sliceHeight/2, slices: CGFloat(value)) {
            images += [newImage]
        }
        return UIImage.animatedImage(with: images, duration: 2.0)
    }

    // Create image with blinds drawn over it
    func createBlindImage(image : UIImage, offset: CGFloat, slices : CGFloat) -> UIImage? {
        let blindHeight = image.size.height/slices
        var grayRect = CGRect(x: 0, y: offset, width: image.size.width, height: blindHeight)
        UIGraphicsBeginImageContext(image.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        UIGraphicsPushContext(context)

        // Draw image with blinds on top of it every blindHeight
        image.draw(at: CGPoint(x: 0, y: 0))
        let blindsCount = Int(slices/2)
        for _ in 0...blindsCount {
            let rectPath = UIBezierPath(rect: grayRect)
            UIColor.black.setFill()
            rectPath.fill()
            grayRect.origin.y += blindHeight * 2
        }
        UIGraphicsPopContext()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
   }
}
