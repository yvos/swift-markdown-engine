//
//  MarkdownEditorPointerInteraction.swift
//  MarkdownEngine
//  Added to the NoFray fork on 2026-09-04 under Apache-2.0; see FORK_CHANGES.md.
//

import AppKit

/// A pointer interaction recognized by the editor for host-level coordination.
///
/// Use ``NativeTextViewWrapper/onPointerInteraction`` when an embedding view
/// needs to distinguish editor interactions without layering a SwiftUI tap
/// gesture over the native text view.
public enum MarkdownEditorPointerInteraction: Sendable, Equatable {
    /// The engine consumed a press on a rendered task checkbox.
    case taskCheckbox
    /// AppKit or the engine recognized the press as link navigation.
    case link
    /// An unmodified, stationary primary click activated ordinary content.
    case content
}

/// Source-coordinate companion to ``MarkdownEditorPointerInteraction``.
/// `hitRange` is nil when the display-to-source conversion is ambiguous.
public struct MarkdownSourcePointerInteraction: Sendable, Equatable {
    public let documentID: String
    public let sourceRevision: Int
    public let kind: MarkdownEditorPointerInteraction
    public let hitRange: NSRange?

    public init(documentID: String, sourceRevision: Int, kind: MarkdownEditorPointerInteraction, hitRange: NSRange?) {
        self.documentID = documentID
        self.sourceRevision = sourceRevision
        self.kind = kind
        self.hitRange = hitRange
    }
}

/// Per-mouse-down classification state. Keeping delivery in one session makes
/// AppKit's delegate path and the dropped-link fallback converge on one report.
struct NativePointerInteractionSession {
    private let beganOnLink: Bool
    private let canActivateContent: Bool
    private let onInteraction: ((MarkdownEditorPointerInteraction) -> Void)?
    private let sourceInteraction: MarkdownSourcePointerInteraction?
    private let onSourceInteraction: ((MarkdownSourcePointerInteraction) -> Void)?
    private var didReport = false

    init(
        event: NSEvent,
        beganOnLink: Bool,
        onInteraction: ((MarkdownEditorPointerInteraction) -> Void)?,
        sourceInteraction: MarkdownSourcePointerInteraction? = nil,
        onSourceInteraction: ((MarkdownSourcePointerInteraction) -> Void)? = nil
    ) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        self.beganOnLink = beganOnLink
        self.canActivateContent = event.type == .leftMouseDown
            && event.clickCount == 1
            && modifiers.isEmpty
        self.onInteraction = onInteraction
        self.sourceInteraction = sourceInteraction
        self.onSourceInteraction = onSourceInteraction
    }

    mutating func taskCheckboxWasConsumed() {
        report(.taskCheckbox)
    }

    mutating func complete(
        linkDidNavigate: Bool,
        linkWasHandled: Bool,
        travel: CGFloat,
        selectionLength: Int
    ) {
        if linkDidNavigate {
            report(.link)
            return
        }
        guard canActivateContent,
              beganOnLink == false,
              linkWasHandled == false,
              travel < 2,
              selectionLength == 0 else { return }
        report(.content)
    }

    private mutating func report(_ interaction: MarkdownEditorPointerInteraction) {
        guard didReport == false else { return }
        didReport = true
        onInteraction?(interaction)
        if let sourceInteraction {
            onSourceInteraction?(MarkdownSourcePointerInteraction(
                documentID: sourceInteraction.documentID,
                sourceRevision: sourceInteraction.sourceRevision,
                kind: interaction,
                hitRange: sourceInteraction.hitRange
            ))
        }
    }
}
