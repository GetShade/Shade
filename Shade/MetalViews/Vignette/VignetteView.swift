//
//  VignetteView.swift
//  Shade
//
//  Created by Ahmed Ragab on 06/10/2024.
//

import Foundation
import SwiftUI
import MetalKit

struct VignetteViewMetalView : NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
         Coordinator(self)
    }
    
    var image: NSImage
    var radius: Float
    var softness: Float
    
    func makeNSView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.delegate = context.coordinator
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
//        mtkView.autoResizeDrawable = true
        return mtkView
    }
    
    func updateNSView(_ uiView: MTKView, context: Context) {
        context.coordinator.updateVignette(radius: radius, softness: softness)
        uiView.setNeedsDisplay(uiView.frame)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        func draw(in view: MTKView) {
            renderer.draw(in: view)
        }
        
        func updateVignette(radius: Float, softness: Float) {
            renderer.radius = radius
            renderer.softness = softness
        }
        
        var parent: VignetteViewMetalView
        var renderer: VignetteMetalRenderer
        
        init(_ parent: VignetteViewMetalView) {
            self.parent = parent
            let device = MTLCreateSystemDefaultDevice()!
            self.renderer =  VignetteMetalRenderer(device: device, image: parent.image)
        }
    }
}


struct VignetteView: View {
    // State properties for radius and softness
    @State private var radius: Float = 0.5 // Default value
    @State private var softness: Float = 0.5 // Default value

    var body: some View {
        VStack {
            // Vignette view with the image and the effect applied
            VignetteViewMetalView(image: NSImage(resource: .person2),
                                  radius: radius,
                                  softness: softness)
                .frame(width: 300, height: 300)
//                .border(Color.black, width: 1)

            // Sliders for adjusting radius and softness
            VStack {
                Text("Radius: \(String(format: "%.2f", radius))")
                    .padding(.top)

                Slider(value: $radius, in: 0...1, step: 0.01) // Adjust range as needed
                    .padding()

                Text("Softness: \(String(format: "%.2f", softness))")
                    .padding(.top)

                Slider(value: $softness, in: 0...1, step: 0.01) // Adjust range as needed
                    .padding()
            }
            .padding(.top)
        }
        .padding()
    }
}

#Preview {
    VignetteView()
}
