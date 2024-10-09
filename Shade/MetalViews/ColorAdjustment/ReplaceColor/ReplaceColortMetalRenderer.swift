//
//  ReplaceColortMetalRenderer.swift
//  Shade
//
//  Created by Ahmed Ragab on 06/10/2024.
//

import Foundation
import MetalKit
import SwiftUI

class ReplaceColortMetalRenderer: NSObject, MTKViewDelegate {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var texture: MTLTexture?
    var samplerState: MTLSamplerState!
    
    var targetColor =  SIMD4<Float>(0.0,0.0,0.0,0.0)
    var replacmentColor =  SIMD4<Float>(1.0, 1.0, 1.0, 1.0)
    
    init(device: MTLDevice, image: NSImage) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        super.init()
        setupPipeline()
        setupVertexBuffer()
        setupsamplerDescriptor()
        loadImageAsTexture(image: image)
    }
    
    private func loadImageAsTexture(image: NSImage) {
        let textureLoader = MTKTextureLoader(device: device)
        if let cgImage = image.CGImage {
            texture = try? textureLoader.newTexture(cgImage: cgImage, options: nil)
        }
    }
    
    private func setupsamplerDescriptor() {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .nearest
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
    }
    
    private func setupVertexBuffer() {
        let quadVertices: [Vertex] = [
            Vertex(position: [-1.0, -1.0], textureCoordinate: [0.0, 1.0]),
            Vertex(position: [ 1.0, -1.0], textureCoordinate: [1.0, 1.0]),
            Vertex(position: [-1.0,  1.0], textureCoordinate: [0.0, 0.0]),
            Vertex(position: [ 1.0,  1.0], textureCoordinate: [1.0, 0.0])
        ]
        
        vertexBuffer = device.makeBuffer(bytes: quadVertices,
                                         length: MemoryLayout<Vertex>.stride * quadVertices.count,
                                         options: [])
    }
    
    func setupPipeline() {
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "colorReplaceVertexShader")
        let fragmentFunction = library.makeFunction(name: "colorReplaceFragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        let vertexDescriptor = MTLVertexDescriptor()
        
        vertexDescriptor.attributes[0].format = .float2 // Position
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float2 // Texture Coordinates
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        // Create pipeline state
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle window resize if needed
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let rendererPassDescriptor = view.currentRenderPassDescriptor,
              let texture = texture else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rendererPassDescriptor)!
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)

//        renderEncoder.setFragmentTexture(drawable.texture, index: 1)
        
        renderEncoder.setFragmentBytes(&targetColor, length: MemoryLayout<SIMD4<Float>>.stride, index: 1)
        renderEncoder.setFragmentBytes(&replacmentColor, length: MemoryLayout<SIMD4<Float>>.stride, index: 2)
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
