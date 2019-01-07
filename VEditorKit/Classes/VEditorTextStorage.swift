//
//  VEditorTextStorage.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit

final public class VEditorTextStorage: NSTextStorage {
    
    enum TypingStstus {
        case typing
        case remove
        case paste
        case none
    }
    
    internal var status: TypingStstus = .none
    internal var currentTypingAttribute: [NSAttributedString.Key: Any] = [:]
    internal var internalAttributedString: NSMutableAttributedString = .init()
    private var prevCursorLocation: Int = 0
    
    override public var string: String {
        return self.internalAttributedString.string
    }
    
    override public func attributes(at location: Int,
                             effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        guard self.internalAttributedString.length > location else { return [:] }
        return internalAttributedString.attributes(at: location, effectiveRange: range)
    }
    
    override public func setAttributes(_ attrs: [NSAttributedString.Key: Any]?,
                                range: NSRange) {
        guard internalAttributedString.length > range.location else { return }
        
        switch status {
        case .typing, .paste: break
        default: return
        }
        
        self.beginEditing()
        self.internalAttributedString.setAttributes(attrs, range: range)
        self.edited(.editedAttributes, range: range, changeInLength: 0)
        self.endEditing()
    }
    
    override public func setAttributedString(_ attrString: NSAttributedString) {
        self.status = .paste
        super.setAttributedString(attrString)
    }
    
    override public func processEditing() {
        switch status {
        case .typing:
            self.internalAttributedString
                .setAttributes(self.currentTypingAttribute,
                               range: self.editedRange)
        default:
            break
        }
        super.processEditing()
    }
    
    override public func replaceCharacters(in range: NSRange, with str: String) {
        if self.status != .paste {
            self.status = str.isEmpty ? .remove: .typing
        }
        
        self.beginEditing()
        self.internalAttributedString.replaceCharacters(in: range, with: str)
        self.edited(.editedCharacters,
                    range: range,
                    changeInLength: str.count - range.length)
        self.endEditing()
    }
}

extension VEditorTextStorage {
    
    public func didUpdateText(_ textNode: VEditorTextNode) {
        self.status = .none
        textNode.supernode?.setNeedsLayout()
        self.replaceAttributeWithRegexPattenIfNeeds(textNode)
    }
    
    public func updateCurrentTypingAttribute(_ textNode: VEditorTextNode,
                                             attribute: VEditorStyleAttribute,
                                             isBlock: Bool) {
        if isBlock {
            let blockRange = self.paragraphBlockRange(textNode.selectedRange)
            self.status = .paste
            self.setAttributes(attribute, range: blockRange)
            self.replaceAttributeWithRegexPattenIfNeeds(textNode, customRange: blockRange)
            textNode.setNeedsLayout()
        } else {
            self.setAttributes(attribute, range: textNode.selectedRange)
        }
        
        textNode.currentTypingAttribute = attribute
        self.replaceAttributesIfNeeds(textNode)
    }
    
    public func replaceAttributesIfNeeds(_ textNode: VEditorTextNode) {
        guard textNode.selectedRange.length > 1 else { return }
        self.status = .paste
        self.setAttributes(self.currentTypingAttribute,
                           range: textNode.selectedRange)
    }
    
    /**
     Convert to paragraph block range
     
     - parameters:
     - range: recommend parameter is selectedRange.
     
     - returns: Paragraph Block Range
     */
    public func paragraphBlockRange(_ range: NSRange) -> NSRange {
        return NSString(string: self.internalAttributedString.string)
            .paragraphRange(for: range)
    }
    
    /**
     Trigger Regex Pattern Base AttributedText Touch Event Hanlder
     
     - important: If you wanna use it, try to set VEditorRegexApplierDelegate on textNode, MainThread Only!
     
     - parameters:
     - textNode: VEditorTextNode
     - customRange: default is VEditorTextNode selectedRange
     */
    public func triggerTouchEventIfNeeds(_ textNode: VEditorTextNode, customRange: NSRange? = nil) {
        guard let regexDelegate = textNode.regexDelegate, !textNode.isEdit else { return }
        let location = (customRange?.location ?? textNode.selectedRange.location)
        let attributes =
            self.attributes(at: max(0, location - 1), effectiveRange: nil)
        
        if let url = attributes[.link] as? URL {
            regexDelegate.handlURLTouchEvent(url)
            return
        }
        let patternKeys: [NSAttributedString.Key] =
            regexDelegate.allPattern.map({ NSAttributedString.Key.init(rawValue: $0) })
        
        for key in patternKeys {
            if let value = attributes[key] {
                regexDelegate.handlePatternTouchEvent(key.rawValue, value: value)
            }
        }
    }
    
    internal func automaticallyApplyLinkAttribute(_ textNode: VEditorTextNode) -> (URL, Int)? {
        let pattern: String = "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
        guard let regex = try? NSRegularExpression.init(pattern: pattern, options: []) else { return nil }
        let blockRange = self.paragraphBlockRange(textNode.selectedRange)
        let text: String = self.internalAttributedString.string
        
        for match in regex.matches(in: text, options: [], range: blockRange) {
            
            guard let strRange = Range(match.range, in: text) else {
                // NOTE: Match not found or failed to generate stringRange
                continue
            }
            
            guard textNode.selectedRange.location == match.range.location + match.range.length else {
                // NOTE: is not last link
                continue
            }
            
            guard case let urlString = String(text[strRange]), let url = URL(string: urlString) else {
                // NOTE: Failed to convert URL from string
                continue
            }
            
            if let linkXML = textNode.rule.linkStyleXMLTag,
                let linkStyle = textNode.rule.paragraphStyle(linkXML, attributes: [:]) {
                let linkAttribute = linkStyle
                    .byAdding([.link(url)])
                    .byAdding([.extraAttributes([VEditorAttributeKey: [linkXML] as Any])])
                    .attributes
                self.internalAttributedString.setAttributes(linkAttribute, range: match.range)
            }
            
            return (url, textNode.selectedRange.location)
        }
        
        return nil
    }

    /**
     Replace attributedStyle with Regex Pattern
     
     - important: If you wanna use it, try to set VEditorRegexApplierDelegate on textNode, MainThread Only!
     
     - parameters:
     - textNode: VEditorTextNode
     - customRange: default is full internalAttributedString range
     */
    public func replaceAttributeWithRegexPattenIfNeeds(_ textNode: VEditorTextNode, customRange: NSRange? = nil) {
        guard let regexDelegate = textNode.regexDelegate else { return }
        let regexs = regexDelegate.allPattern.map({ regexDelegate.regex($0) })
        let range: NSRange = customRange ?? .init(location: 0, length: self.internalAttributedString.length)
        let text: String = self.internalAttributedString.string
        
        for regex in regexs {
            let matchs: [NSTextCheckingResult] = regex.matches(in: text, options: [], range: range)
            
            guard !matchs.isEmpty,
                let attributedStyle: VEditorStyle =
                regexDelegate.paragraphStyle(pattern: regex.pattern) else { continue }
            
            
            for match in matchs {
                let matchedRange: NSRange = match.range
                guard let stringRange: Range<String.Index> =
                    Range.init(matchedRange, in: text) else { continue }
                let patternKey = NSAttributedString.Key.init(rawValue: regex.pattern)
                let matchedValue: Any = text[stringRange] as Any
                self.internalAttributedString.addAttributes(attributedStyle.attributes,
                                                            range: matchedRange)
                self.internalAttributedString.addAttribute(patternKey,
                                                           value: matchedValue,
                                                           range: matchedRange)
            }
        }
    }
}

extension Dictionary where Key == NSAttributedString.Key, Value == Any {
    
    internal func typingAttribute() -> [String: Any] {
        var dict: [String: Any] = [:]
        self.forEach({ key, value in
            dict[key.rawValue] = value
        })
        return dict
    }
}
