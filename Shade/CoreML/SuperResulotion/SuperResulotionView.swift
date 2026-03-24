//
//  SuperResulotionView.swift
//  Shade
//
//  Created by Ahmed Ragab on 23/10/2024.
//

import Foundation
import CoreML
import Accelerate
import Vision
import SwiftUI

struct SuperResulotionView: View {
    @State var inputImage: NSImage = NSImage(resource: .city)
    @State var outImage: NSImage = NSImage(resource: .person2)
    var body: some View {
        VStack {
            HStack(spacing:8) {
                Image(nsImage: inputImage)
                    .resizable()
                    .scaledToFit()
                
                
                Image(nsImage: outImage)
                    .resizable()
                    .scaledToFit()
            }
            Button {
                superResulotion()
            } label: {
                Text("Super resulotion model")
            }

        }
    }
    
    
    func superResulotion() {
        Task {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndGPU
            guard let model = try? VNCoreMLModel(for: RealesrGAN_512(configuration: config).model) else {
                fatalError("could not load ml model")
            }
            
            
            let request = VNCoreMLRequest(model: model) { request, error in
                if let result = request.results as? [VNPixelBufferObservation] {
                    DispatchQueue.main.async {
                        let image = pixelBufferToCGImage(pixelBuffer:result.first!.pixelBuffer)!
                        outImage = NSImage(cgImage:image, size: NSSize(width: image.frame.width, height: image.frame.height))
                    }
                } else if let error = error {
                    print("Error during Core ML request: \(error.localizedDescription)")
                }
            }
            
            guard let inputImage = inputImage.CGImage else {
                fatalError("could not load input image")
            }
            
            let handler = VNImageRequestHandler(cgImage: inputImage,options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform Core ML request: \(error.localizedDescription)")
            }
        }
    }
    
    func pixelBufferToCGImage(pixelBuffer: CVPixelBuffer) -> CGImage? {
        // Create a CIImage from the CVPixelBuffer
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Create a CIContext to render the CIImage
        let ciContext = CIContext(options: nil)
        
        // Get the dimensions of the pixel buffer
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // Render the CIImage to a CGImage
        let cgImage = ciContext.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: width, height: height))
        
        return cgImage
    }
}


#Preview {
    SuperResulotionView()
}


