import AppKit
import SwiftUI
import Testing
@testable import MarkdownEngine

@MainActor
@Suite("Relative Markdown link routing")
struct RelativeMarkdownLinkTests {
    private let source = "[Task](a.md)"
    private let target = "a.md"

    @Test(arguments: [true, false])
    func routedTargetReachesHostFromEditableAndReadOnlyViews(isEditable: Bool) async throws {
        var received: [String] = []
        let fixture = try makeFixture(
            routesToHost: true,
            isEditable: isEditable,
            onLinkClick: { received.append($0) }
        )
        let link = try #require(fixture.linkValue as? String)

        #expect(link == target)
        #expect(
            fixture.coordinator.textView(
                fixture.textView,
                clickedOnLink: link,
                at: fixture.linkRange.location + 1
            )
        )
        await flushMainQueue()
        #expect(received == [target])
    }

    @Test
    func disabledRoutingKeepsURLNavigationWithAppKit() throws {
        var received: [String] = []
        let fixture = try makeFixture(
            routesToHost: false,
            isEditable: true,
            onLinkClick: { received.append($0) }
        )
        let url = try #require(fixture.linkValue as? URL)

        #expect(url.absoluteString == "https://a.md")
        #expect(
            fixture.coordinator.textView(
                fixture.textView,
                clickedOnLink: url,
                at: fixture.linkRange.location + 1
            ) == false
        )
        #expect(received.isEmpty)
    }

    @Test
    func routedTargetWithoutCallbackIsConsumed() throws {
        let fixture = try makeFixture(
            routesToHost: true,
            isEditable: false,
            onLinkClick: nil
        )
        let link = try #require(fixture.linkValue as? String)

        #expect(
            fixture.coordinator.textView(
                fixture.textView,
                clickedOnLink: link,
                at: fixture.linkRange.location + 1
            )
        )
    }

    private func makeFixture(
        routesToHost: Bool,
        isEditable: Bool,
        onLinkClick: ((String) -> Void)?
    ) throws -> (
        coordinator: NativeTextViewCoordinator,
        textView: NativeTextView,
        linkValue: Any,
        linkRange: NSRange
    ) {
        let configuration = MarkdownEditorConfiguration(
            routesRelativeMarkdownLinksToHost: routesToHost
        )
        let wrapper = NativeTextViewWrapper(
            text: .constant(source),
            configuration: configuration,
            isEditable: isEditable,
            onLinkClick: onLinkClick
        )
        let coordinator = wrapper.makeCoordinator()
        let textView = NativeTextView(frame: NSRect(x: 0, y: 0, width: 240, height: 100))
        textView.string = source
        textView.configuration = configuration
        textView.isEditable = isEditable
        textView.delegate = coordinator
        coordinator.textView = textView

        let styledLink = try #require(
            MarkdownASTStyler.styleAttributes(
                text: source,
                fontName: NSFont.systemFont(ofSize: 14).fontName,
                fontSize: 14,
                configuration: configuration
            ).first { $0.attributes[.link] != nil }
        )
        let value = try #require(styledLink.attributes[.link])
        let storage = try #require(textView.textStorage)
        storage.addAttributes(styledLink.attributes, range: styledLink.range)

        return (coordinator, textView, value, styledLink.range)
    }

    private func flushMainQueue() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}
