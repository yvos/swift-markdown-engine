import Foundation

/// One host-authored document operation. Replacements use UTF-16 ranges in the
/// raw Markdown binding; the engine maps them to its projected editor text.
public struct MarkdownDocumentTransaction: Sendable, Equatable, Identifiable {
    public struct Replacement: Sendable, Equatable {
        public let range: NSRange
        public let text: String

        public init(range: NSRange, text: String) {
            self.range = range
            self.text = text
        }
    }

    public let id: UUID
    public let documentID: String
    public let sourceRevision: Int
    public let expectedSource: String
    public let replacements: [Replacement]
    /// Optional caret offset in the resulting raw Markdown source.
    public let selectionAfter: Int?
    public let actionName: String

    public init(
        id: UUID = UUID(),
        documentID: String,
        sourceRevision: Int,
        expectedSource: String,
        replacements: [Replacement],
        selectionAfter: Int? = nil,
        actionName: String
    ) {
        self.id = id
        self.documentID = documentID
        self.sourceRevision = sourceRevision
        self.expectedSource = expectedSource
        self.replacements = replacements
        self.selectionAfter = selectionAfter
        self.actionName = actionName
    }
}

/// Outcome for a consumed document transaction request.
public enum MarkdownDocumentTransactionFailureCode: String, Sendable, Equatable {
    case documentMismatch
    case sourceRevisionMismatch
    case sourceMismatch
    case invalidAction
    case tooManyReplacements
    case readOnly
    case undoUnavailable
    case invalidReplacementRange
    case unmappableDisplayRange
    case displayRangeOutOfBounds
}

public struct MarkdownDocumentTransactionResult: Sendable, Equatable {
    public let id: UUID
    public let applied: Bool
    /// Bounded structural cause when the engine rejects a transaction.
    public let failureCode: MarkdownDocumentTransactionFailureCode?

    public init(
        id: UUID,
        applied: Bool,
        failureCode: MarkdownDocumentTransactionFailureCode? = nil
    ) {
        self.id = id
        self.applied = applied
        self.failureCode = failureCode
    }
}
