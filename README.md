# Lucide Icons for SwiftUI

An unofficial Swift Package for [Lucide](https://lucide.dev) icons, with Dynamic Type scaling, template colors, and optional build-time subsetting. Not affiliated with the Lucide project.

The resource-based API below describes the current development source and has not yet been released in a tag. Version 0.1.0 uses the earlier name-enum API.

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
- `Label(..., lucide: ...)` uses a 20-point icon. Use a custom Label icon closure to choose another size.

## Resources and the built-in catalogue

`LucideIconResource` is a `Hashable`, `Sendable` value containing an asset name and its owning bundle. `LucideIcon` displays that resource; size, scaling, and rendering mode belong to the view, not the resource.

```swift
let icon: LucideIconResource = .history
LucideIcon(icon, size: 20, relativeTo: .caption, renderingMode: .template)

// Lookup uses exact upstream kebab-case names. Unknown names return nil.
let selected = LucideIconCatalog.icon(named: "arrow-left")

// Dictionary from upstream names to resources, including aliases.
let available = LucideIconCatalog.all
let sortedNames = available.keys.sorted()
```

Subset packages expose only selected static properties and catalogue entries. Custom resources are not registered in the built-in catalogue. Catalogue separation does not automatically strip unused assets from the full package.

## Custom icons

Add your SVG or PDF to your app's asset catalogue, then define a reusable resource:

```swift
extension LucideIconResource {
    static var companyLogo: Self {
        Self(asset: "company-logo", bundle: .main)
    }
}

LucideIcon(.companyLogo)
    .foregroundStyle(.blue)

// Preserve a multicolor logo's original colors.
LucideIcon(.companyLogo, size: 32, renderingMode: .original)

// Inside a Swift Package that owns the asset:
let custom = LucideIconResource(asset: "custom-icon", bundle: .module)
LucideIcon(custom, size: 20, relativeTo: .caption)

let icons: [LucideIconResource] = [.history, .companyLogo]
Label("Company", lucide: .companyLogo)

// iOS 17 / macOS 14 and later:
ContentUnavailableView("No items", lucide: .companyLogo)
```

The bundle defaults to `.main`. Pass the bundle that owns the asset; `.module` in the example belongs to your package, not LucideIcons. Use the exact asset name, without a file extension or an automatic `lucide-` prefix. Resource initialization does not load or validate the asset. Rendering uses bundled image assets, not arbitrary SVG files or URLs; a missing asset follows SwiftUI `Image` behavior and has no automatic fallback.

Custom icons share the built-in icons' Dynamic Type scaling, aspect-fit layout, and decorative accessibility behavior. Template rendering is the default; use `.original` for multicolor artwork. Enable **Preserve Vector Data** in your asset catalogue for scalable vector artwork. Convenience labels use template rendering; use the icon closure to customize it:

```swift
Label {
    Text("Company")
} icon: {
    LucideIcon(.companyLogo, size: 20, renderingMode: .original)
}
```

## UIKit

On platforms with UIKit (excluding watchOS), the same resource can load a `UIImage`:

```swift
let template = LucideIconResource.history.uiImage()
let logo = LucideIconResource.companyLogo.uiImage(renderingMode: .alwaysOriginal)
```

Both return `UIImage?`; missing assets return `nil` so callers can choose a fallback. The default is `.alwaysTemplate`. UIKit callers own layout and Dynamic Type scaling.

## Keep your app small

The default package bundles all 2,313 upstream names (including aliases), pinned to `lucide-static` 1.68.0. Adding the remote SPM product does **not** automatically strip unused images. Each app or extension may carry its own resource bundle.

For a smaller app, generate a standalone local package from a JSON selection:

```json
["history", "settings", "languages", "volume-2"]
```

```sh
# From a checkout of this API version:
python3 Scripts/generate.py \
  --icons /path/to/icons.json \
  --output /path/to/MyApp/Packages/LucideIcons
```

Add the generated folder as a **local** Swift Package instead of the full remote product. Commit the generated package and your selection to your app repository; normal builds need neither Python nor network access for icons. Pin the generator checkout to a tag/commit when updating.

The output includes the runtime sources, package manifest, tests, selected SVG assets, and both licenses. Only selected static properties exist, so referencing an omitted icon is a compile error. Catalogue lookup returns `nil` for omitted icons. Dynamic string names must be explicitly selected. The script rejects unknown or duplicate names before replacing generated assets. Regeneration removes previously selected icons that are no longer listed. It overwrites its generated files; keep custom code outside the output package.

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

Use Xcode/xcodebuild for rendering tests: the asset catalogue needs Apple's resource compiler, so plain `swift test` is not the supported resource-test path. Tests cover catalogue lookup, resource identity, built-in and custom resource loading, template/original colors, aspect ratio, Dynamic Type sizes, custom scaling curves, convenience views, UIKit missing-asset behavior, and unchanged rendered pixels under bold settings. Generator tests cover full export, subsets, stale asset removal, validation failures, and stable alias names.

## License

Swift wrappers, tests, and generation tooling: [MIT](LICENSE), copyright Nix Wang.

Lucide artwork: [ISC / Feather MIT notices](Sources/LucideIcons/Resources/Lucide-LICENSE.txt), copyright Lucide Icons and Contributors and Cole Bemis. Preserve these notices when redistributing full or subset packages. See the [upstream license](https://lucide.dev/license).
