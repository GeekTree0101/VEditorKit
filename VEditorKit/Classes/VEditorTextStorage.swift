//
//  VEditorTextStorage.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit

final internal class VEditorTextStorage: NSTextStorage, NSTextStorageDelegate {
    
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
    
    override var string: String {
        return self.internalAttributedString.string
    }
    
    override init() {
        super.init()
        super.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func attributes(at location: Int,
                             effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        guard self.internalAttributedString.length > location else { return [:] }
        return internalAttributedString.attributes(at: location, effectiveRange: range)
    }
    
    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?,
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
    
    override func setAttributedString(_ attrString: NSAttributedString) {
        self.status = .paste
        super.setAttributedString(attrString)
    }
    
    override func processEditing() {
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
    
    override func fixAttributes(in range: NSRange) {
        // TODO: real time regex base attribute update
        super.fixAttributes(in: range)
    }
    
    override func replaceCharacters(in range: NSRange, with str: String) {
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
    
    func textStorage(_ textStorage: NSTextStorage,
                     didProcessEditing editedMask: NSTextStorage.EditActions,
                     range editedRange: NSRange,
                     changeInLength delta: Int) {
        self.status = .none
    }
}

extension VEditorTextStorage {
    
    public func updateCurrentLocationAttributesIfNeeds(_ textNode: VEditorTextNode) {
        
        self.prevCursorLocation = textNode.selectedRange.location
    }
    
    public func replaceAttributesIfNeeds(_ textNode: VEditorTextNode) {
        guard textNode.selectedRange.length > 1 else { return }
        self.status = .paste
        self.setAttributes(self.currentTypingAttribute,
                           range: textNode.selectedRange)
    }
    
    private func isFlyToTargetLocationWithoutTyping(_ textNode: VEditorTextNode) -> Bool {
        return abs(textNode.selectedRange.location - self.prevCursorLocation) > 1
    }
    
    public func paragraphStyleRange(_ textNode: VEditorTextNode) -> NSRange {
        return NSString(string: self.internalAttributedString.string)
            .paragraphRange(for: textNode.selectedRange)
    }
}
