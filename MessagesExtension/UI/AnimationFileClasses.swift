//
//  AnimationFileClasses.swift
//  GhostPics
//
//  Created by CRH on 9/6/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit

// MARK: Enums -------------------------------------------------------------------------------------------------
enum ImageFilterType : Int {
    case None = 0, Flash, Blinds, Fade, Faces

    static func fromInt(filterIndex : Int) -> ImageFilterType {
        switch filterIndex {
        case 0:
            return .None
        case 1:
            return .Flash
        case 2:
            return .Blinds
        case 3:
            return .Fade
        case 4:
            return .Faces
        default :
            return .None
        }
    }

    static func isValid(intValue : Int ) -> Bool {
        if intValue >= ImageFilterType.None.rawValue && intValue <= ImageFilterType.Faces.rawValue {
            return true
        }
        return false
    }
}

// MARK: Extensions -------------------------------------------------------------------------------------------------
extension UIImage {
    func resizeWith(percentage: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: size.width * percentage, height: size.height * percentage)))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
//    func resizeWith(width: CGFloat) -> UIImage? {
//        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))))
//        imageView.contentMode = .scaleAspectFit
//        imageView.image = self
//        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
//        guard let context = UIGraphicsGetCurrentContext() else { return nil }
//        imageView.layer.render(in: context)
//        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
//        UIGraphicsEndImageContext()
//        return result
//    }
}

// MARK: AnimationHeader -------------------------------------------------------------------------------------------------
struct AnimationHeader {
    var headerTag = "FILT"
    var checkSum : Double = 0.0
    var type : ImageFilterType = .None
    var alpha : CGFloat
    var duration : Double = 2.0
    var doRepeat = false
    var blindsSize : CGFloat = 0.1
    var imageSize  = 0

    init(type : ImageFilterType, duration : Double, size: Int, blindsSize: CGFloat, alpha: CGFloat, doRepeat: Bool) {
        self.type = type
        self.duration = duration
        self.imageSize = size
        self.blindsSize = blindsSize
        self.alpha = alpha
        self.doRepeat = doRepeat
        self.checkSum = calcCheckSum()
    }

    init(settings: SettingsObject, imageSize : Int) {
        self.type = settings.filterType
        self.duration = settings.duration
        self.imageSize = imageSize
        self.blindsSize = settings.blindSize
        self.alpha = settings.alpha
        self.checkSum = calcCheckSum()
    }

    func calcCheckSum() -> Double {
        return Double(type.rawValue + imageSize) + duration + Double(alpha + blindsSize)
    }

    func asSettings() -> SettingsObject {
        let settings = SettingsObject()
        settings.filterType = type
        settings.alpha = alpha
        settings.duration = duration
        settings.blindSize = blindsSize
        settings.duration = duration
        return settings
    }
}

// MARK: Animation Class -------------------------------------------------------------------------------------------------
class AnimationClass {
    internal var _images = [UIImage]()
    internal var _baseImage : UIImage?
    var settings = SettingsObject()

    var size : CGSize? {
        get {
            return _baseImage?.size
        }
    }

    init(baseImage: UIImage, settings: SettingsObject) {
        self.settings = settings
        self._baseImage = baseImage
        createImages(baseImage: baseImage, settings: settings)
    }

    init(data : NSData) {
        // Get header
        var header = AnimationHeader(type: .None, duration: 0.0, size: 0, blindsSize: 0.1, alpha: 0.0, doRepeat: false)
        let headerSize = MemoryLayout<AnimationHeader>.size
        data.getBytes(&header, length: headerSize)

        guard header.calcCheckSum() == header.checkSum else {
            print("Failed checksum")
            return
        }
        guard ImageFilterType.isValid(intValue: header.type.rawValue) else {
            print("Failed type check")
            return
        }
        settings = header.asSettings()

        _images.removeAll()
        let subData = data.subdata(with: NSMakeRange(headerSize, header.imageSize))
        if let image = UIImage(data: subData) {
            createImages(baseImage: image, settings: header.asSettings())
        }
    }

    let jpegQuality : CGFloat = 0.7
    func asData(image: UIImage) -> NSData? {
        if let imageData = UIImageJPEGRepresentation(image, jpegQuality) {
            var header = AnimationHeader(settings: settings, imageSize: imageData.count)
            let headerData = encode(value: &header)
            let data = NSMutableData(data: headerData as Data)
            data.append(imageData)
            return data
        }
        return nil
    }

//    func asJPEGData() -> Data? {
//        return UIImageJPEGRepresentation(_baseImage!, jpegQuality)
//    }


    func encode<T>( value: inout T) -> NSData {
        let sizeOfValue = MemoryLayout<T>.size
        return withUnsafePointer(to: &value) { p in
            NSData(bytes: p, length: sizeOfValue)
        }
    }

    // MARK: Images -------------------------------------------------------------------------------------------------
    // return base image faded with alpha, or not
    func baseImage(alpha: CGFloat) -> UIImage? {
        guard let baseImage = _baseImage else {
            return nil
        }
        UIGraphicsBeginImageContext(baseImage.size)
        if let context = UIGraphicsGetCurrentContext() {
            UIGraphicsPushContext(context)
            let color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1 - alpha)
            baseImage.draw(at: CGPoint(x: 0, y: 0))
            let rectPath = UIBezierPath(rect: CGRect(origin: CGPoint(x: 0, y:0), size: baseImage.size))
            color.setFill()
            rectPath.fill()
            UIGraphicsPopContext()
        }
        let bgImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return bgImage
    }

    func asImage() -> UIImage? {
        if _images.count == 0 {
            return _baseImage
        }
        return UIImage.animatedImage(with: _images, duration: settings.duration)
    }

    func createImages(baseImage: UIImage, settings: SettingsObject) {
        self._baseImage = baseImage
        if let previewImage = baseImage.resizeWith(percentage: 0.5) {
            switch settings.filterType {
            case .Blinds:
                blindsAnimation(baseImage: previewImage, settings: settings)
            case .Flash:
                flashAnimation(baseImage: previewImage,  settings: settings)
            case .Fade:
                fadeAnimation(baseImage: previewImage,  settings: settings)
            default:
                baseAnimation(baseImage: previewImage,  settings: settings)
            }
        }

    }

    private func clearImage(baseImage: UIImage) -> UIImage? {
        let color = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)

        // Create background
        UIGraphicsBeginImageContext(baseImage.size)
        if let context = UIGraphicsGetCurrentContext() {
            UIGraphicsPushContext(context)
            let rectPath = UIBezierPath(rect: CGRect(origin: CGPoint(x: 0, y:0), size: baseImage.size))
            color.setFill()
            rectPath.fill()
            UIGraphicsPopContext()
        }
        let bgImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return bgImage
    }

    // MARK: Animations -------------------------------------------------------------------------------------------------
    private func baseAnimation(baseImage: UIImage, settings: SettingsObject) {
        _images.append(baseImage)
    }

    private func flashAnimation(baseImage: UIImage, settings: SettingsObject) {
        // Create animation
        if let clearImage = self.clearImage(baseImage: baseImage) {
            // Flash is 1/5 of animation
            for _ in 1...4 {
                _images.append(baseImage)
            }
            _images.append(clearImage)
        }
    }

    private func fadeAnimation(baseImage: UIImage, settings: SettingsObject) {
        // Create array of alpha values for fade progression
        let transitions = 8
        let startAlpha : CGFloat = 1.0 - settings.alpha
        let fadeDistance = CGFloat(1.0 - startAlpha)/CGFloat(transitions)
        var fadeValues = [CGFloat]()
        var startFade = startAlpha
        for _ in 0 ... transitions {
            fadeValues += [startFade]
            startFade += fadeDistance
        }

        // Create faded versions of base image
        for fadeValue in fadeValues {
            let color =  Shared.backgroundColor(alpha: fadeValue)

            // Create background
            UIGraphicsBeginImageContext(baseImage.size)
            if let context = UIGraphicsGetCurrentContext() {
                UIGraphicsPushContext(context)
                baseImage.draw(at: CGPoint(x: 0, y: 0))
                let rectPath = UIBezierPath(rect: CGRect(origin: CGPoint(x: 0, y:0), size: baseImage.size))
                color.setFill()
                rectPath.fill()
                UIGraphicsPopContext()
            }
            guard let bgImage = UIGraphicsGetImageFromCurrentImageContext() else {
                UIGraphicsEndImageContext()
                return
            }
            UIGraphicsEndImageContext()
            _images.append(bgImage)
        }
        // Clear images 1/4 of fade images
        if let clearImage = self.clearImage(baseImage: baseImage) {
            _images.append(clearImage)
        }
    }

    private func blindsAnimation(baseImage: UIImage, settings: SettingsObject) {
        let slices = CGFloat(22 * (1.1 - settings.blindSize))
        let blindHeight = baseImage.size.height/slices

        if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: -blindHeight, slices: slices, alpha: settings.alpha) {
            _images += [newImage]
        }
       if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: -3*blindHeight/4, slices: slices, alpha: settings.alpha) {
            _images += [newImage]
        }
        if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: -blindHeight/2, slices: slices, alpha: settings.alpha) {
            _images += [newImage]
        }
        if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: -blindHeight/4, slices: slices, alpha: settings.alpha) {
            _images += [newImage]
        }
        if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: 0, slices: slices, alpha: settings.alpha) {
            _images += [newImage]
        }
        if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: blindHeight/4, slices: slices, alpha: settings.alpha) {
            _images += [newImage]
        }
        if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: blindHeight/2, slices: slices, alpha: settings.alpha) {
            _images += [newImage]
        }
        if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: 3*blindHeight/4, slices: slices, alpha: settings.alpha) {
            _images += [newImage]
        }
   }

    // Create image with blinds drawn over it
    private func createBlindImage(image : UIImage, blindHeight: CGFloat, offset: CGFloat, slices : CGFloat, alpha: CGFloat) -> UIImage? {

        let color = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.85)
        var grayRect = CGRect(x: 0, y: offset, width: image.size.width, height: blindHeight)
        UIGraphicsBeginImageContext(image.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        UIGraphicsPushContext(context)

        // Draw image with blinds on top of it every blindHeight
        image.draw(at: CGPoint(x: 0, y: 0))
        while grayRect.origin.y < image.size.height {
            let rectPath = UIBezierPath(rect: grayRect)
            color.setFill()
            rectPath.fill()
            grayRect.origin.y += blindHeight * 2
        }
        UIGraphicsPopContext()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
