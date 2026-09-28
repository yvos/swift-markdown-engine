import AppKit

extension NativeTextViewCoordinator {
    func handleTaskCheckboxActivation(displayRange: NSRange, isChecked: Bool, in view: NSTextView) -> Bool {
        guard let onTaskCheckboxActivation,
              let sourceRange = WikiLinkService.storageRange(forDisplayRange: displayRange,
                  metadata: wikiLinkMetadata) else { return false }
        let source = (lastComputedStorage.isEmpty ? text : lastComputedStorage) as NSString
        guard sourceRange.length == 3, NSMaxRange(sourceRange) <= source.length else { return false }
        let marker = source.substring(with: sourceRange)
        guard marker == (isChecked ? "[x]" : "[ ]") || (isChecked && marker == "[X]") else { return false }
        return onTaskCheckboxActivation(.init(sourceRange: sourceRange,
            lineRange: source.lineRange(for: sourceRange), isChecked: isChecked, isEditable: view.isEditable))
    }
}
