//
//  ContentView.swift
//  CoreMLBackgroundChangeSwiftUI
//
//  Created by Anupam Chugh on 27/05/21.
//

import SwiftUI
import CoreML
import CoreMedia
import Vision

extension NSImage {
    class func imageFromColor(color: NSColor, scale: CGFloat) -> NSImage {
           let baseSize = CGSize(width: 1, height: 1)
           let scaledSize = CGSize(width: baseSize.width * scale, height: baseSize.height * scale)
           
           let image = NSImage(size: scaledSize)
           image.lockFocus()
           color.drawSwatch(in: NSRect(origin: .zero, size: scaledSize))
           image.unlockFocus()
           
           return image
       }
    /// Creates an `NSImage` filled with the given color and size.
    class func imageFromColor(color: NSColor, size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        color.drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()
        return image
    }
    
    func resizedImage(for newSize: CGSize) -> NSImage? {
          guard let bitmapRep = NSBitmapImageRep(
                  bitmapDataPlanes: nil,
                  pixelsWide: Int(newSize.width),
                  pixelsHigh: Int(newSize.height),
                  bitsPerSample: 8,
                  samplesPerPixel: 4,
                  hasAlpha: true,
                  isPlanar: false,
                  colorSpaceName: .deviceRGB,
                  bytesPerRow: 0,
                  bitsPerPixel: 0) else {
              return nil
          }

          bitmapRep.size = newSize

          let resizedImage = NSImage(size: newSize)
          resizedImage.addRepresentation(bitmapRep)

          resizedImage.lockFocus()
          let context = NSGraphicsContext.current
          context?.imageInterpolation = .high
          self.draw(in: NSRect(origin: .zero, size: newSize),
                    from: NSRect(origin: .zero, size: self.size),
                    operation: .sourceOver,
                    fraction: 1.0)
          resizedImage.unlockFocus()

          return resizedImage
      }
}
#if canImport(UIKit)
extension UIImage {
    class func imageFromColor(color: Color, size: CGSize=CGSize(width: 1, height: 1), scale: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func resizedImage(for size: CGSize) -> UIImage? {
            let image = self.cgImage
            print(size)
            let context = CGContext(data: nil,
                                    width: Int(size.width),
                                    height: Int(size.height),
                                    bitsPerComponent: image!.bitsPerComponent,
                                    bytesPerRow: Int(size.width),
                                    space: image?.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
                                    bitmapInfo: image!.bitmapInfo.rawValue)
            context?.interpolationQuality = .high
            context?.draw(image!, in: CGRect(origin: .zero, size: size))

            guard let scaledImage = context?.makeImage() else { return nil }

            return UIImage(cgImage: scaledImage)
    }
    
    
    convenience init?(size: CGSize, gradientPoints: [GradientPoint], scale : CGFloat) {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)

        guard let context = UIGraphicsGetCurrentContext() else { return nil }       // If the size is zero, the context will be nil.
        guard let gradient = CGGradient(colorSpace: CGColorSpaceCreateDeviceRGB(), colorComponents: gradientPoints.compactMap { $0.color.cgColor.components }.flatMap { $0 }, locations: gradientPoints.map { $0.location }, count: gradientPoints.count) else {
            return nil
        }

        context.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: 0, y: size.height), options: CGGradientDrawingOptions())
        guard let image = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else { return nil }
        self.init(cgImage: image)
        defer { UIGraphicsEndImageContext() }
    }

}




extension UIImage {
  func withAlphaComponent(_ alpha: CGFloat) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    defer { UIGraphicsEndImageContext() }

    draw(at: .zero, blendMode: .normal, alpha: alpha)
    return UIGraphicsGetImageFromCurrentImageContext()
  }
}
#endif
struct PersonsSegmentaionView: View {

    @State var outputImage : NSImage = NSImage.imageFromColor(color: .red, scale: 1)
    @State var inputImage : NSImage = NSImage(resource: .person)
    

    var body: some View {
        
            
            
                
                VStack{
                    
                    HStack{
                        
                        Image(nsImage: inputImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            
                        Spacer()
                        Image(nsImage: outputImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)

                    }

                    Button(action: {runVisionRequest()}, label: {
                        Text("Run Image Segmentation")
                    })
                    .padding()
                    
                }
    }

    func runVisionRequest() {
        
        guard let model = try? VNCoreMLModel(for: DeepLabV3_model(configuration: .init()).model)
        else { return }
        
        let request = VNCoreMLRequest(model: model, completionHandler: visionRequestDidComplete)
        request.imageCropAndScaleOption = .scaleFill
        DispatchQueue.global().async {

            let handler = VNImageRequestHandler(cgImage: inputImage.CGImage!, options: [:])
            
            do {
                try handler.perform([request])
            }catch {
                print(error)
            }
        }
    }
    

    func visionRequestDidComplete(request: VNRequest, error: Error?) {
            DispatchQueue.main.async {
                if let observations = request.results as? [VNCoreMLFeatureValueObservation],
                    let segmentationmap = observations.first?.featureValue.multiArrayValue {
                    
                    let segmentationMask = segmentationmap.image(min: 0, max: 1)

                    self.outputImage = segmentationMask!.resizedImage(for: self.inputImage.size)!

                    

                }
            }
    }
}

struct GradientPoint {
   var location: CGFloat
   var color: NSColor
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PersonsSegmentaionView()
            .padding()
    }
}
