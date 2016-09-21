//
//  PreviewView.swift
//  GhostPics
//
//  Created by CRH on 9/2/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit

class PreviewView : UIView {
    private var animation : AnimationClass?
    private var runAgain : UIButton?
    private var inActivityFeedback = false

    var image : UIImage {
        get {
            animation = AnimationClass(baseImage: imageView.composite()!, settings: SettingsObject())
            return animation!.asImage()!
        }
    }

    var imageView = ImageEditor()
    var message = ""
    var textView = UITextView()
    var activityView = UIActivityIndicatorView()
    var progressBar = UIProgressView()
    var delegate : SettingsProtocol?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        textView.font = UIFont.boldSystemFont(ofSize: 20.0)
        textView.backgroundColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1.0)
        self.backgroundColor = Shared.backgroundColor(alpha: 1.0)
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pictureTapped))
//        self.addGestureRecognizer(tapGesture)

    }

    func initFromData(data : NSData) {
        animation = AnimationClass(data: data)
        DispatchQueue.main.async {
            self.clearViews()
            self.addSubview(self.imageView)
            self.sizeImageView()
            self.imageView.image = self.animation?.asImage()
            if let settings = self.animation?.settings {
                if settings.filterType != .Blinds && settings.filterType != .None {
                    Timer.scheduledTimer(withTimeInterval: self.animation!.settings.duration, repeats: false, block: { (timer) in
                        self.imageView.image = nil
                    })
                }
            }
        }
    }

    func asData() -> NSData? {
        return animation!.asData()
    }

    func convert(length: Int, data: UnsafePointer<Int8>) -> [Int8] {

        let buffer = UnsafeBufferPointer(start: data, count: length);
        return Array(buffer)
    }

    func clearViews() {
        self.imageView.removeFromSuperview()
        self.textView.removeFromSuperview()
        self.runAgain?.removeFromSuperview()
        self.stopActivityFeedback()
    }

    func hasImage() -> Bool {
        if imageView.composite() == nil {
            return false
        }
        return true
    }

    // MARK: Activity Feedback Methods -------------------------------------------------------------------------------------------------
    func startActivityFeedback(completed: (()->())?) {
        self.inActivityFeedback = true
        DispatchQueue.main.async {
            self.clearViews()
            self.activityView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            self.activityView.activityIndicatorViewStyle = .gray
            self.addSubview(self.activityView)
            self.activityView.startAnimating()
            self.activityView.layer.zPosition = 1

            self.progressBar.frame = CGRect(x: 0, y: 10, width: self.frame.width, height: 10)
            self.progressBar.setProgress(0.05, animated: false)
            self.addSubview(self.progressBar)
            completed?()
        }
    }

    func setProgress(percent : Float) {
        print("percent: \(percent)")
        DispatchQueue.main.async {
            self.progressBar.progress = percent
        }
    }

    func setProgressSync(percent : Float) {
        self.progressBar.setProgress(percent, animated: true)
    }

    func stopActivityFeedback() {
        self.activityView.stopAnimating()
        self.activityView.removeFromSuperview()
        self.progressBar.removeFromSuperview()
        inActivityFeedback = false
    }

    // MARK: Faces
    func addFace(image: UIImage) {
        let imageRect = CGRect(x: (frame.width - 64)/2, y: (frame.height - 64)/2, width: 64, height: 64)
        let imageView = UIImageView(image: image)
        imageView.frame = imageRect
        self.addSubview(imageView)
    }

    // MARK: Image Methods -------------------------------------------------------------------------------------------------
    func setImage(newImage : UIImage) {
        DispatchQueue.main.async {
            self.imageView.baseImage = newImage
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
        if settings.filterType == .None || settings.filterType == .Faces {
            self.imageView.image = self.animation?.baseImage(alpha: 1.0)
        } else if settings.filterType == .Blinds {
            self.animation = AnimationClass(baseImage: self.imageView.composite()!, settings: settings)
            self.imageView.image = self.animation?.asImage()!
        } else {
            runOnce(settings: settings)
        }
    }

    func runOnce(settings: SettingsObject) {
        DispatchQueue.main.async {
            var startDelay = 0.1
            switch settings.filterType {
            case .Flash:
                self.imageView.image = nil
                startDelay = 1.0
            case .Blinds:
                break
            case .Fade:
                break
            default:
                break
            }
            // Clear view before showing animation
            self.runAgain?.removeFromSuperview()
            self.runAgain = nil
            self.animation = AnimationClass(baseImage: self.imageView.composite()!, settings: settings)

            // Now show animation after a short delay to show clear view
           Timer.scheduledTimer(withTimeInterval: startDelay, repeats: false) { (timer) in
                if let filteredImage = self.animation?.asImage() {
                    self.imageView.image = filteredImage
                    // clean up image in a few seconds. Sometimes the image finishes early and restarts
                    // so we'll start cleanup early to eliinate a flash from that happening
                    let duration = settings.duration * 0.8
                    Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { (timer) in
                        self.imageView.image = nil
                        self.createTapToRunButton()
                    })
                }
            }
        }
    }

    func createTapToRunButton() {
        if !inActivityFeedback {
            let buttonWidth : CGFloat = 160
            let buttonHeight : CGFloat = 36
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
    }

    func pictureTapped() {
        let settings = self.delegate!.getSettings()
        if settings.filterType != .None {
            self.runOnce(settings: settings)
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
