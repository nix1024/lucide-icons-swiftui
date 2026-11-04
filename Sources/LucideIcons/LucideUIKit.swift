#if canImport(UIKit) && !os(watchOS)
    import UIKit

    public extension LucideIconResource {
        /// Loads the asset, returning `nil` if it is missing from its bundle.
        /// UIKit callers manage sizing and Dynamic Type themselves.
        func uiImage(renderingMode: UIImage.RenderingMode = .alwaysTemplate) -> UIImage? {
            UIImage(named: assetName, in: bundle, compatibleWith: nil)?
                .withRenderingMode(renderingMode)
        }
    }
#endif
