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
    case None = 0, Flash, Blinds

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

    static func isValid(intValue : Int ) -> Bool {
        if intValue >= 0 && intValue <= 2 {
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
    var duration : Double = 0.0
    var imageSize  = 0

    init(type : ImageFilterType, duration : Double, size: Int, value: Int) {
        self.type = type
        self.duration = duration
        self.imageSize = size
        self.value = value
        self.checkSum = calcCheckSum()
        print("imagesize: \(self.imageSize)")
    }

    func calcCheckSum() -> Double {
        return Double(type.rawValue + imageSize + value) + duration
    }

    func printIt() {
        print("Tag: \(headerTag), checkSum: \(checkSum), type: \(type), size: \(imageSize)")
    }
}

// MARK: Animation Class -------------------------------------------------------------------------------------------------
class AnimationClass {
    internal var _images = [UIImage]()
    internal var _duration = 0.0
    var type : ImageFilterType = .None
    var value = 0

    init(baseImage: UIImage, filterType: ImageFilterType, value: Int) {
        type = filterType
        self.value = value
        createImages(baseImage: baseImage, filterType: filterType, value: value)
    }

    func createImages(baseImage: UIImage, filterType: ImageFilterType, value: Int) {
        switch type {
        case .Blinds:
            blindsAnimation(baseImage: baseImage, value: value)
        case .Flash:
            flashAnimation(baseImage: baseImage, value: value)
        default:
            baseAnimation(baseImage: baseImage, value: value)
        }
    }

    func baseAnimation(baseImage: UIImage, value: Int) {
        _images.append(baseImage)
    }

    init(data : NSData) {
        // Get header
        var header = AnimationHeader(type: .None, duration: 0.0, size: 0, value: 0)
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
            createImages(baseImage: image, filterType: header.type, value: header.value)
        }
    }

    func asImage() -> UIImage? {
        if _images.count == 0 {
            return nil
        }
        return UIImage.animatedImage(with: _images, duration: _duration)
    }

    func asData(baseImage : UIImage) -> NSData? {
        if let imageData = UIImageJPEGRepresentation(baseImage, 1.0) {
            var header = AnimationHeader(type: type, duration: _duration, size: imageData.count, value: value)
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

    func flashAnimation(baseImage: UIImage, value: Int) {
        self.type = .Flash
        _duration = 10.0/Double(value)

        // Create background
        UIGraphicsBeginImageContext(baseImage.size)
        if let context = UIGraphicsGetCurrentContext() {
            UIGraphicsPushContext(context)
            let rectPath = UIBezierPath(rect: CGRect(origin: CGPoint(x: 0, y:0), size: baseImage.size))
            UIColor.black.setFill()
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

    func blindsAnimation(baseImage: UIImage, value: Int) {
        type = .Blinds
        let sliceHeight = baseImage.size.height/CGFloat(22 - value)
        _duration = 2.0

        if let newImage = createBlindImage(image: baseImage, offset: 0, slices: CGFloat(value)) {
            _images += [newImage]
        }
        if let newImage = createBlindImage(image: baseImage, offset: sliceHeight/2, slices: CGFloat(value)) {
            _images += [newImage]
        }
        if let newImage = createBlindImage(image: baseImage, offset: -sliceHeight/2, slices: CGFloat(value)) {
            _images += [newImage]
        }
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
