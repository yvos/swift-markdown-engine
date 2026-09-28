import AppKit
import Foundation
import SwiftUI
import Testing
@testable import MarkdownEngine

@MainActor
@Suite(.serialized)
struct NativeTypingHistoryTests {
    @Test
    func typedCheckboxTextUsesNativeUndoAndRedo() async throws {
        _ = NSApplication.shared
        let source = "- [ ] "
        var buffer = source
        let coordinator = NativeTextViewCoordinator(
            text: Binding(get: { buffer }, set: { buffer = $0 }),
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

        let marked = "- [ ] x"
        await flushBindingQueue()
        #expect(buffer == marked)
        #expect(textView.string == marked)
        #expect(textView.selectedRange().location == ("- [ ] x" as NSString).length)

        let undoManager = try #require(coordinator.undoManager(for: textView))
        undoManager.undo()
        await flushBindingQueue()
        #expect(buffer == source)
        #expect(textView.string == source)

        undoManager.redo()
        await flushBindingQueue()
        #expect(buffer == marked)
        #expect(textView.string == marked)
        window.orderOut(nil)
    }
    private func flushBindingQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}
