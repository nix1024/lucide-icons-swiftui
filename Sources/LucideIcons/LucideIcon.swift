import SwiftUI

/// A decorative icon with aspect-fit layout and Dynamic Type scaling.
public struct LucideIcon: View {
    private let resource: LucideIconResource
    private let renderingMode: Image.TemplateRenderingMode
    @ScaledMetric private var scaledSize: CGFloat

    /// Displays a built-in or custom resource.
    ///
    /// `size` is the square frame's side length at Dynamic Type `.large` and must
    /// be finite and positive. It scales relative to `textStyle`, independently
    /// of the parent's font. Use `.original` to preserve multicolor artwork.
    /// Provide an accessibility label on the enclosing control when needed.
    public init(
        _ resource: LucideIconResource,
        size: CGFloat = 24,
        relativeTo textStyle: Font.TextStyle = .body,
        renderingMode: Image.TemplateRenderingMode = .template
    ) {
        precondition(size.isFinite && size > 0, "Icon size must be finite and positive")
        self.resource = resource
        self.renderingMode = renderingMode
        _scaledSize = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
    }

    public var body: some View {
        Image(decorative: resource.assetName, bundle: resource.bundle)
            .renderingMode(renderingMode)
            .resizable()
            .scaledToFit()
            .frame(width: scaledSize, height: scaledSize)
    }
}
