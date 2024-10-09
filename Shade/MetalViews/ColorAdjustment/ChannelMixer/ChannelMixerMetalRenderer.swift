//
//  ChannelMixerMetalRenderer.swift
//  Shade
//
//  Created by Ahmed Ragab on 06/10/2024.
//
//

import MetalKit
import SwiftUI
struct Vertex {
    var position: SIMD2<Float>
    var textureCoordinate: SIMD2<Float>
}

class ChannelMixerMetalRenderer: NSObject, MTKViewDelegate {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var texture: MTLTexture?

    var redMix = SIMD3<Float>(1.0, 0.0, 0.0)
    var greenMix = SIMD3<Float>(0.0, 1.0, 0.0)
    var blueMix = SIMD3<Float>(0.0, 0.0, 1.0)

    init(device: MTLDevice, image: NSImage) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        super.init()
        setupPipeline()
        setupVertexBuffer()
        loadImageAsTexture(image: image)
    }

    // Load image and create Metal texture from UIImage
    private func loadImageAsTexture(image: NSImage) {
        let textureLoader = MTKTextureLoader(device: device)
        if let cgImage = image.CGImage {
            texture = try? textureLoader.newTexture(cgImage: cgImage, options: nil)
        }
    }

    // Setup vertex buffer with full-screen quad vertices
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

    // Setup pipeline, including vertex and fragment shaders
    private func setupPipeline() {
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "channelMixerVertexShader")
        let fragmentFunction = library.makeFunction(name: "channelMixerFragment")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Define the vertex descriptor to describe vertex attributes
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

    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle window resize if needed
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let texture = texture else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        // Set the pipeline state
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Set vertex buffer
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Set texture and channel mixer values in the fragment shader
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setFragmentBytes(&redMix, length: MemoryLayout<SIMD3<Float>>.stride, index: 0)
        renderEncoder.setFragmentBytes(&greenMix, length: MemoryLayout<SIMD3<Float>>.stride, index: 1)
        renderEncoder.setFragmentBytes(&blueMix, length: MemoryLayout<SIMD3<Float>>.stride, index: 2)
        
        // Draw the full-screen quad (4 vertices)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

extension NSImage {
    var CGImage: CGImage? {
        get {
            let imageData = self.tiffRepresentation
            let source = CGImageSourceCreateWithData(imageData! as CFData, nil).unsafelyUnwrapped
            let maskRef = CGImageSourceCreateImageAtIndex(source, Int(0), nil)
            return maskRef.unsafelyUnwrapped
        }
    }
}
extension NSImage {
    /// Generates a CIImage for this NSImage.
    /// - Returns: A CIImage optional.
    func ciImage() -> CIImage? {
        guard let data = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data) else {
            return nil
        }
        let ci = CIImage(bitmapImageRep: bitmap)
        return ci
    }
    
    /// Generates an NSImage from a CIImage.
    /// - Parameter ciImage: The CIImage
    /// - Returns: An NSImage optional.
    static func fromCIImage(_ ciImage: CIImage) -> NSImage {
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
}
