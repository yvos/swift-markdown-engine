import Foundation

/// A checkbox activation offered to the host before the default text toggle.
/// The engine owns hit-testing and source coordinates; the host owns its action.
public struct MarkdownTaskCheckboxActivation: Sendable, Equatable {
    /// UTF-16 range of the three-character checkbox marker in raw Markdown.
    public let sourceRange: NSRange
    /// Full source line containing the marker, including its line terminator.
    public let lineRange: NSRange
    public let isChecked: Bool
    public let isEditable: Bool

    public init(sourceRange: NSRange, lineRange: NSRange, isChecked: Bool, isEditable: Bool) {
        self.sourceRange = sourceRange
        self.lineRange = lineRange
        self.isChecked = isChecked
        self.isEditable = isEditable
    }
}
