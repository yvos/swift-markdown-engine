//
//  PointerInteractionTests.swift
//  MarkdownEngineTests
//  Added to the NoFray fork on 2026-09-04 under Apache-2.0; see FORK_CHANGES.md.
//

import AppKit
import SwiftUI
import Testing
@testable import MarkdownEngine

@MainActor
@Suite("Host pointer interaction reporting")
struct PointerInteractionTests {
    @Test("The public callback is optional and defaults to nil")
    func callbackDefaultsToNil() {
        let wrapper = NativeTextViewWrapper(text: .constant(""))

        #expect(wrapper.onPointerInteraction == nil)
    }

    @Test("A navigated wiki link is reported without changing delegate consumption")
    func wikiLinkKeepsEngineNavigation() throws {
        let fixture = makeLinkFixture()

        let engineConsumed = fixture.coordinator.textView(
            fixture.textView,
            clickedOnLink: "wiki-id",
            at: 0
        )
        let interactions = try completeLinkInteraction(fixture)

        #expect(engineConsumed)
        #expect(interactions == [.link])
    }

    @Test("A navigated URL is reported while AppKit remains responsible for opening it")
    func urlKeepsAppKitNavigation() throws {
        let fixture = makeLinkFixture()
        let url = try #require(URL(string: "https://example.com"))

        let engineConsumed = fixture.coordinator.textView(
            fixture.textView,
            clickedOnLink: url,
            at: 0
        )
        let interactions = try completeLinkInteraction(fixture)

        #expect(engineConsumed == false)
        #expect(interactions == [.link])
    }

    @Test("An ordinary stationary primary content click is reported")
    func stationaryPrimaryClickReportsContent() throws {
        var interactions: [MarkdownEditorPointerInteraction] = []
        var session = NativePointerInteractionSession(
            event: try mouseEvent(),
            beganOnLink: false,
            onInteraction: { interactions.append($0) }
        )

        session.complete(
            linkDidNavigate: false,
            linkWasHandled: false,
            travel: 0,
            selectionLength: 0
        )

        #expect(interactions == [.content])
    }

    @Test("Drags, selections, modifier clicks, secondary clicks, and multi-clicks do not activate content")
    func nonContentClicksAreFiltered() throws {
        let cases: [(event: NSEvent, travel: CGFloat, selectionLength: Int)] = [
            (try mouseEvent(modifiers: .command), 0, 0),
            (try mouseEvent(), 3, 0),
            (try mouseEvent(), 0, 1),
            (try mouseEvent(type: .rightMouseDown), 0, 0),
            (try mouseEvent(clickCount: 2), 0, 0),
        ]

        for testCase in cases {
            var interactions: [MarkdownEditorPointerInteraction] = []
            var session = NativePointerInteractionSession(
                event: testCase.event,
                beganOnLink: false,
                onInteraction: { interactions.append($0) }
            )

            session.complete(
                linkDidNavigate: false,
                linkWasHandled: false,
                travel: testCase.travel,
                selectionLength: testCase.selectionLength
            )

            #expect(interactions.isEmpty)
        }
    }

    @Test("A non-navigating link edit-zone press is not reported as content")
    func linkEditZoneIsNotContent() throws {
        var interactions: [MarkdownEditorPointerInteraction] = []
        var session = NativePointerInteractionSession(
            event: try mouseEvent(),
            beganOnLink: true,
            onInteraction: { interactions.append($0) }
        )

        session.complete(
            linkDidNavigate: false,
            linkWasHandled: true,
            travel: 0,
            selectionLength: 0
        )

        #expect(interactions.isEmpty)
    }

    @Test("Fallback and repeated completion deliver at most once")
    func duplicateFallbackDeliversOnce() throws {
        var interactions: [MarkdownEditorPointerInteraction] = []
        var session = NativePointerInteractionSession(
            event: try mouseEvent(),
            beganOnLink: true,
            onInteraction: { interactions.append($0) }
        )

        session.complete(
            linkDidNavigate: true,
            linkWasHandled: true,
            travel: 0,
            selectionLength: 0
        )
        session.complete(
            linkDidNavigate: true,
            linkWasHandled: true,
            travel: 0,
            selectionLength: 0
        )
        session.taskCheckboxWasConsumed()

        #expect(interactions == [.link])
    }

    @Test("A nil callback accepts every classification path without delivery")
    func nilCallbackIsCompatible() throws {
        var session = NativePointerInteractionSession(
            event: try mouseEvent(),
            beganOnLink: false,
            onInteraction: nil
        )

        session.complete(
            linkDidNavigate: false,
            linkWasHandled: false,
            travel: 0,
            selectionLength: 0
        )
        session.taskCheckboxWasConsumed()
    }

    private func makeLinkFixture() -> (
        textView: NativeTextView,
        coordinator: NativeTextViewCoordinator
    ) {
        let coordinator = NativeTextViewCoordinator(
            text: .constant("Link"),
            fontName: NSFont.systemFont(ofSize: 14).fontName,
            fontSize: 14,
            isWikiLinkActive: .constant(false),
            onLinkClick: nil,
            onInlineSelectionChange: nil
        )
        let textView = NativeTextView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        textView.string = "Link"
        textView.isEditable = false
        textView.delegate = coordinator
        coordinator.textView = textView
        return (textView, coordinator)
    }

    private func completeLinkInteraction(
        _ fixture: (textView: NativeTextView, coordinator: NativeTextViewCoordinator)
    ) throws -> [MarkdownEditorPointerInteraction] {
        var interactions: [MarkdownEditorPointerInteraction] = []
        var session = NativePointerInteractionSession(
            event: try mouseEvent(),
            beganOnLink: true,
            onInteraction: { interactions.append($0) }
        )
        session.complete(
            linkDidNavigate: fixture.textView.linkClickDidNavigate,
            linkWasHandled: fixture.textView.linkClickDidFire,
            travel: 0,
            selectionLength: 0
        )
        return interactions
    }

    private func mouseEvent(
        type: NSEvent.EventType = .leftMouseDown,
        modifiers: NSEvent.ModifierFlags = [],
        clickCount: Int = 1
    ) throws -> NSEvent {
        guard let event = NSEvent.mouseEvent(
            with: type,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 1,
            clickCount: clickCount,
            pressure: 1
        ) else {
            throw FixtureError.missingMouseEvent
        }
        return event
    }

    private enum FixtureError: Error {
        case missingMouseEvent
    }
}
