//
//  kaleidoscopeMetalRenderer.swift
//  Shade
//
//  Created by Ahmed Ragab on 13/10/2024.
//

import Foundation
import SwiftUI
import MetalKit

class kaleidoscopeMetalRenderer: NSObject,MTKViewDelegate {
    
    
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var texture: MTLTexture?
    
    
    
    var touchLocation = SIMD2<Float>(0, 0)
    var count: Int = 6
    var angle: Float = 0.0
    var radius: Float = 0.0

    
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
        let vertexFunction = library.makeFunction(name: "kaleidoscopeVertexShader")
        let fragmentFunction = library.makeFunction(name: "kaleidoscopeFragment")
        
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
       


        var center = SIMD2<Float>(Float(touchLocation.x / Float(view.bounds.width)), Float(1.0 - touchLocation.y / Float(view.bounds.height)))
             renderEncoder.setFragmentBytes(&center, length: MemoryLayout<SIMD2<Float>>.stride, index: 0)
             renderEncoder.setFragmentBytes(&angle, length: MemoryLayout<Float>.stride, index: 1)
             renderEncoder.setFragmentBytes(&count, length: MemoryLayout<Int>.stride, index: 2)
            renderEncoder.setFragmentBytes(&radius, length: MemoryLayout<Float>.size, index: 3)

                
        
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


struct kaleidoscopeMetalView: NSViewRepresentable {
    var image: NSImage
    @Binding var touchLocation: CGPoint
    var angle: Float = 0.0 // Loupe radius (in normalized UV space)
    var count: Int = 0
    var radius: Float = 0.5

    func makeNSView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.delegate = context.coordinator.renderer
        mtkView.preferredFramesPerSecond = 60

        mtkView.autoResizeDrawable = true
        return mtkView
    }
    
    func updateNSView(_ uiView: MTKView, context: Context) {
        context.coordinator.renderer.angle = angle
        context.coordinator.renderer.count = count
        context.coordinator.renderer.radius = radius
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
        
        var parent: kaleidoscopeMetalView
        var renderer: kaleidoscopeMetalRenderer
        
        init(_ parent: kaleidoscopeMetalView) {
            self.parent = parent
            let device = MTLCreateSystemDefaultDevice()!
            self.renderer =  kaleidoscopeMetalRenderer(device: device, image: parent.image)
        }
    }
}

struct kaleidoscopeView: View {
    @State private var count: Int = 6
    @State private var angle: Float = 0.0
    @State private var center: CGPoint = CGPoint(x: 0.5, y: 0.5)
    @State private var radius: Float = 0.5

    var body: some View {
        VStack {
            kaleidoscopeMetalView(
                image: NSImage(resource: .person), touchLocation: $center,
                angle: angle,
                count: count,
                radius: radius
            )
            .frame(width: 300, height: 300)
                      .gesture(
                          DragGesture()
                              .onChanged { value in
                                  // Update center of the kaleidoscope effect based on drag location
//                                  let x = Float(value.location.x / 300)
//                                  let y = Float(value.location.y / 300)
                                  center = value.location
//                                  CGPoint(x: CGFloat(x), y: CGFloat(y))
                              }
                      )

                      HStack {
                          Text("Slices Count")
                          Slider(value: Binding(
                              get: { Double(count) },
                              set: { count = Int($0) }
                          ), in: 3...12, step: 1)
                      }
                      .padding()

                      HStack {
                          Text("Angle")
                          Slider(value: $angle, in: 0.0...Float.pi)
                      }
                      .padding()

                      HStack {
                          Text("Radius")
                          Slider(value: $radius, in: 0.0...1.0)
                      }
                      .padding()
                  }
              }
          }
#Preview {
    kaleidoscopeView()
}
