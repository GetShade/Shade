//
//  WrapingLoupeMetalRenderer.swift
//  Shade
//
//  Created by Ahmed Ragab on 12/10/2024.
//

import Foundation
import SwiftUI
import MetalKit

class WarpingLoupeMetalRenderer: NSObject,MTKViewDelegate {
    
    
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var texture: MTLTexture?
    
    
    
    var touchLocation = SIMD2<Float>(0, 0)
     var zoomFactor: Float = 2.0
     var maxDistance: Float = 0.25
    
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
        let vertexFunction = library.makeFunction(name: "warpingLoupeVertexShader")
        let fragmentFunction = library.makeFunction(name: "warpingLoupe")
        
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
       
        var size = SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height))

        
        renderEncoder.setFragmentBytes(&size, length: MemoryLayout<SIMD2<Float>>.stride, index: 0)
             renderEncoder.setFragmentBytes(&touchLocation, length: MemoryLayout<SIMD2<Float>>.stride, index: 1)
             renderEncoder.setFragmentBytes(&maxDistance, length: MemoryLayout<Float>.stride, index: 2)
             renderEncoder.setFragmentBytes(&zoomFactor, length: MemoryLayout<Float>.stride, index: 3)
                
        
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


struct WarpingLoupeMetalView: NSViewRepresentable {
     var image: NSImage
     @Binding var touchLocation: CGPoint
      var maxDistance: Float = 0.25 // Loupe radius (in normalized UV space)
       var zoomFactor: Float = 2.0
    
    func makeNSView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.delegate = context.coordinator.renderer
        mtkView.preferredFramesPerSecond = 60

        mtkView.autoResizeDrawable = true
        return mtkView
    }
    
    func updateNSView(_ uiView: MTKView, context: Context) {
        context.coordinator.renderer.maxDistance = maxDistance
        context.coordinator.renderer.zoomFactor = zoomFactor
        
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
        
        var parent: WarpingLoupeMetalView
        var renderer: WarpingLoupeMetalRenderer
        
        init(_ parent: WarpingLoupeMetalView) {
            self.parent = parent
            let device = MTLCreateSystemDefaultDevice()!
            self.renderer =  WarpingLoupeMetalRenderer(device: device, image: parent.image)
        }
    }
}

struct WarpingLoupeView: View {
    @State private var touchLocation: CGPoint = .zero
       @State private var maxDistance: Float = 0.25 // Loupe radius (in normalized UV space)
       @State private var zoomFactor: Float = 0.5   // Zoom factor
    var image = NSImage(resource: .person)
    var body: some View {
        VStack {
         

            WarpingLoupeMetalView(image: image, touchLocation: $touchLocation,maxDistance: maxDistance,zoomFactor: zoomFactor)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Convert touch location to Metal view coordinates
                            touchLocation = value.location
                        }
                )
                .aspectRatio(contentMode: .fit)
            
            Slider(value: $zoomFactor, in: 0.5...5.0) {
                Text("Zoom Factor")
            }.padding()

            Slider(value: $maxDistance, in: 0.1...0.5) {
                Text("Loupe Radius")
            }.padding()
        }
    }
}

#Preview {
    WarpingLoupeView()
}
