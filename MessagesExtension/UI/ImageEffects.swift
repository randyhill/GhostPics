//
//  ImageEffects.swift
//  GhostPics
//
//  Created by CRH on 9/17/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import Foundation

//    struct Pixel {
//        var value: UInt32
//        var red: UInt8 {
//            get { return UInt8(value & 0xFF) }
//            set { value = UInt32(newValue) | (value & 0xFFFFFF00) }
//        }
//        var green: UInt8 {
//            get { return UInt8((value >> 8) & 0xFF) }
//            set { value = (UInt32(newValue) << 8) | (value & 0xFFFF00FF) }
//        }
//        var blue: UInt8 {
//            get { return UInt8((value >> 16) & 0xFF) }
//            set { value = (UInt32(newValue) << 16) | (value & 0xFF00FFFF) }
//        }
//        var alpha: UInt8 {
//            get { return UInt8((value >> 24) & 0xFF) }
//            set { value = (UInt32(newValue) << 24) | (value & 0x00FFFFFF) }
//        }
//        mutating func addValue(value : UInt8) {
//            self.red = addToColor(color: self.red, value: value)
//            self.green = addToColor(color: self.green, value: value)
//            self.blue = addToColor(color: self.blue, value: value)
//        }
//        mutating func subtractValue(value : UInt8) {
//            self.red = addToColor(color: self.red, value: value)
//            self.green = addToColor(color: self.green, value: value)
//            self.blue = addToColor(color: self.blue, value: value)
//        }
//        // Don't overflow
//        func addToColor(color : UInt8, value : UInt8) -> UInt8 {
//            let added : Int = Int(value) + Int(self.red)
//            if added > 255 {
//                return UInt8(added - 255)
//            } else {
//                return UInt8(added)
//            }
//        }
//        // Don't overflow
//        func subFromColor(color : UInt8, value : UInt8) -> UInt8 {
//            let subtracted : Int = Int(value) - Int(self.red)
//            if subtracted < 0 {
//                return UInt8(subtracted + 255)
//            } else {
//                return UInt8(subtracted)
//            }
//        }
//    }
//    struct RGBA {
//        var pixels: UnsafeMutableBufferPointer<Pixel>
//        var width: Int
//        var height: Int
//
//        init?(image: UIImage) {
//            guard let cgImage = image.cgImage else { return nil } // 1
//
//            width = Int(image.size.width)
//            height = Int(image.size.height)
//            let bitsPerComponent = 8 // 2
//
//            let bytesPerPixel = 4
//            let bytesPerRow = width * bytesPerPixel
//            let imageData = UnsafeMutablePointer<Pixel>.allocate(capacity: width * height)
//            let colorSpace = CGColorSpaceCreateDeviceRGB() // 3
//
//            var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
//            bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
//            guard let imageContext = CGContext(data: imageData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else { return nil }
//           // draw(<#T##layer: CALayer##CALayer#>, in: imageContext)
//            imageContext.draw(cgImage, in: CGRect(origin: CGPoint(x: 0, y: 0), size: image.size)) // 4
//
//            pixels = UnsafeMutableBufferPointer<Pixel>(start: imageData, count: width * height)
//        }
//        func toUIImage() -> UIImage? {
//            let bitsPerComponent = 8 // 1
//
//            let bytesPerPixel = 4
//            let bytesPerRow = width * bytesPerPixel
//            let colorSpace = CGColorSpaceCreateDeviceRGB() // 2
//
//            var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
//            bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
//            let imageContext = CGContext(data: pixels.baseAddress, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, releaseCallback: nil, releaseInfo: nil)
//            guard let cgImage = imageContext!.makeImage() else {return nil} // 3
//
//            let image = UIImage(cgImage: cgImage)
//            return image
//        }
//    }
//
//    func encodedImage() -> UIImage? {
//        if let image = animation?._baseImage {
//            var random : UInt8 = 1
//            if let rgba = RGBA(image: image) {
//                for y in 0..<rgba.height {
//                    for x in 0..<rgba.width {
//                        let index = y * rgba.width + x
//                        var pixel = rgba.pixels[index] as Pixel
//                        pixel.addValue(value: random)
//                        rgba.pixels[index] = pixel
//                        random = random < 255 ? random + 1 : 0
//                    }
//                }
//                return rgba.toUIImage()
//            }
//        }
//        return nil
//    }
//
//    func decodeImage(image: UIImage) {
//        var random : UInt8 = 1
//        if let rgba = RGBA(image: image) {
//            for y in 0..<rgba.height {
//                for x in 0..<rgba.width {
//                    let index = y * rgba.width + x
//                    var pixel = rgba.pixels[index] as Pixel
//                    pixel.subtractValue(value: random)
//                    rgba.pixels[index] = pixel
//                    random = random < 255 ? random + 1 : 0
//                }
//            }
//            self.setImage(newImage: image)
//        }
//    }
