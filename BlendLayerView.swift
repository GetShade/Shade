import SwiftUI
import AppKit

struct BlendLayerMetalView: NSViewRepresentable {
    var baseImage: NSImage
    var blendImage: NSImage
    var blendMode: CustomBlendMode

    // For custom blend modes
    @State private var compositedImage: NSImage?

    func makeNSView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.delegate = context.coordinator.renderer
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        mtkView.autoResizeDrawable = true
        return mtkView
    }

    func updateNSView(_ mtkView: MTKView, context: Context) {
        context.coordinator.updateBlendMode(blendMode)
        mtkView.setNeedsDisplay(mtkView.frame)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: BlendLayerMetalView
        var renderer: BlendLayerMetalRenderer

        init(_ parent: BlendLayerMetalView) {
            self.parent = parent
            let device = MTLCreateSystemDefaultDevice()!
            self.renderer = BlendLayerMetalRenderer(device: device,
                                                  baseImage: parent.baseImage,
                                                  blendImage: parent.blendImage)
        }

        func updateBlendMode(_ mode: CustomBlendMode) {
            renderer.blendMode = mode
        }

        func draw(in view: MTKView) {
            renderer.draw(in: view)
        }
    }
}

struct BlendLayerView: View {
    @State private var selectedBlendMode: CustomBlendMode = .normal
    var baseImage: NSImage = NSImage(resource: .person)
    var blendImage: NSImage = NSImage(resource: .person2)

    var body: some View {
        VStack {
            BlendLayerMetalView(
                baseImage: baseImage,
                blendImage: blendImage,
                blendMode: selectedBlendMode
            )
            .frame(width: 300, height: 300)

            Picker("Blend Mode", selection: $selectedBlendMode) {
                Group {
                    Text("Normal").tag(CustomBlendMode.normal)
                    Text("Multiply").tag(CustomBlendMode.multiply)
                    Text("Screen").tag(CustomBlendMode.screen)
                    Text("Overlay").tag(CustomBlendMode.overlay)
                    Text("Darken").tag(CustomBlendMode.darken)
                    Text("Lighten").tag(CustomBlendMode.lighten)
                }

                Group {
                    Text("Color Dodge").tag(CustomBlendMode.colorDodge)
                    Text("Color Burn").tag(CustomBlendMode.colorBurn)
                    Text("Soft Light").tag(CustomBlendMode.softLight)
                    Text("Hard Light").tag(CustomBlendMode.hardLight)
                    Text("Difference").tag(CustomBlendMode.difference)
                    Text("Exclusion").tag(CustomBlendMode.exclusion)
                }

                Group {
                    Text("Hue").tag(CustomBlendMode.hue)
                    Text("Saturation").tag(CustomBlendMode.saturation)
                    Text("Color").tag(CustomBlendMode.color)
                    Text("Luminosity").tag(CustomBlendMode.luminosity)
                    Text("Linear Dodge").tag(CustomBlendMode.linearDodge)
                    Text("Hard Mix").tag(CustomBlendMode.hardMix)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
        }
    }
}

#Preview {
    BlendLayerView()
}
