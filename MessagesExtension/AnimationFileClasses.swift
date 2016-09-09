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
    case None = 0, Flash, Blinds, Fade

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
        default :
            return .None
        }
    }

    static func isValid(intValue : Int ) -> Bool {
        if intValue >= ImageFilterType.None.rawValue && intValue <= ImageFilterType.Fade.rawValue {
            return true
        }
        return false
    }
}

// MARK: AnimationHeader -------------------------------------------------------------------------------------------------
struct AnimationHeader {
    var headerTag = "FILT"
    var checkSum : Double = 0.0
    var type : ImageFilterType = .None
    var value : Int
    var alpha : CGFloat
    var duration : Double = 2.0
    var repeatAnimation = false
    var imageSize  = 0

    init(type : ImageFilterType, duration : Double, size: Int, value: Int, alpha: CGFloat, repeatAnimation: Bool) {
        self.type = type
        self.duration = duration
        self.imageSize = size
        self.value = value
        self.alpha = alpha
        self.repeatAnimation = repeatAnimation
        self.checkSum = calcCheckSum()
        print("imagesize: \(self.imageSize)")
    }

    func calcCheckSum() -> Double {
        return Double(type.rawValue + imageSize + value) + duration + Double(alpha)
    }

    func printIt() {
        print("Tag: \(headerTag), checkSum: \(checkSum), type: \(type), size: \(imageSize)")
    }
}

// MARK: Animation Class -------------------------------------------------------------------------------------------------
class AnimationClass {
    internal var _images = [UIImage]()
    internal var _duration = 2.0
    internal var _baseImage : UIImage?
    var type : ImageFilterType = .None
    var value = 0
    var alpha : CGFloat = 0.0
    var repeatAnimation = false

    var size : CGSize {
        get {
            return _baseImage!.size
        }
    }

    init(baseImage: UIImage, filterType: ImageFilterType, value: Int, alpha: CGFloat, repeatAnimation: Bool) {
        self.type = filterType
        self.value = value
        self.alpha = alpha
        self._baseImage = baseImage
        self.repeatAnimation = repeatAnimation
        createImages(baseImage: baseImage, filterType: filterType, value: value, alpha: alpha, repeatAnimation: self.repeatAnimation)
    }

    func createImages(baseImage: UIImage, filterType: ImageFilterType, value: Int, alpha: CGFloat, repeatAnimation: Bool) {
        self.repeatAnimation = repeatAnimation
        switch type {
        case .Blinds:
            blindsAnimation(baseImage: baseImage, value: value, alpha: alpha)
        case .Flash:
            flashAnimation(baseImage: baseImage, value: value, alpha: alpha)
        case .Fade:
            fadeAnimation(baseImage: baseImage, value: value, alpha: alpha)
        default:
            baseAnimation(baseImage: baseImage, value: value, alpha: alpha)
        }
    }

    func baseAnimation(baseImage: UIImage, value: Int, alpha: CGFloat) {
        _images.append(baseImage)
    }

    init(data : NSData) {
        // Get header
        var header = AnimationHeader(type: .None, duration: 0.0, size: 0, value: 0, alpha: 0.0, repeatAnimation: false)
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
        type = header.type
        _duration = header.duration

        _images.removeAll()
        let subData = data.subdata(with: NSMakeRange(headerSize, header.imageSize))
        if let image = UIImage(data: subData) {
            createImages(baseImage: image, filterType: header.type, value: header.value, alpha: header.alpha, repeatAnimation: self.repeatAnimation)
        }
    }

    func asImage() -> UIImage? {
        if _images.count == 0 {
            return nil
        }
        return UIImage.animatedImage(with: _images, duration: _duration)
    }

    func asData() -> NSData? {
        if let imageData = UIImageJPEGRepresentation(_baseImage!, 1.0) {
            var header = AnimationHeader(type: type, duration: _duration, size: imageData.count, value: value, alpha: alpha, repeatAnimation: self.repeatAnimation)
            let headerData = encode(value: &header)
            let data = NSMutableData(data: headerData as Data)
            data.append(imageData)
            return data
        }
        return nil
    }

    func encode<T>( value: inout T) -> NSData {
        let sizeOfValue = MemoryLayout<T>.size
        return withUnsafePointer(to: &value) { p in
            NSData(bytes: p, length: sizeOfValue)
        }
    }
    func decode<T>(data: NSData) -> T {
        let length = MemoryLayout<T.Type>.size
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: length)
        data.getBytes(pointer, length: length)
        return pointer.move()
    }

    func flashAnimation(baseImage: UIImage, value: Int, alpha: CGFloat) {
        let color = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: alpha)
        self.type = .Flash
        //_duration = 10.0/Double(value)

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

        // Create animation
        _images.append(bgImage)
        _images.append(baseImage)
        _images.append(bgImage)
    }

    func fadeAnimation(baseImage: UIImage, value: Int, alpha: CGFloat) {
        self.type = .Fade
       // _duration = 10.0/Double(value)

        // Create array of alpha values for fade progression
        let transitions = 20
        let startAlpha : CGFloat = 0.0
        let fadeDistance = CGFloat(1.0 - startAlpha)/CGFloat(transitions)
        var fadeValues = [CGFloat]()
        var startFade = startAlpha
        for _ in 0 ... transitions {
            fadeValues += [startFade]
            startFade += fadeDistance
        }

        // Create faded versions of base image
        for fadeValue in fadeValues {
            let color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: fadeValue)

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
    }

    func blindsAnimation(baseImage: UIImage, value: Int, alpha: CGFloat) {
        type = .Blinds
        //_duration = 1.0
        let slices = CGFloat(22 - value)
        let blindHeight = baseImage.size.height/slices

        if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: -blindHeight, slices: CGFloat(value), alpha: alpha) {
            _images += [newImage]
        }
       if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: -3*blindHeight/4, slices: CGFloat(value), alpha: alpha) {
            _images += [newImage]
        }
        if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: -blindHeight/2, slices: CGFloat(value), alpha: alpha) {
            _images += [newImage]
        }
        if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: -blindHeight/4, slices: CGFloat(value), alpha: alpha) {
            _images += [newImage]
        }
        if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: 0, slices: CGFloat(value), alpha: alpha) {
            _images += [newImage]
        }
        if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: blindHeight/4, slices: CGFloat(value), alpha: alpha) {
            _images += [newImage]
        }
        if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: blindHeight/2, slices: CGFloat(value), alpha: alpha) {
            _images += [newImage]
        }
        if let newImage = createBlindImage(image: baseImage, blindHeight: blindHeight, offset: 3*blindHeight/4, slices: CGFloat(value), alpha: alpha) {
            _images += [newImage]
        }
   }

    // Create image with blinds drawn over it
    func createBlindImage(image : UIImage, blindHeight: CGFloat, offset: CGFloat, slices : CGFloat, alpha: CGFloat) -> UIImage? {

        let color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: alpha)
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
