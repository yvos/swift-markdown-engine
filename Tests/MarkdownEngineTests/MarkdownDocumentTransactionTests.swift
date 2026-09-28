import AppKit
import Foundation
import Testing
@testable import MarkdownEngine

@MainActor
@Suite(.serialized)
struct MarkdownDocumentTransactionTests {
    @Test
    func textTransactionUndoAndRedoNeedsNoHostHistoryContext() throws {
        _ = NSApplication.shared
        let coordinator = NativeTextViewCoordinator(
            text: .constant("abc"),
            fontName: NSFont.systemFont(ofSize: 14).fontName,
            fontSize: 14,
            isWikiLinkActive: .constant(false),
            onLinkClick: nil,
            onInlineSelectionChange: nil
        )
        coordinator.documentId = "meeting-a"
        coordinator.sourceRevision = 2
        coordinator.currentSourceRevision = { 3 }
        let textView = NativeTextView(frame: .zero)
        textView.string = "abc"
        textView.isEditable = true
        textView.delegate = coordinator
        coordinator.textView = textView
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 160),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.contentView = textView
        window.makeFirstResponder(textView)
        let transaction = MarkdownDocumentTransaction(
            documentID: "meeting-a",
            sourceRevision: 3,
            expectedSource: "abc",
            replacements: [.init(range: NSRange(location: 1, length: 1), text: "X")],
            actionName: "Edit document"
        )

        var failureCode: MarkdownDocumentTransactionFailureCode?
        #expect(coordinator.applyDocumentTransaction(transaction, to: textView, failureCode: &failureCode))
        #expect(failureCode == nil)
        #expect(textView.string == "aXc")

        let manager = try #require(coordinator.undoManager(for: textView))
        #expect(manager.canUndo)
        manager.undo()
        #expect(textView.string == "abc")

        manager.redo()
        #expect(textView.string == "aXc")
        window.orderOut(nil)
    }

    @Test
    func staleDocumentRevisionRejectsTransactionWithoutChangingText() {
        _ = NSApplication.shared
        let coordinator = NativeTextViewCoordinator(
            text: .constant("abc"),
            fontName: NSFont.systemFont(ofSize: 14).fontName,
            fontSize: 14,
            isWikiLinkActive: .constant(false),
            onLinkClick: nil,
            onInlineSelectionChange: nil
        )
        coordinator.documentId = "meeting-a"
        coordinator.sourceRevision = 4
        let textView = NativeTextView(frame: .zero)
        textView.string = "abc"
        textView.isEditable = true
        textView.delegate = coordinator
        coordinator.textView = textView
        let transaction = MarkdownDocumentTransaction(
            documentID: "meeting-a",
            sourceRevision: 3,
            expectedSource: "abc",
            replacements: [.init(range: NSRange(location: 1, length: 1), text: "X")],
            actionName: "Edit document"
        )

        var failureCode: MarkdownDocumentTransactionFailureCode?
        #expect(!coordinator.applyDocumentTransaction(transaction, to: textView, failureCode: &failureCode))
        #expect(failureCode == .sourceRevisionMismatch)
        #expect(textView.string == "abc")
        #expect(coordinator.undoManager(for: textView)?.canUndo == false)
    }
}
