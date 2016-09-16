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

        self.backgroundColor = Shared.backgroundColor(alpha: 1.0)


        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pictureTapped))
        self.addGestureRecognizer(tapGesture)

    }

    func initFromData(data : NSData) {
        animation = AnimationClass(data: data)
        DispatchQueue.main.async {
            self.clearViews()
            self.addSubview(self.imageView)
            self.sizeImageView()
            self.imageView.image = self.animation?.asImage()
            if let settings = self.animation?.settings {
                if !settings.doRepeat && settings.filterType != .None {
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

    struct Pixel {
        var value: UInt32
        var red: UInt8 {
            get { return UInt8(value & 0xFF) }
            set { value = UInt32(newValue) | (value & 0xFFFFFF00) }
        }
        var green: UInt8 {
            get { return UInt8((value >> 8) & 0xFF) }
            set { value = (UInt32(newValue) << 8) | (value & 0xFFFF00FF) }
        }
        var blue: UInt8 {
            get { return UInt8((value >> 16) & 0xFF) }
            set { value = (UInt32(newValue) << 16) | (value & 0xFF00FFFF) }
        }
        var alpha: UInt8 {
            get { return UInt8((value >> 24) & 0xFF) }
            set { value = (UInt32(newValue) << 24) | (value & 0x00FFFFFF) }
        }
        mutating func addRandom(random : UInt8) {
            self.red = limitRandom(color: self.red, random: random)
            self.green = limitRandom(color: self.green, random: random)
            self.blue = limitRandom(color: self.blue, random: random)
        }
        func limitRandom(color : UInt8, random : UInt8) -> UInt8 {
            let value : Int = Int(random) + Int(self.red)
            if value > 255 {
                return UInt8(value - 255)
            } else {
                return UInt8(value)
            }
        }
    }
    struct RGBA {
        var pixels: UnsafeMutableBufferPointer<Pixel>
        var width: Int
        var height: Int

        init?(image: UIImage) {
            guard let cgImage = image.cgImage else { return nil } // 1

            width = Int(image.size.width)
            height = Int(image.size.height)
            let bitsPerComponent = 8 // 2

            let bytesPerPixel = 4
            let bytesPerRow = width * bytesPerPixel
            let imageData = UnsafeMutablePointer<Pixel>.allocate(capacity: width * height)
            let colorSpace = CGColorSpaceCreateDeviceRGB() // 3

            var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
            bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
            guard let imageContext = CGContext(data: imageData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else { return nil }
           // draw(<#T##layer: CALayer##CALayer#>, in: imageContext)
            imageContext.draw(cgImage, in: CGRect(origin: CGPoint(x: 0, y: 0), size: image.size)) // 4

            pixels = UnsafeMutableBufferPointer<Pixel>(start: imageData, count: width * height)
        }
        func toUIImage() -> UIImage? {
            let bitsPerComponent = 8 // 1

            let bytesPerPixel = 4
            let bytesPerRow = width * bytesPerPixel
            let colorSpace = CGColorSpaceCreateDeviceRGB() // 2

            var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
            bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
            let imageContext = CGContext(data: pixels.baseAddress, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, releaseCallback: nil, releaseInfo: nil)
            guard let cgImage = imageContext!.makeImage() else {return nil} // 3
            
            let image = UIImage(cgImage: cgImage)
            return image
        }
    }


    func encodedImage() -> UIImage? {
        if let image = animation?._baseImage {
            var random : UInt8 = 1
            if let rgba = RGBA(image: image) {
                for y in 0..<rgba.height {
                    for x in 0..<rgba.width {
                        let index = y * rgba.width + x
                        var pixel = rgba.pixels[index] as Pixel
                        pixel.addRandom(random: random)
                        rgba.pixels[index] = pixel
                        random = random < 255 ? random + 1 : 0
                    }
                }
                return rgba.toUIImage()
            }
        }

//        if var imageData = animation!.asJPEGData() {
//            let byteCount = imageData.count
//            print("Count: \(byteCount)")
//            var bytes = [UInt8](repeating: 0, count: byteCount)
//            for i in 0..<byteCount {
//                let value = ~imageData[i]
//                bytes[i] = UInt8(value)
//            }
//            let newImageData = Data(bytes: bytes, count: byteCount)
//            let image = UIImage(data: newImageData)
//            return image
//        }
        return nil
    }


    func clearViews() {
        self.imageView.removeFromSuperview()
        self.textView.removeFromSuperview()
        self.stopActivityFeedback()
    }

    func hasImage() -> Bool {
        if _baseImage == nil {
            return false
        }
        return true
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
            self.progressBar.setProgress(0.0, animated: false)
            self.addSubview(self.progressBar)
            completed?()
        }
    }

    func setProgress(percent : Float) {
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
                    if !self.animation!.doRepeat {
                        // clean up image in a few seconds
                        let duration = settings.duration * 0.9
                        Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { (timer) in
                            self.imageView.image = nil
                            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { (timer) in
                                self.imageView.image = self.animation?.baseImage(alpha: 1.0)
                                self.createTapToRunButton()
                            })
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
