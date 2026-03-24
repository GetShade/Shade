import SwiftUI

struct ContentView: View {
    @State private var selectedBlendMode: CustomBlendMode = .normal
    @State private var baseImage: NSImage?
    @State private var blendImage: NSImage?

    var body: some View {
        HSplitView {
            // Left sidebar with controls
            VStack(alignment: .leading, spacing: 20) {
                Text("Blend Modes")
                    .font(.headline)

                Picker("Blend Mode", selection: $selectedBlendMode) {
                    Group {
                        Text("Normal").tag(CustomBlendMode.normal)
                        Text("Multiply").tag(CustomBlendMode.multiply)
                        Text("Screen").tag(CustomBlendMode.screen)
                        Text("Overlay").tag(CustomBlendMode.overlay)
                        Text("Darken").tag(CustomBlendMode.darken)
                        Text("Lighten").tag(CustomBlendMode.lighten)
                        Text("Color Dodge").tag(CustomBlendMode.colorDodge)
                        Text("Color Burn").tag(CustomBlendMode.colorBurn)
                        Text("Soft Light").tag(CustomBlendMode.softLight)
                        Text("Hard Light").tag(CustomBlendMode.hardLight)
                    }

                    Group {
                        Text("Difference").tag(CustomBlendMode.difference)
                        Text("Exclusion").tag(CustomBlendMode.exclusion)
                        Text("Hue").tag(CustomBlendMode.hue)
                        Text("Saturation").tag(CustomBlendMode.saturation)
                        Text("Color").tag(CustomBlendMode.color)
                        Text("Luminosity").tag(CustomBlendMode.luminosity)
                        Text("Linear Dodge").tag(CustomBlendMode.linearDodge)
                        Text("Hard Mix").tag(CustomBlendMode.hardMix)
                        Text("Vivid Light").tag(CustomBlendMode.vividLight)
                        Text("Linear Light").tag(CustomBlendMode.linearLight)
                    }
                }
                .pickerStyle(RadioGroupPickerStyle())
                .padding()

                VStack(alignment: .leading, spacing: 10) {
                    Button("Choose Base Image") {
                        openImagePicker(for: \.$baseImage)
                    }

                    Button("Choose Blend Image") {
                        openImagePicker(for: \.$blendImage)
                    }
                }
                .padding()

                Spacer()
            }
            .frame(minWidth: 200, maxWidth: 250)
            .padding()

            // Right side with blend preview
            if let baseImage = baseImage, let blendImage = blendImage {
                BlendLayerView(
                    baseImage: baseImage,
                    blendImage: blendImage,
                    blendMode: selectedBlendMode
                )
                .frame(minWidth: 400, minHeight: 400)
            } else {
                Text("Choose base and blend images to start")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func openImagePicker(for binding: ReferenceWritableKeyPath<ContentView, Binding<NSImage?>>) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]

        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let image = NSImage(contentsOf: url) {
                    self[keyPath: binding].wrappedValue = image
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
