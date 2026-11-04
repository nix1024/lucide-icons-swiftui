#if canImport(UIKit) && !os(watchOS)
    import UIKit

    public extension LucideIconName {
        var uiImage: UIImage {
            guard let image = UIImage(named: assetName, in: .module, compatibleWith: nil) else {
                preconditionFailure("Missing bundled Lucide icon: \(rawValue)")
            }

            return image.withRenderingMode(.alwaysTemplate)
        }
    }
#endif
