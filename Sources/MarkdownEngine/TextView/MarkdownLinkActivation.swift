import AppKit
import Foundation

/// Describes a link activation before the editor applies its default routing.
public struct MarkdownLinkActivation: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case inlineLink
        case wikiLink
        case autolink
    }

    /// The destination as written in the source. Inline Markdown destinations
    /// have angle brackets and an optional title removed, with no decoding.
    public let kind: Kind
    public let destination: String
    /// UTF-16 range of the full link token in raw Markdown storage coordinates.
    public let sourceRange: NSRange
    public let modifierFlags: NSEvent.ModifierFlags
    public let isEditable: Bool

    public init(
        kind: Kind,
        destination: String,
        sourceRange: NSRange,
        modifierFlags: NSEvent.ModifierFlags,
        isEditable: Bool
    ) {
        self.kind = kind
        self.destination = destination
        self.sourceRange = sourceRange
        self.modifierFlags = modifierFlags
        self.isEditable = isEditable
    }
}
