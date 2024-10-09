//
//  GrainView.swift
//  Shade
//
//  Created by Ahmed Ragab on 06/10/2024.
//

import Foundation
import MetalKit
import SwiftUI

struct GrainMetalView: NSViewRepresentable {
    var image: NSImage
    var grainIntensity: Float
    
    
    func makeNSView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.delegate = context.coordinator.renderer
        mtkView.autoResizeDrawable = true
        return mtkView
    }
    
    func updateNSView(_ uiView: MTKView, context: Context) {
        context.coordinator.updateGrain(grainIntensity: grainIntensity)
        uiView.setNeedsDisplay(uiView.frame)
    }
    
    func makeCoordinator() -> Coordinator {
         Coordinator(self)
    }
    
    class Coordinator: NSObject {
        
        func draw(in view: MTKView) {
            renderer.draw(in: view)
        }
        
        func updateGrain(grainIntensity: Float) {
            renderer.grainIntensity = grainIntensity
        }
        
        var parent: GrainMetalView
        var renderer: GrainMetalRenderer
        
        init(_ parent: GrainMetalView) {
            self.parent = parent
            let device = MTLCreateSystemDefaultDevice()!
            self.renderer =  GrainMetalRenderer(device: device, image: parent.image)
        }
    }
}

struct GrainEffectView: View {
    @State private var grainIntensity: Float = 0.5 // Adjust grain intensity
    var image = NSImage(resource: .person)
    var body: some View {
        VStack {
            GrainMetalView(image: image,
                           grainIntensity: grainIntensity)
                .frame(width: 300, height: 300)
                .cornerRadius(12)
            
            Slider(value: $grainIntensity, in: 0.0...1.0, step: 0.01) {
                Text("Grain Intensity")
            }
            .padding()
        }
    }
}


#Preview {
    GrainEffectView()
}
