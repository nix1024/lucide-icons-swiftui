import SwiftUI

public extension Label where Title == Text, Icon == LucideIcon {
    init(_ title: LocalizedStringKey, lucide icon: LucideIconName) {
        self.init { Text(title) } icon: { LucideIcon(icon, size: 20) }
    }

    init(_ title: some StringProtocol, lucide icon: LucideIconName) {
        self.init { Text(title) } icon: { LucideIcon(icon, size: 20) }
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    init(_ title: LocalizedStringResource, lucide icon: LucideIconName) {
        self.init { Text(title) } icon: { LucideIcon(icon, size: 20) }
    }
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
public extension ContentUnavailableView where Label == SwiftUI.Label<Text, LucideIcon>, Description == Text?,
    Actions == EmptyView {
    init(_ title: LocalizedStringKey, lucide icon: LucideIconName, description: Text? = nil) {
        self.init {
            SwiftUI.Label { Text(title) } icon: { LucideIcon(icon, size: 48, relativeTo: .largeTitle) }
        } description: { description }
    }

    init(_ title: some StringProtocol, lucide icon: LucideIconName, description: Text? = nil) {
        self.init {
            SwiftUI.Label { Text(title) } icon: { LucideIcon(icon, size: 48, relativeTo: .largeTitle) }
        } description: { description }
    }
}
