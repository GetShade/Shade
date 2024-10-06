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

