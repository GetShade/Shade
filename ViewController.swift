class ViewController: UIViewController {
    private let blendView = BlendLayerView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBlendView()
    }

    private func setupBlendView() {
        view.addSubview(blendView)
        blendView.frame = view.bounds

        // Set base and blend images
        if let baseImage = UIImage(named: "baseImage"),
           let blendImage = UIImage(named: "blendImage") {
            blendView.setBaseImage(baseImage)
            blendView.setBlendImage(blendImage)
        }

        // Set blend mode
        blendView.setBlendMode(.overlay)
    }
}
