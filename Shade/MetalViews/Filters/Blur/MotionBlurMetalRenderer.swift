//
//  MotionBlurMetalRenderer.swift
//  Shade
//
//  Created by Ahmed Ragab on 12/10/2024.
//

import Foundation
import MetalKit
import SwiftUI

class MotionBlurMetalRenderer: NSObject,MTKViewDelegate {
    
    
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var texture: MTLTexture?
    
    
    
    
    var radius: Float = 0.5
    var blurAngle: Float = 45.0
    
    
    init(device: MTLDevice, image: NSImage) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        super.init()
        setupPipeline()
        setupVertexBuffer()
        loadImageAsTexture(image: image)
    }
    
    private func setupVertexBuffer() {
        let quadVertices: [Vertex] = [
            Vertex(position: [-1.0, -1.0], textureCoordinate: [0.0, 1.0]), // Bottom-left
            Vertex(position: [ 1.0, -1.0], textureCoordinate: [1.0, 1.0]), // Bottom-right
            Vertex(position: [-1.0,  1.0], textureCoordinate: [0.0, 0.0]), // Top-left
            
            // Second triangle
            Vertex(position: [-1.0,  1.0], textureCoordinate: [0.0, 0.0]), // Top-left (repeated)
            Vertex(position: [ 1.0, -1.0], textureCoordinate: [1.0, 1.0]), // Bottom-right (repeated)
            Vertex(position: [ 1.0,  1.0], textureCoordinate: [1.0, 0.0])
        ]
        
        vertexBuffer = device.makeBuffer(bytes: quadVertices,
                                         length: MemoryLayout<Vertex>.stride * quadVertices.count,
                                         options: [])
    }
    
    func setupPipeline() {
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "motionBlurVertexShader")
        let fragmentFunction = library.makeFunction(name: "motionBlurFragment")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        //         Define the vertex descriptor to describe vertex attributes
        let vertexDescriptor = MTLVertexDescriptor()
        
        vertexDescriptor.attributes[0].format = .float3 // Position
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float3 // Texture Coordinates
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func draw(in view: MTKView) {
        
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let texture = texture else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setFragmentTexture(texture, index: 0)
        

        
        
        renderEncoder.setFragmentBytes(&radius, length: MemoryLayout<SIMD2<Float>>.size, index: 0)
        renderEncoder.setFragmentBytes(&blurAngle, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        
        
        renderEncoder.setFragmentTexture(texture, index: 0)
        
        
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Draw the quad
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    
    private func loadImageAsTexture(image: NSImage) {
        let textureLoader = MTKTextureLoader(device: device)
        if let cgImage = image.CGImage {
            texture = try? textureLoader.newTexture(cgImage: cgImage, options: nil)
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}


struct MotionBlurMetalView: NSViewRepresentable {
    var image: NSImage
    var radius: Float = 0.5
    var blurAngle: Float = 45.0
    
    func makeNSView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.delegate = context.coordinator.renderer
        mtkView.preferredFramesPerSecond = 60
        
        mtkView.autoResizeDrawable = true
        return mtkView
    }
    
    func updateNSView(_ uiView: MTKView, context: Context) {
        context.coordinator.renderer.radius = radius
        context.coordinator.renderer.blurAngle = blurAngle
        uiView.setNeedsDisplay(uiView.frame)
    }
    func updateTouchLocation(_ location: CGPoint) -> SIMD2<Float> {
        return  SIMD2<Float>(Float(location.x), Float(location.y))
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        
        func draw(in view: MTKView) {
            renderer.draw(in: view)
        }
        
        var parent: MotionBlurMetalView
        var renderer: MotionBlurMetalRenderer
        
        init(_ parent: MotionBlurMetalView) {
            self.parent = parent
            let device = MTLCreateSystemDefaultDevice()!
            self.renderer =  MotionBlurMetalRenderer(device: device, image: parent.image)
        }
    }
}

struct MotionBlurView: View {
    var image: NSImage = NSImage(resource: .person2)
     @State private var blurRadius: Float = 5.0
     @State private var blurAngle: Float = 45.0
     
     var body: some View {
         VStack {
             MotionBlurMetalView(image: image, radius: blurRadius, blurAngle: blurAngle)
                 .frame(width: 300, height: 300)
             
             VStack {
                 Text("Blur Radius")
                 Slider(value: $blurRadius, in: 1...20)
                     .padding()
                 Text("Blur Angle")
                 Slider(value: $blurAngle, in: 0...360)
                     .padding()
             }
         }
     }
}

#Preview {
    MotionBlurView()
}
