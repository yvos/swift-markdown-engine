import AppKit
import SwiftUI
import Testing
@testable import MarkdownEngine

@MainActor
struct TaskCheckboxActivationTests {
    @Test
    func wrapperDefaultsAndCoordinatorForwarding() throws {
        #expect(NativeTextViewWrapper(text: .constant("")).onTaskCheckboxActivation == nil)
        var received: MarkdownTaskCheckboxActivation?
        let wrapper = NativeTextViewWrapper(text: .constant("- [ ] Item"), onTaskCheckboxActivation: {
            received = $0
            return true
        })
        let callback = try #require(wrapper.makeCoordinator().onTaskCheckboxActivation)
        let activation = MarkdownTaskCheckboxActivation(sourceRange: NSRange(location: 2, length: 3),
            lineRange: NSRange(location: 0, length: 10), isChecked: false, isEditable: false)
        #expect(callback(activation))
        #expect(received == activation)
    }

    @Test(arguments: [false, true], [false, true])
    func handledClickReportsActivationWithoutTextOrHistoryChanges(editable: Bool, checked: Bool) async throws {
        let source = "- \(checked ? "[X]" : "[ ]") Item\r\n"
        var activations: [MarkdownTaskCheckboxActivation] = []
        var mutations: [MarkdownTextMutation] = []
        let fixture = try ReadOnlyTaskCheckboxTests().makeFixture(source,
            checkboxRange: NSRange(location: 2, length: 3), allowsReadOnlyToggle: false,
            onTextMutation: { mutations.append($0) }, isEditable: editable,
            onTaskCheckboxActivation: { activations.append($0); return true })
        defer { fixture.window.orderOut(nil) }
        fixture.textView.setSelectedRange(NSRange(location: 8, length: 0))
        let selection = fixture.textView.selectedRange()
        let undo = try #require(fixture.coordinator.undoManager(for: fixture.textView))
        undo.removeAllActions()
        var interactions: [MarkdownEditorPointerInteraction] = []
        var pointer = NativePointerInteractionSession(event: fixture.click, beganOnLink: false,
            onInteraction: { interactions.append($0) })
        #expect(fixture.textView.consumeTaskCheckboxIfHit(event: fixture.click, pointerInteraction: &pointer))
        await settleBinding()
        #expect(activations == [.init(sourceRange: NSRange(location: 2, length: 3),
            lineRange: NSRange(location: 0, length: (source as NSString).length),
            isChecked: checked, isEditable: editable)])
        #expect(interactions == [.taskCheckbox])
        #expect(fixture.textView.string == source)
        #expect(fixture.published() == source)
        #expect(fixture.textView.selectedRange() == selection)
        #expect(mutations.isEmpty)
        #expect(!undo.canUndo && !undo.canRedo)
    }

    @Test(arguments: [false, true])
    func declinedClickKeepsTheDefaultReadOnlyPolicy(allowsReadOnlyToggle: Bool) async throws {
        let source = "- [ ] Item\n"
        var received = 0
        let fixture = try ReadOnlyTaskCheckboxTests().makeFixture(source,
            checkboxRange: NSRange(location: 2, length: 3), allowsReadOnlyToggle: allowsReadOnlyToggle,
            onTaskCheckboxActivation: { _ in received += 1; return false })
        defer { fixture.window.orderOut(nil) }
        #expect(fixture.textView.toggleTaskCheckboxIfHit(event: fixture.click) == true)
        await settleBinding()
        #expect(received == 1)
        #expect(fixture.published() == (allowsReadOnlyToggle ? "- [x] Item\n" : source))
    }

    @Test
    func rawRangesAccountForProjectedWikiLinksUnicodeAndCRLF() throws {
        let source = "😀 [[Prior|opaque-id]]\r\n- [ ] [Task](../Tasks/Task.md)\r\n"
        let display = WikiLinkService.makeDisplayState(from: source, nameForID: { _ in nil }).display as NSString
        var received: MarkdownTaskCheckboxActivation?
        let fixture = try ReadOnlyTaskCheckboxTests().makeFixture(source,
            checkboxRange: display.range(of: "[ ]"), allowsReadOnlyToggle: false,
            onTaskCheckboxActivation: { received = $0; return true })
        defer { fixture.window.orderOut(nil) }
        #expect(fixture.textView.toggleTaskCheckboxIfHit(event: fixture.click) == true)
        let marker = (source as NSString).range(of: "[ ]")
        #expect(received?.sourceRange == marker)
        #expect(received?.lineRange == (source as NSString).lineRange(for: marker))
        #expect(fixture.published() == source)
    }

    @Test(arguments: [false, true])
    func helpersOffKeepsHostActivationWithoutNativeMutation(editable: Bool) async throws {
        let source = "- [ ] Item\n"
        var activations: [MarkdownTaskCheckboxActivation] = []
        let fixture = try ReadOnlyTaskCheckboxTests().makeFixture(source,
            checkboxRange: NSRange(location: 2, length: 3), allowsReadOnlyToggle: false,
            isEditable: editable, helpersEnabled: false,
            onTaskCheckboxActivation: { activations.append($0); return true })
        defer { fixture.window.orderOut(nil) }
        let undo = try #require(fixture.coordinator.undoManager(for: fixture.textView))
        undo.removeAllActions()

        #expect(fixture.textView.toggleTaskCheckboxIfHit(event: fixture.click) == true)
        await settleBinding()

        #expect(activations == [.init(sourceRange: NSRange(location: 2, length: 3),
            lineRange: NSRange(location: 0, length: (source as NSString).length),
            isChecked: false, isEditable: editable)])
        #expect(fixture.textView.string == source)
        #expect(fixture.published() == source)
        #expect(!undo.canUndo)
    }

    private func settleBinding() async {
        for _ in 0..<4 {
            await withCheckedContinuation { continuation in
                DispatchQueue.main.async { continuation.resume() }
            }
        }
    }
}
