import Foundation

/// A reusable image asset reference, independent of its display size and colors.
///
/// Built-in Lucide icons are available as static properties. Add static properties
/// in your own extension to give custom assets the same typed call sites.
public struct LucideIconResource: Hashable, Sendable {
    /// The exact asset catalogue name, without a file extension.
    public let assetName: String

    /// The bundle containing the asset.
    public let bundle: Bundle

    /// References an asset without loading or validating it.
    ///
    /// For assets in another Swift Package, pass that package's `Bundle.module`.
    public init(asset name: String, bundle: Bundle = .main) {
        assetName = name
        self.bundle = bundle
    }
}
