import SwiftUI
import MetalKit
struct ContentView: View {
    @State private var selectedImage: NSImage?
    @State private var brightness: Float = 0
    @State private var contrast: Float = 1
    @State private var saturation: Float = 1
    @State private var hueAngle: Float = 0
    @State private var exposure: Float = 0
    @State private var selectedFilter: FilterType = .none
    @State private var blurRadius: Float = 0
    @State private var motionBlurAngle: Float = 0
    @State private var bokehRadius: Float = 0
    @State private var bokehRingAmount: Float = 1.0
    @State private var bokehRingSize: Float = 0.1

    // Metal renderers
    @State private var colorControlRenderer: ColorControlMetalRenderer?
    @State private var hueAdjustRenderer: HueAdjustMetalRenderer?
    @State private var exposureAdjustRenderer: ExposureAdjustMetalRenderer?
    @State private var boxBlurRenderer: BoxBlurMetalRenderer?
    @State private var gaussianBlurRenderer: GaussianBlurEffectMetalRenderer?
    @State private var motionBlurRenderer: MotionBlurMetalRenderer?
    @State private var bokehBlurRenderer: BokehBlurMetalRenderer?
    @State private var invertColorRenderer: InvertColorMetalRenderer?
    @State private var thresholdRenderer: ThresholdColorMetalRenderer?

    // MTKView for rendering
    @State private var metalView: MTKView?

    enum FilterType {
        case none
        case boxBlur
        case gaussianBlur
        case motionBlur
        case bokehBlur
        case colorInvert
        case threshold
    }

    var body: some View {
        NavigationView {
            HSplitView {
                // Left sidebar with filters
                VStack(spacing: 20) {
                    Text("Filters")
                        .font(.headline)

                    FilterButton(title: "Box Blur", isSelected: selectedFilter == .boxBlur) {
                        selectedFilter = .boxBlur
                        updateRenderer()
                    }

                    FilterButton(title: "Gaussian Blur", isSelected: selectedFilter == .gaussianBlur) {
                        selectedFilter = .gaussianBlur
                        updateRenderer()
                    }

                    FilterButton(title: "Motion Blur", isSelected: selectedFilter == .motionBlur) {
                        selectedFilter = .motionBlur
                        updateRenderer()
                    }

                    FilterButton(title: "Bokeh Blur", isSelected: selectedFilter == .bokehBlur) {
                        selectedFilter = .bokehBlur
                        updateRenderer()
                    }

                    FilterButton(title: "Invert", isSelected: selectedFilter == .colorInvert) {
                        selectedFilter = .colorInvert
                        updateRenderer()
                    }

                    FilterButton(title: "Threshold", isSelected: selectedFilter == .threshold) {
                        selectedFilter = .threshold
                        updateRenderer()
                    }

                    Spacer()
                }
                .frame(width: 200)
                .padding()
                .background(Color(.systemGray6))

                // Main content area
                VStack {
                    if let image = selectedImage {
                        MetalViewRepresentable(metalView: $metalView)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onChange(of: [brightness, contrast, saturation, hueAngle, exposure,
                                         blurRadius, motionBlurAngle, bokehRadius,
                                         bokehRingAmount, bokehRingSize]) { _ in
                                updateParameters()
                            }
                    } else {
                        ImagePlaceholder()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Right sidebar with adjustments
                VStack(spacing: 20) {
                    Text("Adjustments")
                        .font(.headline)

                    Group {
                        switch selectedFilter {
                        case .none:
                            AdjustmentSlider(title: "Brightness", value: $brightness, range: 0...2)
                            AdjustmentSlider(title: "Contrast", value: $contrast, range: 0...2)
                            AdjustmentSlider(title: "Saturation", value: $saturation, range: -1...2)
                            AdjustmentSlider(title: "Hue", value: $hueAngle, range: -180...180)
                            AdjustmentSlider(title: "Exposure", value: $exposure, range: -2...2)

                        case .boxBlur, .gaussianBlur:
                            AdjustmentSlider(title: "Radius", value: $blurRadius, range: 0...20)

                        case .motionBlur:
                            AdjustmentSlider(title: "Radius", value: $blurRadius, range: 1...20)
                            AdjustmentSlider(title: "Angle", value: $motionBlurAngle, range: 0...360)

                        case .bokehBlur:
                            AdjustmentSlider(title: "Radius", value: $bokehRadius, range: 0...1)
                            AdjustmentSlider(title: "Ring Size", value: $bokehRingSize, range: 0...1)
                            AdjustmentSlider(title: "Ring Amount", value: $bokehRingAmount, range: 1...10)

                        case .threshold:
                            AdjustmentSlider(title: "Threshold", value: $brightness, range: 0...1)

                        default:
                            EmptyView()
                        }
                    }

                    Spacer()
                }
                .frame(width: 250)
                .padding()
                .background(Color(.systemGray6))
            }
            .navigationTitle("Photo Editor")
            .toolbar {
                Button("Open Image") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.canCreateDirectories = false
                    panel.canChooseFiles = true
                    panel.allowedContentTypes = [.image]

                    if panel.runModal() == .OK {
                        if let url = panel.url,
                           let image = NSImage(contentsOf: url) {
                            selectedImage = image
                            setupMetalRenderers(with: image)
                        }
                    }
                }
            }
        }
    }

    private func setupMetalRenderers(with image: NSImage) {
        guard let device = MTLCreateSystemDefaultDevice() else { return }

        // Initialize Metal view
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        mtkView.framebufferOnly = false
        metalView = mtkView

        // Initialize all renderers
        colorControlRenderer = ColorControlMetalRenderer(device: device, image: image)
        hueAdjustRenderer = HueAdjustMetalRenderer(device: device, image: image)
        exposureAdjustRenderer = ExposureAdjustMetalRenderer(device: device, image: image)
        boxBlurRenderer = BoxBlurMetalRenderer(device: device, image: image)
        gaussianBlurRenderer = GaussianBlurEffectMetalRenderer(device: device, image: image)
        motionBlurRenderer = MotionBlurMetalRenderer(device: device, image: image)
        bokehBlurRenderer = BokehBlurMetalRenderer(device: device, image: image)
        invertColorRenderer = InvertColorMetalRenderer(device: device, image: image)
        thresholdRenderer = ThresholdColorMetalRenderer(device: device, image: image)

        updateRenderer()
    }

    private func updateRenderer() {
        guard let metalView = metalView else { return }

        // Update MTKView delegate based on selected filter
        switch selectedFilter {
        case .none:
            metalView.delegate = colorControlRenderer
        case .boxBlur:
            metalView.delegate = boxBlurRenderer
        case .gaussianBlur:
            metalView.delegate = gaussianBlurRenderer
        case .motionBlur:
            metalView.delegate = motionBlurRenderer
        case .bokehBlur:
            metalView.delegate = bokehBlurRenderer
        case .colorInvert:
            metalView.delegate = invertColorRenderer
        case .threshold:
            metalView.delegate = thresholdRenderer
        }

        metalView.setNeedsDisplay(metalView.bounds)
    }

    private func updateParameters() {
        switch selectedFilter {
        case .none:
            colorControlRenderer?.brightness = brightness
            colorControlRenderer?.contrast = contrast
            colorControlRenderer?.saturation = saturation
            hueAdjustRenderer?.hueAngle = hueAngle
            exposureAdjustRenderer?.exposureEV = exposure

        case .boxBlur:
            boxBlurRenderer?.radius = blurRadius

        case .gaussianBlur:
            gaussianBlurRenderer?.radius = blurRadius

        case .motionBlur:
            motionBlurRenderer?.radius = blurRadius
            motionBlurRenderer?.blurAngle = motionBlurAngle

        case .bokehBlur:
            bokehBlurRenderer?.radius = bokehRadius
            bokehBlurRenderer?.ringAmount = bokehRingAmount
            bokehBlurRenderer?.ringSize = bokehRingSize

        case .threshold:
            thresholdRenderer?.threshold = brightness

        default:
            break
        }

        metalView?.setNeedsDisplay(metalView?.bounds ?? .zero)
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct AdjustmentSlider: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)

            Slider(value: $value, in: range)

            Text(String(format: "%.2f", value))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ImagePlaceholder: View {
    var body: some View {
        VStack {
            Image(systemName: "photo")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Drop image here or click Open Image")
                .foregroundColor(.secondary)
        }
    }
}

// Metal view wrapper for SwiftUI
struct MetalViewRepresentable: NSViewRepresentable {
    @Binding var metalView: MTKView?

    func makeNSView(context: Context) -> MTKView {
        return metalView ?? MTKView()
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        // Updates are handled by the Metal renderers
    }
}
