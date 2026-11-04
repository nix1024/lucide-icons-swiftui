import SwiftUI

public struct LucideIcon: View {
    public let name: LucideIconName
    @ScaledMetric private var scaledSize: CGFloat

    public init(
        _ name: LucideIconName,
        size: CGFloat = 24,
        relativeTo textStyle: Font.TextStyle = .body
    ) {
        precondition(size.isFinite && size > 0, "Icon size must be finite and positive")
        self.name = name
        _scaledSize = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
    }

    public var body: some View {
        Image(decorative: name.assetName, bundle: .module)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: scaledSize, height: scaledSize)
    }
}

extension LucideIconName {
    var assetName: String { "lucide-" + rawValue }
}
