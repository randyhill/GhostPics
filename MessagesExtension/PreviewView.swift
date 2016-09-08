//
//  PreviewView.swift
//  GhostPics
//
//  Created by CRH on 9/2/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit

class PreviewView : UIView {
    private var _imageContainer : ImageContainer?
    var image : UIImage {
        get {
            return _imageContainer!.getImage(filter: .None, value: 0, alpha: 1.0)
        }
    }

    var imageView = UIImageView()
    var message = ""
    var textView = UITextView()
    var activityView = UIActivityIndicatorView()
    var progressBar = UIProgressView()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
       // _image = ImageContainer(image: UIImage(named: "rounded ghost")!)
        textView.font = UIFont.boldSystemFont(ofSize: 20.0)
        textView.backgroundColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1.0)
    }

    func initFromData(data : NSData) {
        _imageContainer = ImageContainer(data: data)
        self.setImage(newImage: _imageContainer!.getImage())
    }

    func asData() -> NSData? {
        return _imageContainer!.asData()
    }

    func clearViews() {
        self.imageView.removeFromSuperview()
        self.textView.removeFromSuperview()
        self.stopActivityFeedback()
    }

    // MARK: Activity Feedback Methods -------------------------------------------------------------------------------------------------
    func startActivityFeedback(completed: (@escaping ()->())?) {
        print("start activity feedback")

        DispatchQueue.main.async {
            self.clearViews()
            self.activityView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            self.activityView.activityIndicatorViewStyle = .gray
            self.addSubview(self.activityView)
            self.activityView.startAnimating()
            self.activityView.layer.zPosition = 1

            self.progressBar.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 10)
            self.addSubview(self.progressBar)
            completed?()
        }
    }

    func setProgress(percent : Float) {
        DispatchQueue.main.async {
            self.progressBar.progress = percent
        }
    }

    func stopActivityFeedback() {
        self.activityView.stopAnimating()
        self.activityView.removeFromSuperview()
        self.progressBar.removeFromSuperview()
    }

    // MARK: Image Methods -------------------------------------------------------------------------------------------------
    func setImage(newImage : UIImage) {
        DispatchQueue.main.async {
            self.clearViews()
            self.addSubview(self.imageView)
            self._imageContainer = ImageContainer(image: newImage)
            self.sizeImageView()
            self.imageView.image = newImage
        }
    }

    func sizeImageView() {
        // Start with image view frame size, and resize to be proportionate to image.
        // Pick the dimension that will fit within image view frame, and shrink to that size.
        if let size = _imageContainer?.size {
            self.imageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            let picProportion = size.height/size.width
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

    func filterImage(filterIndex : Int, value : Int, alpha: CGFloat) {
        if let filteredImage = _imageContainer?.getImage(filter: ImageFilterType.fromInt(filterIndex: filterIndex), value: value, alpha: alpha) {
            self.imageView.image = filteredImage
        }

    }

    // MARK: Text Methods -------------------------------------------------------------------------------------------------
    func setText(message : String) {
        print("Text message: \(message)")

        DispatchQueue.main.async {
            self.clearViews()
            self.addSubview(self.textView)
            self.textView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            self.textView.text = message
            self.textView.textAlignment = .center
        }
    }
}