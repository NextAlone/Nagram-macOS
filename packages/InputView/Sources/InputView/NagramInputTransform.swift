import Foundation
import NagramCore

public extension ChatTextInputState {
    func nagramTransformed(editing: Bool) -> ChatTextInputState {
        let string = inputText as NSString
        var protected: [Range<Int>] = attributes.compactMap { attribute in
            switch attribute {
            case .pre, .code, .url, .uid, .animated, .date:
                return attribute.range
            default:
                return nil
            }
        }
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            for match in detector.matches(in: inputText, range: NSRange(location: 0, length: string.length)) {
                protected.append(match.range.location ..< match.range.location + match.range.length)
            }
        }
        if let mentions = try? NSRegularExpression(pattern: "[@#/][\\\\w_]+") {
            for match in mentions.matches(in: inputText, range: NSRange(location: 0, length: string.length)) {
                protected.append(match.range.location ..< match.range.location + match.range.length)
            }
        }
        let stages = NagramText.sendingStages(inputText, editing: editing, protectedRanges: protected)
        if stages.isEmpty {
            return self
        }
        let text = NagramText.apply(stages: stages, to: inputText)
        let updated = attributes.compactMap { attribute -> ChatTextInputAttribute? in
            guard let range = NagramText.remap(attribute.range, stages: stages) else {
                return nil
            }
            return attribute.updateRange(range)
        }
        let length = (text as NSString).length
        return ChatTextInputState(inputText: text, selectionRange: length ..< length, attributes: updated)
    }
}
