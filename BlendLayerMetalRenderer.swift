import MetalKit
import SwiftUI

class BlendLayerMetalRenderer: NSObject, MTKViewDelegate {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var baseTexture: MTLTexture?
    private var blendTexture: MTLTexture?
    private var samplerState: MTLSamplerState!

    var blendMode: CustomBlendMode = .normal

    init(device: MTLDevice, baseImage: NSImage, blendImage: NSImage) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        super.init()
        setupPipeline()
        setupVertexBuffer()
        setupSamplerState()
        loadTextures(baseImage: baseImage, blendImage: blendImage)
    }

    private func setupPipeline() {
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "blendFragmentShader")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    private func setupVertexBuffer() {
        let vertices: [Vertex] = [
            Vertex(position: SIMD2<Float>(-1, -1), textureCoordinate: SIMD2<Float>(0, 1)),
            Vertex(position: SIMD2<Float>(1, -1), textureCoordinate: SIMD2<Float>(1, 1)),
            Vertex(position: SIMD2<Float>(-1, 1), textureCoordinate: SIMD2<Float>(0, 0)),
            Vertex(position: SIMD2<Float>(1, 1), textureCoordinate: SIMD2<Float>(1, 0))
        ]

        vertexBuffer = device.makeBuffer(bytes: vertices,
                                       length: vertices.count * MemoryLayout<Vertex>.stride,
                                       options: [])
    }

    private func setupSamplerState() {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
    }

    private func loadTextures(baseImage: NSImage, blendImage: NSImage) {
        let textureLoader = MTKTextureLoader(device: device)

        if let cgImage = baseImage.CGImage {
            baseTexture = try? textureLoader.newTexture(cgImage: cgImage, options: nil)
        }

        if let cgImage = blendImage.CGImage {
            blendTexture = try? textureLoader.newTexture(cgImage: cgImage, options: nil)
        }
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }

        let commandBuffer = commandQueue.makeCommandBuffer()
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)

        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder?.setFragmentTexture(baseTexture, index: 0)
        renderEncoder?.setFragmentTexture(blendTexture, index: 1)
        renderEncoder?.setFragmentSamplerState(samplerState, index: 0)

        // Set blend mode uniform
        var blendModeInt = Int32(blendMode.rawValue)
        renderEncoder?.setFragmentBytes(&blendModeInt, length: MemoryLayout<Int32>.size, index: 0)

        renderEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder?.endEncoding()

        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
