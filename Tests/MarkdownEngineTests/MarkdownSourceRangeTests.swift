import Foundation
import Testing
@testable import MarkdownEngine

struct MarkdownSourceRangeTests {
    @Test
    func displaySelectionsMapToRawUTF16OffsetsAndRejectAmbiguousLinkInteriors() {
        let source = "😀 before [[Old|opaque-id]] after"
        let state = WikiLinkService.makeDisplayState(from: source)
        let display = state.display as NSString
        let raw = source as NSString
        let displayLink = display.range(of: "[[Old]]")
        let rawLink = raw.range(of: "[[Old|opaque-id]]")
        let before = display.range(of: "before")

        #expect(WikiLinkService.storageRange(forDisplayRange: before, metadata: state.metadata)
            == raw.range(of: "before"))
        #expect(WikiLinkService.storageRange(forDisplayRange: displayLink, metadata: state.metadata) == rawLink)
        #expect(WikiLinkService.storageHitRange(atDisplayLocation: displayLink.location + 3, metadata: state.metadata)
            == rawLink)
        #expect(WikiLinkService.storageRange(
            forDisplayRange: NSRange(location: displayLink.location + 3, length: 1),
            metadata: state.metadata
        ) == nil)
    }
}
