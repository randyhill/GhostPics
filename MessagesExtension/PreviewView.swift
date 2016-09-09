//
//  PreviewView.swift
//  GhostPics
//
//  Created by CRH on 9/2/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit

let kNoneFilterNotification = "kNoneFilterNotification"

class PreviewView : UIView {
    private var _animation : AnimationClass?
    private var _baseImage : UIImage?
    private var _runAgain : UIButton?

    var image : UIImage {
        get {
            _animation = AnimationClass(baseImage: _baseImage!, filterType: .None, value: 0, alpha: 1.0, repeatAnimation: false)
            return _animation!.asImage()!
            //            return _animation!.getImage(filter: .None, value: 0, alpha: 1.0, repeatAnimation: false)
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

        self.backgroundColor = UIColor.white
//        self.layer.borderColor = UIColor.black.cgColor
//        self.layer.borderWidth = 1.0

//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pictureTapped))
    }

    func initFromData(data : NSData) {
        _animation = AnimationClass(data: data)
        self.setImage(newImage: _animation!.asImage()!)
        if !_animation!.repeatAnimation {

        }
    }

    func asData() -> NSData? {
        return _animation!.asData()
    }

    func clearViews() {
        self.imageView.removeFromSuperview()
        self.textView.removeFromSuperview()
        self.stopActivityFeedback()
    }

    // MARK: Activity Feedback Methods -------------------------------------------------------------------------------------------------
    func startActivityFeedback(completed: (()->())?) {
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
            self._baseImage = newImage
            self.clearViews()
            self.addSubview(self.imageView)
            self._animation = AnimationClass(baseImage: newImage, filterType: .None, value: 0, alpha: 1.0, repeatAnimation: false)
            self.sizeImageView()
            self.imageView.image = newImage
        }
    }

    func sizeImageView() {
        // Start with image view frame size, and resize to be proportionate to image.
        // Pick the dimension that will fit within image view frame, and shrink to that size.
        if let size = _animation?.size {
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

    func filterImage(filter : ImageFilterType, value : Int, alpha: CGFloat, repeatAnimation: Bool) {
        _animation = AnimationClass(baseImage: _baseImage!, filterType: filter, value: value, alpha: alpha, repeatAnimation: repeatAnimation)
        runAnimation()
    }

    func runAnimation() {
        DispatchQueue.main.async {
            self._runAgain?.removeFromSuperview()
            self._runAgain = nil
            if let filteredImage = self._animation?.asImage() {
                self.imageView.image = filteredImage
                if !self._animation!.repeatAnimation && self._animation!.type != .None {
                    // clean up image in a few seconds
                    Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { (timer) in
                        self.imageView.image = nil
                        self.createTapToRunButton()
                    })
                }
            }
        }
    }

    func createTapToRunButton() {
        let buttonWidth : CGFloat = 160
        let buttonHeight : CGFloat = 28
        let centerFrame = CGRect(x: (self.frame.width - buttonWidth)/2, y: (self.frame.height - buttonHeight)/2, width: buttonWidth, height: buttonHeight)
        self._runAgain = UIButton(frame: centerFrame)
        self._runAgain?.backgroundColor = UIColor.black
        self._runAgain?.setTitle("Tap to run again", for: .normal)
        self._runAgain?.setTitleColor(UIColor.white, for: .normal)
        self._runAgain?.layer.cornerRadius = 8.0
        self._runAgain?.addTarget(self, action: #selector(self.pictureTapped), for: .touchUpInside)
        self.addSubview(self._runAgain!)
    }

    func pictureTapped() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (timer) in
            self.runAnimation()
        }
    }

    // MARK: Text Methods -------------------------------------------------------------------------------------------------
    func setText(message : String) {
        DispatchQueue.main.async {
            self.clearViews()
            self.addSubview(self.textView)
            self.textView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            self.textView.text = message
            self.textView.textAlignment = .center
        }
    }
}
