//
//  PreviewView.swift
//  GhostPics
//
//  Created by CRH on 9/2/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit

//let kNoneFilterNotification = "kNoneFilterNotification"

class PreviewView : UIView {
    private var animation : AnimationClass?
    private var _baseImage : UIImage?
    private var runAgain : UIButton?

    var image : UIImage {
        get {
            animation = AnimationClass(baseImage: _baseImage!, settings: SettingsObject())
            return animation!.asImage()!
        }
    }

    var imageView = UIImageView()
    var message = ""
    var textView = UITextView()
    var activityView = UIActivityIndicatorView()
    var progressBar = UIProgressView()
    var delegate : SettingsProtocol?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        textView.font = UIFont.boldSystemFont(ofSize: 20.0)
        textView.backgroundColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1.0)

        self.backgroundColor = UIColor.white
//        self.layer.borderColor = UIColor.black.cgColor
//        self.layer.borderWidth = 1.0

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pictureTapped))
        self.addGestureRecognizer(tapGesture)

        let lineView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 2))
        lineView.backgroundColor = UIColor.black
        self.addSubview(lineView)
    }

    func initFromData(data : NSData) {
        animation = AnimationClass(data: data)
        self.setImage(newImage: animation!.asImage()!)
        if !animation!.repeatAnimation {

        }
    }

    func asData() -> NSData? {
        return animation!.asData()
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
            self.animation = AnimationClass(baseImage: newImage, settings: SettingsObject())
            self.sizeImageView()
            self.imageView.image = newImage
        }
    }

    func sizeImageView() {
        // Start with image view frame size, and resize to be proportionate to image.
        // Pick the dimension that will fit within image view frame, and shrink to that size.
        if let size = animation?.size {
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

    func filterImage(settings: SettingsObject) {
        self.runAgain?.removeFromSuperview()
        self.runAgain = nil
        if settings.filterType == .None {
            self.imageView.image = self.animation?.baseImage(alpha: 1.0)
        } else {
            runAnimation(settings: settings)
        }
    }

    func runAnimation(settings: SettingsObject) {
        DispatchQueue.main.async {
            // Clear view before showing animation
            self.runAgain?.removeFromSuperview()
            self.runAgain = nil
            self.imageView.image = nil
            self.animation = AnimationClass(baseImage: self._baseImage!, settings: settings)

            // Now show animation after a short delay to show clear view
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (timer) in
                if let filteredImage = self.animation?.asImage() {
                    self.imageView.image = filteredImage
                    if !self.animation!.repeatAnimation {
                        // clean up image in a few seconds
                        Timer.scheduledTimer(withTimeInterval: settings.duration, repeats: false, block: { (timer) in
                            self.imageView.image = nil
                            self.imageView.image = self.animation?.baseImage(alpha: 1.0)
                            self.createTapToRunButton()
                        })
                    }
                }
            }
        }
    }

    func createTapToRunButton() {
        let buttonWidth : CGFloat = 160
        let buttonHeight : CGFloat = 28
        let centerFrame = CGRect(x: (self.frame.width - buttonWidth)/2, y: (self.frame.height - buttonHeight)/2, width: buttonWidth, height: buttonHeight)
        self.runAgain?.removeFromSuperview()
        self.runAgain = nil
        self.runAgain = UIButton(frame: centerFrame)
        self.runAgain?.backgroundColor = UIColor.black
        self.runAgain?.setTitle("Tap to run again", for: .normal)
        self.runAgain?.setTitleColor(UIColor.white, for: .normal)
        self.runAgain?.layer.cornerRadius = 8.0
        self.runAgain?.addTarget(self, action: #selector(self.pictureTapped), for: .touchUpInside)
        self.addSubview(self.runAgain!)
    }

    func pictureTapped() {
        let settings = self.delegate!.getSettings()
        if settings.filterType != .None {
            self.runAnimation(settings: settings)
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
