import SwiftUI

public struct LucideIcon: View {
    /// The built-in icon name, or `nil` for a custom asset.
    public let name: LucideIconName?
    private let image: Image
    private let renderingMode: Image.TemplateRenderingMode
    @ScaledMetric private var scaledSize: CGFloat

    public init(
        _ name: LucideIconName,
        size: CGFloat = 24,
        relativeTo textStyle: Font.TextStyle = .body
    ) {
        precondition(size.isFinite && size > 0, "Icon size must be finite and positive")
        self.name = name
        image = Image(decorative: name.assetName, bundle: .module)
        renderingMode = .template
        _scaledSize = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
    }

    /// Displays an asset from the app or another resource bundle.
    /// Use `.original` to preserve a multicolor asset's colors.
    public init(
        asset: String,
        bundle: Bundle = .main,
        renderingMode: Image.TemplateRenderingMode = .template,
        size: CGFloat = 24,
        relativeTo textStyle: Font.TextStyle = .body
    ) {
        precondition(size.isFinite && size > 0, "Icon size must be finite and positive")
        name = nil
        image = Image(decorative: asset, bundle: bundle)
        self.renderingMode = renderingMode
        _scaledSize = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
    }

    public var body: some View {
        image
            .renderingMode(renderingMode)
            .resizable()
            .scaledToFit()
            .frame(width: scaledSize, height: scaledSize)
    }
}

extension LucideIconName {
    var assetName: String { "lucide-" + rawValue }
}
