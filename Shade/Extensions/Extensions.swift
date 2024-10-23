//
//  Extensions.swift
//  Shade
//
//  Created by Ahmed Ragab on 06/10/2024.
//

import SwiftUI
import Foundation

#if canImport(UIKit)
import UIKit
extension UIImage {
    func pixelBuffer() -> CVPixelBuffer? {
        let options: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: kCFBooleanTrue!
        ]
        var pixelBuffer: CVPixelBuffer?
        let width = Int(size.width)
        let height = Int(size.height)
        
        // Create the pixel buffer
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, options as CFDictionary, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            print("Error: Unable to create CVPixelBuffer")
            return nil
        }
        
        // Lock the pixel buffer base address
        CVPixelBufferLockBaseAddress(buffer, .init(rawValue: 0))
        
        // Get the base address of the pixel buffer
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            CVPixelBufferUnlockBaseAddress(buffer, .init(rawValue: 0))
            print("Error: Unable to create CGContext")
            return nil
        }
        
        // Draw the UIImage into the pixel buffer
        UIGraphicsPushContext(context)
        draw(in: CGRect(origin: .zero, size: size))
        UIGraphicsPopContext()
        
        // Unlock the pixel buffer base address
        CVPixelBufferUnlockBaseAddress(buffer, .init(rawValue: 0))
        
        return buffer
    }
}
#endif

#if canImport(AppKit)
import AppKit
extension NSImage {
    func pixelBuffer() -> CVPixelBuffer? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("Error: Unable to convert NSImage to CGImage")
            return nil
        }
        
        let options: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: kCFBooleanTrue!
        ]
        var pixelBuffer: CVPixelBuffer?
        let width = Int(cgImage.width)
        let height = Int(cgImage.height)
        
        // Create the pixel buffer
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, options as CFDictionary, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            print("Error: Unable to create CVPixelBuffer")
            return nil
        }
        
        // Lock the pixel buffer base address
        CVPixelBufferLockBaseAddress(buffer, .init(rawValue: 0))
        
        // Get the base address of the pixel buffer
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            CVPixelBufferUnlockBaseAddress(buffer, .init(rawValue: 0))
            print("Error: Unable to create CGContext")
            return nil
        }
        
        // Draw the CGImage into the pixel buffer
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Unlock the pixel buffer base address
        CVPixelBufferUnlockBaseAddress(buffer, .init(rawValue: 0))
        
        return buffer
    }
}
#endif

extension Color {
    func toSimdFloat4() -> SIMD4<Float> {
        // Convert SwiftUI Color to NSColor
        let nsColor = NSColor(self)

        // Extract RGBA components
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        // Ensure the color is in device RGB color space
        if ((nsColor.usingColorSpace(.deviceRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)) != nil) == true {
            // Convert CGFloat (0-1) to Float (0-1) and create SIMD4
            return SIMD4<Float>(Float(red), Float(green), Float(blue), Float(alpha))
        } else {
            // Fallback to transparent black if conversion fails
            return SIMD4<Float>(0, 0, 0, 0)
        }
    }
}



extension NSColor {
    var float4: SIMD4<Float> {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return SIMD4<Float>(Float(red), Float(green), Float(blue), Float(alpha))
    }
}

extension NSColor {
    
 convenience init(hex: String) {
    let trimHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    let dropHash = String(trimHex.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
    let hexString = trimHex.starts(with: "#") ? dropHash : trimHex
    let ui64 = UInt64(hexString, radix: 16)
    let value = ui64 != nil ? Int(ui64!) : 0
    // #RRGGBB
    var components = (
        R: CGFloat((value >> 16) & 0xff) / 255,
        G: CGFloat((value >> 08) & 0xff) / 255,
        B: CGFloat((value >> 00) & 0xff) / 255,
        a: CGFloat(1)
    )
    if String(hexString).count == 8 {
        // #RRGGBBAA
        components = (
            R: CGFloat((value >> 24) & 0xff) / 255,
            G: CGFloat((value >> 16) & 0xff) / 255,
            B: CGFloat((value >> 08) & 0xff) / 255,
            a: CGFloat((value >> 00) & 0xff) / 255
        )
    }
    self.init(red: components.R, green: components.G, blue: components.B, alpha: components.a)
}

func toHex(alpha: Bool = false) -> String? {
    guard let components = cgColor.components, components.count >= 3 else {
        return nil
    }
    
    let r = Float(components[0])
    let g = Float(components[1])
    let b = Float(components[2])
    var a = Float(1.0)
    
    if components.count >= 4 {
        a = Float(components[3])
    }
    
    if alpha {
        return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
    } else {
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
}
