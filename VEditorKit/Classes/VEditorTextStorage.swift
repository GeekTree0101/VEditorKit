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
    
    private var internalAttributedString: NSMutableAttributedString = .init()
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
    
    override public func fixAttributes(in range: NSRange) {
        // TODO: real time regex base attribute update
        super.fixAttributes(in: range)
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
    }
    
    public func updateCurrentTypingAttribute(_ textNode: VEditorTextNode,
                                             attribute: VEditorStyleAttribute,
                                             isBlock: Bool) {
        if isBlock {
            let blockRange = self.paragraphStyleRange(textNode.selectedRange)
            self.status = .paste
            self.setAttributes(attribute, range: blockRange)
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
    
    public func paragraphStyleRange(_ range: NSRange) -> NSRange {
        return NSString(string: self.internalAttributedString.string)
            .paragraphRange(for: range)
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
