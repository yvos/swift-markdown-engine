import AppKit
import Foundation
import SwiftUI
import Testing
@testable import MarkdownEngine

@MainActor
@Suite(.serialized)
struct PreparedTextMutationTests {
    @Test
    func typedCheckboxAndHostContextUndoAndRedoTogether() throws {
        _ = NSApplication.shared
        let source = "- [ ] "
        let coordinator = NativeTextViewCoordinator(
            text: .constant(source),
            fontName: NSFont.systemFont(ofSize: 14).fontName,
            fontSize: 14,
            isWikiLinkActive: .constant(false),
            onLinkClick: nil,
            onInlineSelectionChange: nil
        )
        coordinator.documentId = "meeting-prepared"
        coordinator.sourceRevision = 7
        coordinator.lastSyncedText = source
        coordinator.lastComputedStorage = source

        let before = Data([1])
        let after = Data([2])
        var restored: [Data?] = []
        var results: [Bool] = []
        coordinator.onHistoryContextRestore = { id, context in
            #expect(id == "meeting-prepared")
            restored.append(context)
        }
        coordinator.onDocumentTransactionResult = { result in
            results.append(result.applied)
        }
        coordinator.onPrepareTextMutation = { proposal in
            #expect(proposal.documentID == "meeting-prepared")
            #expect(proposal.sourceRevision == 7)
            #expect(proposal.source == source)
            #expect(proposal.range == NSRange(location: 6, length: 0))
            #expect(proposal.replacement == "x")
            let marked = "- [ ] x <!-- nofray:action:typed -->"
            return MarkdownDocumentTransaction(
                documentID: proposal.documentID,
                sourceRevision: proposal.sourceRevision,
                expectedSource: proposal.source,
                replacements: [.init(range: NSRange(location: 0, length: (source as NSString).length),
                                     text: marked)],
                selectionAfter: ("- [ ] x" as NSString).length,
                historyContextBefore: before,
                historyContextAfter: after,
                actionName: "Add meeting action"
            )
        }

        let textView = NativeTextView(frame: .zero)
        textView.allowsUndo = true
        textView.string = source
        textView.isEditable = true
        textView.delegate = coordinator
        coordinator.textView = textView
        textView.setSelectedRange(NSRange(location: (source as NSString).length, length: 0))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 160),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = textView
        window.makeFirstResponder(textView)

        textView.insertText("x", replacementRange: NSRange(location: 6, length: 0))

        let marked = "- [ ] x <!-- nofray:action:typed -->"
        #expect(textView.string == marked)
        #expect(textView.selectedRange().location == ("- [ ] x" as NSString).length)
        #expect(restored == [after])
        #expect(results == [true])

        let undoManager = try #require(coordinator.undoManager(for: textView))
        undoManager.undo()
        #expect(textView.string == source)
        #expect(restored == [after, before])

        undoManager.redo()
        #expect(textView.string == marked)
        #expect(restored == [after, before, after])
        window.orderOut(nil)
    }
}
