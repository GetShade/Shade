//
//  ObjectDetection.swift
//  Shade
//
//  Created by Ahmed Ragab on 23/10/2024.
//

import Foundation
import SwiftUI
import CoreML
import Vision

struct ObjectDetectionView: View {
    @State private var detectedObjects: [VNRecognizedObjectObservation] = []
    var image = NSImage(resource: .city)
    var body: some View {
        VStack {
            Text("Object Detection")
                .font(.title)
                .padding()
            
            // Displaying the image with detected bounding boxes
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .overlay(
                    GeometryReader { geo in
                        ForEach(detectedObjects, id: \.self) { object in
                            let boundingBox = object.boundingBox
                            let rect =  convertBoundingBox(boundingBox, in: geo.frame(in: .global).size)
                            
                            // Drawing the bounding box as a red rectangle
                            Rectangle()
                                .stroke(Color.red, lineWidth: 2)
                                .frame(width: rect.width, height: rect.height)
                                .position(x: rect.midX, y: rect.midY)
                            
                            // Optional: Displaying label and confidence
                            if let label = object.labels.first {
                                Text("\(label.identifier) \(String(format: "%.2f", label.confidence))")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.7))
                                    .position(x: rect.midX, y: rect.minY - 10)
                            }
                        }
                    }
                )
                .task {
                    Task {
                        performObjectDetection(image:image)
                    }
                }

        }
        
        
       
    }
    
    func performObjectDetection(image: NSImage) {
        
        
        guard let cgImage = image.CGImage else { return }
        
        // Load the Core ML YOLO model
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndGPU
        guard let model = try? VNCoreMLModel(for: yolo11m_int8(configuration: config).model) else {
            fatalError("Failed to load YOLO model")
        }
        
        // Create a Vision request for object detection
        let request = VNCoreMLRequest(model: model) { request, error in
            if let results = request.results as? [VNRecognizedObjectObservation] {
                DispatchQueue.main.async {
                    detectedObjects = results
                }
            }
        }
        
        // Create an image request handler
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
    
    func convertBoundingBox(_ boundingBox: CGRect, in size: CGSize) -> CGRect {
        // Convert the bounding box from normalized coordinates to view coordinates
        let width = boundingBox.width * size.width
        let height = boundingBox.height * size.height
        let originX = boundingBox.minX * size.width
        let originY = (1 - boundingBox.maxY) * size.height  // Invert Y-axis for Vision
        return CGRect(x: originX, y: originY, width: width, height: height)
    }
}

#Preview {
    ObjectDetectionView()
}
