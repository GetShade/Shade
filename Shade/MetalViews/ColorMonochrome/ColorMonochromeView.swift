//
//  ColorMonochromeView.swift
//  Shade
//
//  Created by Ahmed Ragab on 06/10/2024.
//

import Foundation
import SwiftUI
import MetalKit

struct ColorMonochromeMetalView: NSViewRepresentable {
    var image: NSImage
    var color: Color
    var intensity: Float
    
    func makeNSView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.delegate = context.coordinator.renderer
        mtkView.autoResizeDrawable = true
        return mtkView
    }
    
    func updateNSView(_ uiView: MTKView, context: Context) {
        context.coordinator.updateColor(color: color, intensity: intensity)
        uiView.setNeedsDisplay(uiView.frame)
    }
    
    func makeCoordinator() -> Coordinator {
         Coordinator(self)
    }
    
    class Coordinator: NSObject {
        
        func draw(in view: MTKView) {
            renderer.draw(in: view)
        }
        
        func updateColor(color: Color, intensity: Float) {
            renderer.intensity = intensity
            renderer.color = color.toSimdFloat4()
        }
        
        var parent: ColorMonochromeMetalView
        var renderer: ColorMonochromeMetalRenderer
        
        init(_ parent: ColorMonochromeMetalView) {
            self.parent = parent
            let device = MTLCreateSystemDefaultDevice()!
            self.renderer =  ColorMonochromeMetalRenderer(device: device, image: parent.image)
        }
    }
}



struct ColorMonochromeView: View {
    @State private var color: Color = .red
    @State private var intensity: Float = 0.5
    var image = NSImage(resource: .person)
    var body: some View {
        VStack {
            ColorMonochromeMetalView(image:image, color: color, intensity: intensity)
                .frame(width: 300, height: 300)
                
            
            // Add controls to change color and intensity
            HStack {
                
                ColorPicker("Select Color", selection: $color)
                
                Slider(value: $intensity, in: 0...1, label: {
                    Text("Intensity")
                })
            }
            .padding()
        }
    }
}



#Preview {
    ColorMonochromeView()
}
