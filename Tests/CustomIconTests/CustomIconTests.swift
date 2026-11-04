import LucideIcons
import SwiftUI
import Testing

@available(iOS 16, macOS 13, *)
@MainActor
private func render(
    mode: Image.TemplateRenderingMode = .template,
    size: DynamicTypeSize = .large,
    baseSize: CGFloat = 24,
    style: Font.TextStyle = .body,
    color: Color = .green
) throws -> CGImage {
    let renderer = ImageRenderer(content:
        LucideIcon(
            asset: "company-logo", bundle: .module, renderingMode: mode,
            size: baseSize, relativeTo: style
        )
        .foregroundStyle(color)
        .environment(\.dynamicTypeSize, size)
    )
    return try #require(renderer.cgImage)
}

private func pixels(_ image: CGImage) throws -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
    try bytes.withUnsafeMutableBytes { buffer in
        let context = try #require(CGContext(
            data: buffer.baseAddress, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: image.width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                | CGBitmapInfo.byteOrder32Big.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    }
    return bytes
}

@available(iOS 16, macOS 13, *)
@Test @MainActor func customBundleColorsAndAspectRatio() throws {
    let template = try render()
    let tinted = try pixels(template)
    let original = try pixels(render(mode: .original))
    #expect(template.width == 24 && template.height == 24)
    // The 2:1 artwork must remain centered inside the square frame.
    #expect(tinted[(2 * 24 + 12) * 4 + 3] == 0)
    let left = (12 * 24 + 6) * 4
    let right = (12 * 24 + 18) * 4
    #expect(tinted[left + 1] > tinted[left] && tinted[left + 3] > 240)
    #expect(original[left] > 240 && original[left + 2] < 10)
    #expect(original[right + 2] > 240 && original[right] < 10)
    #expect(try pixels(render(mode: .original, color: .yellow)) == original)
}

@available(iOS 16, macOS 13, *)
@Test @MainActor func customIconsScaleWithDynamicType() throws {
    #expect(try render(baseSize: 32).width == 32)
    #expect(try render(size: .accessibility5).width > render().width)
    #expect(try render(size: .accessibility5, style: .caption).width
        != render(size: .accessibility5, style: .title).width)
}

@Test @MainActor func customAssetsHaveNoBuiltInName() throws {
    let builtIn = try #require(LucideIconName.allCases.first)
    #expect(LucideIcon(builtIn).name == builtIn)
    #expect(LucideIcon(asset: "company-logo", bundle: .module).name == nil)
    #expect(LucideIcon(asset: "app-icon").name == nil)
}
