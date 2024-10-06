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
    var replacmentColor: NSColor
    var targetColor: NSColor
    
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
        
        func updateColors(targetColor: NSColor, replacmentColor: NSColor) {
            renderer.replacmentColor =  replacmentColor.float4
            renderer.targetColor = targetColor.float4
        }
        
        func draw(in view: MTKView) {
            renderer.draw(in: view)
        }
    }
    
}



struct ReplaceColorView: View {
    private let targetColor = NSColor.red // Target color to replace
    
    private let replacementColor = NSColor(hex:"#083D6B") // Replacement color
    
    private let image = NSImage(resource: .person1)
    
    var body: some View {
        ReplaceColorMetalView(image:image,
                              replacmentColor: targetColor,
                              targetColor: replacementColor)
    }
}
#Preview {
    ReplaceColorView()
}
extension NSColor {
    var float4: SIMD4<Float> {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return SIMD4<Float>(Float(red), Float(green), Float(blue), Float(alpha))
    }
}

extension NSColor {
    
 convenience init(hex: String) {
    let trimHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    let dropHash = String(trimHex.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
    let hexString = trimHex.starts(with: "#") ? dropHash : trimHex
    let ui64 = UInt64(hexString, radix: 16)
    let value = ui64 != nil ? Int(ui64!) : 0
    // #RRGGBB
    var components = (
        R: CGFloat((value >> 16) & 0xff) / 255,
        G: CGFloat((value >> 08) & 0xff) / 255,
        B: CGFloat((value >> 00) & 0xff) / 255,
        a: CGFloat(1)
    )
    if String(hexString).count == 8 {
        // #RRGGBBAA
        components = (
            R: CGFloat((value >> 24) & 0xff) / 255,
            G: CGFloat((value >> 16) & 0xff) / 255,
            B: CGFloat((value >> 08) & 0xff) / 255,
            a: CGFloat((value >> 00) & 0xff) / 255
        )
    }
    self.init(red: components.R, green: components.G, blue: components.B, alpha: components.a)
}

func toHex(alpha: Bool = false) -> String? {
    guard let components = cgColor.components, components.count >= 3 else {
        return nil
    }
    
    let r = Float(components[0])
    let g = Float(components[1])
    let b = Float(components[2])
    var a = Float(1.0)
    
    if components.count >= 4 {
        a = Float(components[3])
    }
    
    if alpha {
        return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
    } else {
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
}
 
