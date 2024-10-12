//
//  BumpTouchEffect.swift
//  Shade
//
//  Created by Ahmed Ragab on 12/10/2024.
//

import Foundation
import MetalKit
import SwiftUI

class BumpTouchEffectMetalRenderer: NSObject,MTKViewDelegate {
    
    
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var texture: MTLTexture?
    
    
    
    var touchLocation = SIMD2<Float>(0, 0)
    var radius: Float = 2.0
    var scale: Float = 0.25
    
    
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
        let vertexFunction = library.makeFunction(name: "bumpEffectVertexShader")
        let fragmentFunction = library.makeFunction(name: "bumpEffectFragment")
        
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
        
        var bumpCenter = SIMD2<Float>(Float(touchLocation.x / Float(view.bounds.width)), Float(1.0 - touchLocation.y / Float(view.bounds.height)))
        var radius = Float(radius / Float(view.bounds.width))
        
        
        
        renderEncoder.setFragmentBytes(&bumpCenter, length: MemoryLayout<SIMD2<Float>>.size, index: 0)
        renderEncoder.setFragmentBytes(&radius, length: MemoryLayout<Float>.size, index: 1)
        renderEncoder.setFragmentBytes(&scale, length: MemoryLayout<Float>.size, index: 2)
        
        
        
        
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


struct BumpTouchEffectMetalView: NSViewRepresentable {
    var image: NSImage
    @Binding var touchLocation: CGPoint
    var radius: Float = 100.0
    var scale: Float = 0.2
    
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
        context.coordinator.renderer.scale = scale
        context.coordinator.renderer.touchLocation = updateTouchLocation($touchLocation.wrappedValue)
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
        
        var parent: BumpTouchEffectMetalView
        var renderer: BumpTouchEffectMetalRenderer
        
        init(_ parent: BumpTouchEffectMetalView) {
            self.parent = parent
            let device = MTLCreateSystemDefaultDevice()!
            self.renderer =  BumpTouchEffectMetalRenderer(device: device, image: parent.image)
        }
    }
}


struct BumpTouchEffectView: View {
    @State private var touchLocation: CGPoint = .zero
    @State private var radius: Float = 100.0
    @State private var scale: Float = 0.2
    var image = NSImage(resource: .person)
    var body: some View {
        VStack {
            BumpTouchEffectMetalView (
                image: image,
                touchLocation: $touchLocation,
                radius: radius,
                scale: scale)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    touchLocation = value.location
                })
            
            
            Text("Radius: \(Int(radius))")
            Slider(value: $radius, in: 50...200)
            
            Text("Scale: \(scale, specifier: "%.2f")")
            Slider(value: $scale, in: 0.1...0.5)
        }
        .padding()
    }
}
#Preview  {
    BumpTouchEffectView()
        .padding()
}


