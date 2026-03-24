//
//  ColorControlMetalRenderer.swift
//  Shade
//
//  Created by Ahmed Ragab on 13/10/2024.
//

import Foundation
import MetalKit
import SwiftUI

class ColorControlMetalRenderer: NSObject,MTKViewDelegate {
    
    
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var texture: MTLTexture?
    var samplerState: MTLSamplerState!

    var saturation: Float  = 0.0
    var contrast: Float = 0.0
    var brightness: Float = 0.0
    
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
        let vertexFunction = library.makeFunction(name: "colorControlsVertexShader")
        let fragmentFunction = library.makeFunction(name: "colorControlsFragment")
        
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
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
    }
    
    func draw(in view: MTKView) {
        
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let texture = texture else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setFragmentTexture(texture, index: 0)
        
        
        var adjustments = SIMD3<Float>(saturation, contrast, brightness)

        renderEncoder.setFragmentBytes(&adjustments, length: MemoryLayout<SIMD3<Float>>.size, index: 0)

        

                
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
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


struct ColorControlMetalView: NSViewRepresentable {
    var image: NSImage
    var saturation: Float
    var contrast: Float
    var brightness: Float
    
    func makeNSView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.delegate = context.coordinator.renderer
        mtkView.preferredFramesPerSecond = 60

        mtkView.autoResizeDrawable = true
        return mtkView
    }
    
    func updateNSView(_ uiView: MTKView, context: Context) {
        context.coordinator.renderer.brightness = brightness
        context.coordinator.renderer.saturation = saturation
        context.coordinator.renderer.contrast = contrast
        
        
        uiView.setNeedsDisplay(uiView.frame)
    }
    
    
    func makeCoordinator() -> Coordinator {
         Coordinator(self)
    }
    
    class Coordinator: NSObject {
        
        func draw(in view: MTKView) {
            renderer.draw(in: view)
        }
        
        var parent: ColorControlMetalView
        var renderer: ColorControlMetalRenderer
        
        init(_ parent: ColorControlMetalView) {
            self.parent = parent
            let device = MTLCreateSystemDefaultDevice()!
            self.renderer =  ColorControlMetalRenderer(device: device, image: parent.image)
        }
    }
}



struct ColorControlView: View {
    var image = NSImage(resource: .person)
    @State private var saturation: Float = 1.0 // Saturation (1.0 = 100%)
    @State private var contrast: Float = 1.0 // Contrast (1.0 = 100%)
    @State private var brightness: Float = 1.0 // Brightness (1.0 = 100%)
    
    var body: some View {
          VStack {
              ColorControlMetalView(image:image,saturation: saturation, contrast: contrast, brightness: brightness)
                  .frame(width: 300, height: 300)

              Slider(value: $saturation, in: -1...2, step: 0.1, label: {
                  Text("Saturation: \(Int(saturation * 100))%")
              })
              Slider(value: $contrast, in: 0...2, step: 0.1, label: {
                  Text("Contrast: \(Int(contrast * 100))%")
              })
              Slider(value: $brightness, in: 0...2, step: 0.1, label: {
                  Text("Brightness: \(Int(brightness * 100))%")
              })
          }
      }
  }
#Preview  {
    ColorControlView()
}



