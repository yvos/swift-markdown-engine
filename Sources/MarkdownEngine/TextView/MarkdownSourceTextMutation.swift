import Foundation

/// One proposed edit in the host's raw Markdown source, before NSTextView
/// applies it. The host may return a document transaction to fold related
/// source metadata into the same native edit and undo unit.
public struct MarkdownSourceTextMutation: Equatable, Sendable {
    public let documentID: String
    public let sourceRevision: Int
    public let source: String
    public let range: NSRange
    public let replacement: String

    public init(documentID: String, sourceRevision: Int, source: String, range: NSRange, replacement: String) {
        self.documentID = documentID
        self.sourceRevision = sourceRevision
        self.source = source
        self.range = range
        self.replacement = replacement
    }
}
