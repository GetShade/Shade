//
//  ChannelMixerView.swift
//  Shade
//
//  Created by Ahmed Ragab on 06/10/2024.
//

import Foundation
import SwiftUI
import MetalKit

struct ChannelMixerMetalView: NSViewRepresentable {
    var image: NSImage
    var redMix: SIMD3<Float>
    var greenMix: SIMD3<Float>
    var blueMix: SIMD3<Float>
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.delegate = context.coordinator
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        mtkView.autoResizeDrawable = true
        return mtkView
    }

    func updateNSView(_ mtkView: MTKView, context: Context) {
        context.coordinator.updateMixers(red: redMix, green: greenMix, blue: blueMix)
        mtkView.setNeedsDisplay(mtkView.frame)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var parent: ChannelMixerMetalView
        var renderer: ChannelMixerMetalRenderer
        
        init(_ parent: ChannelMixerMetalView) {
            self.parent = parent
            let device = MTLCreateSystemDefaultDevice()!
            self.renderer = ChannelMixerMetalRenderer(device: device, image: parent.image)
        }
        
        func updateMixers(red: SIMD3<Float>, green: SIMD3<Float>, blue: SIMD3<Float>) {
            renderer.redMix = red
            renderer.greenMix = green
            renderer.blueMix = blue
        }

        func draw(in view: MTKView) {
            renderer.draw(in: view)
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    }
}



struct ChannelMixerView: View {
    @State private var redMix = SIMD3<Float>(1.0, 0.0, 0.0)
    @State private var greenMix = SIMD3<Float>(0.0, 1.0, 0.0)
    @State private var blueMix = SIMD3<Float>(0.0, 0.0, 1.0)
    
    var body: some View {
        VStack {
            ChannelMixerMetalView(image: NSImage(named: "city")!,
                      redMix: redMix, greenMix: greenMix, blueMix: blueMix)
            .frame(height: 300)
            
            VStack {
                Slider(value: $redMix.x, in: 0...1, label: { Text("Red Mix") })
                Slider(value: $greenMix.y, in: 0...1, label: { Text("Green Mix") })
                Slider(value: $blueMix.z, in: 0...1, label: { Text("Blue Mix") })
            }.padding()
        }
    }
}

#Preview {
    ChannelMixerView()
}
//
////
////  sharpenAndContrast.metal
////  Shade
////
////  Created by Ahmed Ragab on 06/10/2024.
////
//
//#include <metal_stdlib>
//using namespace metal;
//
//
//// Sharpening kernel
//constant float kernelValues[3][3] = {
//    {0.0, -1.0, 0.0},
//    {-1.0, 5.0, -1.0},
//    {0.0, -1.0, 0.0}
//};
//
//struct VertexOut {
//    float4 postion [[position]];
//    float2 textureCoordinate;
//};
//
//struct VertexIn {
//    float4 position [[attribute(0)]];
//    float2 textureCoordinate [[attribute(1)]];
//};
//
//fragment float4 sharpenLuminance(VertexIn in [[stage_in]],
//                                  texture2d<float> inputTexture [[texture(0)]],
//                                  sampler inputSampler [[sampler(0)]],
//                                  constant float& strength [[buffer(1)]]) {
//     // Get texture coordinates
//     float2 texCoords = in.textureCoordinate;
//     
//     // Get the texture size
//     float2 texSize = float2(inputTexture.get_width(), inputTexture.get_height());
//     
//     float4 color = float4(0.0);
//     
//     // Apply the sharpening kernel
//     for (int y = -1; y <= 1; y++) {
//         for (int x = -1; x <= 1; x++) {
//             float2 offset = float2(x, y) / texSize; // Normalized offset
//             float4 sampleColor = inputTexture.sample(inputSampler, texCoords + offset);
//             color += sampleColor * kernelValues[y + 1][x + 1];
//         }
//     }
//
//     // Multiply by strength to control sharpening effect
//     return color * strength;
// }
