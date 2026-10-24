import Foundation

public enum NagramChineseConversion: Int {
    case off = 0
    case simplified = 1
    case traditional = 2

    var transform: StringTransform? {
        switch self {
        case .off:
            return nil
        case .simplified:
            return StringTransform(rawValue: "Hant-Hans")
        case .traditional:
            return StringTransform(rawValue: "Hans-Hant")
        }
    }
}

public enum NagramText {
    private static func isCJK(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x2E80 ... 0x2FDF, 0x3040 ... 0x30FF, 0x3100 ... 0x312F, 0x31A0 ... 0x31FF, 0x3400 ... 0x4DBF, 0x4E00 ... 0x9FFF, 0xF900 ... 0xFAFF, 0x20000 ... 0x2FFFF:
            return true
        default:
            return false
        }
    }

    private static func isLatin(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x30 ... 0x39, 0x41 ... 0x5A, 0x61 ... 0x7A, 0xC0 ... 0x24F:
            return true
        default:
            return false
        }
    }

    public static func panguEdits(_ text: String, skipping: [Range<Int>] = []) -> [NagramTextEdit] {
        let string = text as NSString
        var edits: [NagramTextEdit] = []
        var previous: Unicode.Scalar?
        var index = 0
        while index < string.length {
            let range = string.rangeOfComposedCharacterSequence(at: index)
            let piece = string.substring(with: range)
            guard let scalar = piece.unicodeScalars.first else {
                index = range.location + range.length
                continue
            }
            if let previous = previous, !skipping.contains(where: { $0.contains(range.location) || $0.contains(range.location - 1) }) {
                if (isCJK(previous) && isLatin(scalar)) || (isLatin(previous) && isCJK(scalar)) {
                    edits.append(NagramTextEdit(range: NSRange(location: range.location, length: 0), replacement: " "))
                }
            }
            previous = scalar
            index = range.location + range.length
        }
        return edits
    }

    public static func chineseEdits(_ text: String, conversion: NagramChineseConversion) -> [NagramTextEdit] {
        guard let transform = conversion.transform else {
            return []
        }
        let string = text as NSString
        var edits: [NagramTextEdit] = []
        var index = 0
        while index < string.length {
            let range = string.rangeOfComposedCharacterSequence(at: index)
            let piece = string.substring(with: range)
            if let scalar = piece.unicodeScalars.first, isCJK(scalar), let converted = piece.applyingTransform(transform, reverse: false), converted != piece {
                edits.append(NagramTextEdit(range: range, replacement: converted))
            }
            index = range.location + range.length
        }
        return edits
    }

    public static func readingStages(_ text: String, codeRanges: [Range<Int>]) -> [[NagramTextEdit]] {
        var stages: [[NagramTextEdit]] = []
        var current = text
        let conversion = NagramChineseConversion(rawValue: NagramOptions.readingChinese.value) ?? .off
        if conversion != .off {
            let edits = chineseEdits(current, conversion: conversion)
            if !edits.isEmpty {
                current = NagramFilter.apply(edits: edits, to: current)
                stages.append(edits)
            }
        }
        if NagramOptions.readingSpacing.value {
            let edits = panguEdits(current, skipping: codeRanges)
            if !edits.isEmpty {
                stages.append(edits)
            }
        }
        return stages
    }

    public static func sendingStages(_ text: String, editing: Bool, protectedRanges: [Range<Int>]) -> [[NagramTextEdit]] {
        var stages: [[NagramTextEdit]] = []
        var current = text
        let conversion = NagramChineseConversion(rawValue: NagramOptions.inputChinese.value) ?? .off
        if conversion != .off {
            let edits = chineseEdits(current, conversion: conversion).filter { edit in
                !protectedRanges.contains(where: { $0.contains(edit.range.location) })
            }
            if !edits.isEmpty {
                current = NagramFilter.apply(edits: edits, to: current)
                stages.append(edits)
            }
        }
        if editing ? NagramOptions.spaceOnEdit.value : NagramOptions.spaceOnSend.value {
            let edits = panguEdits(current, skipping: protectedRanges)
            if !edits.isEmpty {
                stages.append(edits)
            }
        }
        return stages
    }

    public static func apply(stages: [[NagramTextEdit]], to text: String) -> String {
        var current = text
        for stage in stages {
            current = NagramFilter.apply(edits: stage, to: current)
        }
        return current
    }

    public static func remap(_ range: Range<Int>, stages: [[NagramTextEdit]]) -> Range<Int>? {
        var current: Range<Int>? = range
        for stage in stages {
            guard let value = current else {
                return nil
            }
            current = NagramFilter.remap(value, edits: stage)
        }
        return current
    }
}
