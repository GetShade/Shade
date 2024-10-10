//
//  ReplaceColorView.swift
//  Shade
//
//  Created by Ahmed Ragab on 06/10/2024.
//

import Foundation
import SwiftUI
import MetalKit

struct ReplaceColorMetalView: NSViewRepresentable {
    
    var image: NSImage
    var replacmentColor: Color
    var targetColor: Color
    
    func makeNSView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.delegate = context.coordinator.renderer
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        mtkView.autoResizeDrawable = true
        return mtkView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func updateNSView(_ mtkView: MTKView, context: Context) {
        context.coordinator.updateColors(targetColor: targetColor, replacmentColor: replacmentColor)
        mtkView.setNeedsDisplay(mtkView.frame)
    }
    
    class Coordinator: NSObject {
        var parent: ReplaceColorMetalView
        var renderer: ReplaceColortMetalRenderer
        
        init(_ parent: ReplaceColorMetalView) {
            self.parent = parent
            let device = MTLCreateSystemDefaultDevice()!
            self.renderer = ReplaceColortMetalRenderer(device: device, image: parent.image)
        }
        
        func updateColors(targetColor: Color, replacmentColor: Color) {
            renderer.replacmentColor =  replacmentColor.toSimdFloat4()
            renderer.targetColor = targetColor.toSimdFloat4()
        }
        
        func draw(in view: MTKView) {
            renderer.draw(in: view)
        }
    }
    
}



struct ReplaceColorView: View {
    @State var targetColor = Color.red // Target color to replace
    
    @State  var replacementColor = Color.blue
    
    private let image = NSImage(resource: .person1)
    
    var body: some View {
        VStack {
            ReplaceColorMetalView(image:image,
                                  replacmentColor: replacementColor,
                                  targetColor: targetColor)
            
            ColorPicker("target Color", selection: $targetColor)
            ColorPicker("replacment Color", selection: $replacementColor)
        }
    }
}
#Preview {
    ReplaceColorView()
}

 
