# Lucide Icons for SwiftUI

An unofficial Swift Package for [Lucide](https://lucide.dev) icons, with Dynamic Type scaling, template colors, and optional build-time subsetting. Not affiliated with the Lucide project.

## Install

Add `https://github.com/nix1024/lucide-icons-swiftui` in Xcode's **Add Package Dependencies**, and select the `LucideIcons` product. Or add:

```swift
.package(url: "https://github.com/nix1024/lucide-icons-swiftui.git", from: "0.1.0")
```

Then add `.product(name: "LucideIcons", package: "lucide-icons-swiftui")` to your target's dependencies.

Requires Swift 6.0. Declared platforms: iOS 15+, macOS 12+, watchOS 8+, tvOS 15+, visionOS 1+. Validation currently covers iOS Simulator; support for other platforms is not a claim of device testing.

## Use

```swift
import LucideIcons
import SwiftUI

LucideIcon(.history)
    .foregroundStyle(.secondary)

LucideIcon(.settings, size: 20, relativeTo: .caption)
    .foregroundStyle(.blue)

Label("History", lucide: .history)

Button {
    showHistory()
} label: {
    LucideIcon(.history)
}
.accessibilityLabel("History")
```

- Default size: 24 points at Dynamic Type `.large`, scaling relative to `.body`, including accessibility sizes.
- Supply `relativeTo` explicitly for other text styles; a parent's `.font` does not determine icon size. SwiftUI's `.dynamicTypeSize(...)` can constrain scaling.
- SVG artwork stays vector-based. Strokes scale proportionally with the icon, preserving Lucide's original 24×24 view box and stroke proportions.
- Bold Text, `.bold()`, and `.fontWeight()` do **not** change icon weight. These are template images, not SF Symbols; symbol variants and symbol effects are not supported.
- Icons are decorative by default. Provide a localized label for icon-only controls.
- `LucideIconName.allCases` lists the available icons. `LucideIconName(rawValue: "arrow-left")` parses upstream names and returns `nil` for unavailable icons.
- `Label(..., lucide: ...)` uses a 20-point icon. Use a custom Label icon closure to choose another size.
- On iOS/tvOS, `LucideIconName.history.uiImage` returns a UIKit template image. It does not manage Dynamic Type sizing; UIKit callers own layout and scaling.

## Custom icons

Add your SVG or PDF to your app's asset catalogue, then use its asset name:

```swift
LucideIcon(asset: "company-logo")
    .foregroundStyle(.blue)

// Preserve a multicolor logo's original colors.
LucideIcon(asset: "company-logo", renderingMode: .original, size: 32)

// Inside a Swift Package that owns the asset:
LucideIcon(asset: "custom-icon", bundle: .module, size: 20, relativeTo: .caption)
```

The bundle defaults to `.main`. Pass the bundle that owns the asset; `.module` in the example belongs to your package, not LucideIcons. Use the exact asset name, without a file extension or an automatic `lucide-` prefix. This initializer loads bundled image assets, not arbitrary SVG files or URLs.

Custom icons share the built-in icons' Dynamic Type scaling, aspect-fit layout, and decorative accessibility behavior. Template rendering is the default; use `.original` for multicolor artwork. Enable **Preserve Vector Data** in your asset catalogue for scalable vector artwork. For custom icons in a `Label`, use its icon closure:

```swift
Label {
    Text("Company")
} icon: {
    LucideIcon(asset: "company-logo", size: 20)
}
```

API note: `LucideIcon.name` is now `LucideIconName?`: built-in icons return their name, and custom assets return `nil`. Existing built-in initializers are unchanged; code that reads `name` must handle the optional value.

## Keep your app small

The default package bundles all 2,313 upstream names (including aliases), pinned to `lucide-static` 1.68.0. Adding the remote SPM product does **not** automatically strip unused images. Each app or extension may carry its own resource bundle.

For a smaller app, generate a standalone local package from a JSON selection:

```json
["history", "settings", "languages", "volume-2"]
```

```sh
git clone --branch 0.1.0 --depth 1 https://github.com/nix1024/lucide-icons-swiftui.git
python3 lucide-icons-swiftui/Scripts/generate.py \
  --icons /path/to/icons.json \
  --output /path/to/MyApp/Packages/LucideIcons
```

Add the generated folder as a **local** Swift Package instead of the full remote product. Commit the generated package and your selection to your app repository; normal builds need neither Python nor network access for icons. Keep the generator tag/commit pinned when updating.

The output includes the runtime sources, package manifest, tests, selected SVG assets, and both licenses. Only selected enum cases exist, so referencing an omitted icon is a compile error. Dynamic string names must be explicitly selected. The script rejects unknown or duplicate names before replacing generated assets. Regeneration removes previously selected icons that are no longer listed. It overwrites its generated files; keep custom code outside the output package.

Swift names use camelCase. Alias collisions are resolved against the full upstream catalogue (for example, `arrow-down-01` becomes `arrow_down_01`), so selecting a smaller set does not rename symbols.

## Regenerate and test

Python 3 standard library only:

```sh
python3 Scripts/generate.py
python3 -m unittest discover -s Scripts -p 'test_generate.py'
xcodebuild -scheme LucideIcons \
  -destination 'platform=iOS Simulator,name=<your simulator>' test
```

Generation verifies the pinned npm archive's SHA-512. To use an already downloaded archive, add `--archive /path/to/lucide-static-1.68.0.tgz`. Updating upstream requires reviewing both `VERSION` and `INTEGRITY` in the generator. Provenance is recorded in `upstream.json`.

Use Xcode/xcodebuild for rendering tests: the asset catalogue needs Apple's resource compiler, so plain `swift test` is not the supported resource-test path. Tests cover resource loading, Dynamic Type sizes, custom scaling curves, and unchanged rendered pixels under bold settings. Generator tests cover full export, subsets, stale asset removal, validation failures, and stable alias names.

## License

Swift wrappers, tests, and generation tooling: [MIT](LICENSE), copyright Nix Wang.

Lucide artwork: [ISC / Feather MIT notices](Sources/LucideIcons/Resources/Lucide-LICENSE.txt), copyright Lucide Icons and Contributors and Cole Bemis. Preserve these notices when redistributing full or subset packages. See the [upstream license](https://lucide.dev/license).
