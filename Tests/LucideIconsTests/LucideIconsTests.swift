import SwiftUI
import Testing
@testable import LucideIcons

#if canImport(UIKit)
    import UIKit
#else
    import AppKit
#endif

@Test func everyIconHasAnAsset() {
    for (name, resource) in LucideIconCatalog.all {
        #if canImport(UIKit)
            #expect(resource.uiImage() != nil, "Missing \(name)")
        #else
            #expect(resource.bundle.image(forResource: resource.assetName) != nil, "Missing \(name)")
        #endif
    }
}

@Test func catalogLooksUpExactNames() throws {
    #expect(!LucideIconCatalog.all.isEmpty)
    for (name, resource) in LucideIconCatalog.all {
        #expect(LucideIconCatalog.icon(named: name) == resource)
        #expect(resource.assetName == "lucide-" + name)
    }
    #expect(LucideIconCatalog.icon(named: "") == nil)
    #expect(LucideIconCatalog.icon(named: "not-a-lucide-icon") == nil)
    let name = try #require(LucideIconCatalog.all.keys.sorted().first)
    #expect(LucideIconCatalog.icon(named: " " + name) == nil)
}

@available(iOS 16, macOS 13, *)
@MainActor
private func render(
    size: DynamicTypeSize,
    bold: Bool = false,
    baseSize: CGFloat = 24,
    style: Font.TextStyle = .body
) throws -> CGImage {
    let name = try #require(LucideIconCatalog.all.keys.sorted().first)
    let resource = try #require(LucideIconCatalog.icon(named: name))
    let renderer = ImageRenderer(content:
        LucideIcon(resource, size: baseSize, relativeTo: style)
            .foregroundStyle(.black)
            .fontWeight(bold ? .bold : .regular)
            .environment(\.legibilityWeight, bold ? .bold : .regular)
            .environment(\.dynamicTypeSize, size)
    )
    return try #require(renderer.cgImage)
}

@available(iOS 16, macOS 13, *)
@Test @MainActor func dynamicTypeScalesThroughAccessibilitySizes() throws {
    let sizes: [DynamicTypeSize] = [
        .xSmall,
        .small,
        .medium,
        .large,
        .xLarge,
        .xxLarge,
        .xxxLarge,
        .accessibility1,
        .accessibility2,
        .accessibility3,
        .accessibility4,
        .accessibility5,
    ]
    let widths = try sizes.map { try render(size: $0).width }
    #expect(try render(size: .large).width == 24)
    #expect(widths.last! > widths.first!)
    for (smaller, larger) in zip(widths, widths.dropFirst()) {
        #expect(larger >= smaller)
    }
    #expect(try render(size: .accessibility5, style: .caption).width != render(size: .accessibility5, style: .title)
        .width
    )
    #expect(try render(size: .large, baseSize: 32).width == 32)
}

@available(iOS 16, macOS 13, *)
@Test @MainActor func boldDoesNotChangeArtwork() throws {
    for size: DynamicTypeSize in [.large, .accessibility3] {
        let regular = try render(size: size)
        let bold = try render(size: size, bold: true)
        #expect(regular.width == bold.width)
        #expect(regular.height == bold.height)
        let regularData = try #require(regular.dataProvider?.data)
        let boldData = try #require(bold.dataProvider?.data)
        #expect(regularData as Data == boldData as Data)
        #expect((regularData as Data).contains { $0 != 0 })
    }
}
