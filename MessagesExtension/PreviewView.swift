//
//  PreviewView.swift
//  GhostPics
//
//  Created by CRH on 9/2/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit

class PreviewView : UIView {
    var image : UIImage?

    var imageView = UIImageView()
    var message = ""
    var textView = UITextView()
    var activityView = UIActivityIndicatorView()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        image = UIImage(named: "rounded ghost")
        textView.font = UIFont.boldSystemFont(ofSize: 20.0)
    }

    func setImage(newImage : UIImage) {
        DispatchQueue.main.async {
            self.textView.removeFromSuperview()
            self.addSubview(self.imageView)
            self.image = newImage
            self.sizeImageView()
            self.imageView.image = newImage
        }
    }

    func sizeImageView() {
        if let newImage = self.image {
            // Start with image view frame size, and resize to be proportionate to image.
            // Pick the dimension that will fit within image view frame, and shrink to that size.
            self.imageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            let picProportion = newImage.size.height/newImage.size.width
            let newWidth = self.frame.height / picProportion
            if newWidth < self.frame.width {
                self.imageView.frame.size.width = newWidth
                self.imageView.frame.origin.x = (self.frame.width - newWidth)/2
            } else {
                let newHeight = self.frame.width * picProportion
                self.imageView.frame.size.height = newHeight
                self.imageView.frame.origin.y = (self.frame.height - newHeight)/2
            }
        }
    }

    func setText(message : String) {
        print("Text message: \(message)")

        DispatchQueue.main.async {
            self.imageView.removeFromSuperview()
            self.addSubview(self.textView)
            self.textView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            self.textView.text = message
            self.textView.textAlignment = .center
        }
    }

    func createAnimation(_ image : UIImage) -> UIImage? {
        var animationImage : UIImage?
        var images = [UIImage]()

        // Create background image
        UIGraphicsBeginImageContext(image.size)
        if let context = UIGraphicsGetCurrentContext() {
            UIGraphicsPushContext(context)
            let rectPath = UIBezierPath(rect: CGRect(origin: CGPoint(x: 0, y:0), size:image.size))
            UIColor.gray.setFill()
            rectPath.fill()
            UIGraphicsPopContext()
        }

        // Create animation array
        if let bgImage = UIGraphicsGetImageFromCurrentImageContext() {
            // Create animation
            images.append(bgImage)
            images.append(image)
            images.append(bgImage)
            animationImage = UIImage.animatedImage(with: images, duration: 3.0)
        }
        UIGraphicsEndImageContext()
        return animationImage
    }
}
