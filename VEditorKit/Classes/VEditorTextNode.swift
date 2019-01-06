//
//  VEditorTextNode.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import RxCocoa
import RxSwift

extension Reactive where Base: VEditorTextNode {
    
    internal var currentLocationXMLTags: Observable<[String]> {
        return base.currentLocationXMLTagsRelay
            .throttle(0.1, scheduler: MainScheduler.instance)
    }
    
    internal var caretRect: Observable<CGRect> {
        return base.caretRectRelay
            .distinctUntilChanged()
            .throttle(0.1, scheduler: MainScheduler.instance)
    }
}

public class VEditorTextNode: ASEditableTextNode, ASEditableTextNodeDelegate {
    
    public var isEdit: Bool = true
    
    public var textStorage: VEditorTextStorage? {
        return self.textView.textStorage as? VEditorTextStorage
    }
    
    public var currentTypingAttribute: [NSAttributedString.Key: Any] = [:] {
        didSet {
            self.typingAttributes = currentTypingAttribute.typingAttribute()
            self.textStorage?.currentTypingAttribute = currentTypingAttribute
        }
    }
    
    private let rule: VEditorRule
    internal let currentLocationXMLTagsRelay = PublishRelay<[String]>()
    internal let caretRectRelay = PublishRelay<CGRect>()
    
    public required init(_ rule: VEditorRule,
                         isEdit: Bool,
                         placeholderText: String?,
                         attributedText: NSAttributedString) {
        self.isEdit = isEdit
        self.rule = rule
        let textStorage = VEditorTextStorage.init()
        textStorage.setAttributedString(attributedText)
        let textKitComponents: ASTextKitComponents =
            .init(textStorage: textStorage,
                  textContainerSize: .zero,
                  layoutManager: .init())
        let placeholderTextKit: ASTextKitComponents =
            .init(attributedSeedString: nil,
                  textContainerSize: .zero)
        super.init(textKitComponents: textKitComponents,
                   placeholderTextKitComponents: placeholderTextKit)
        super.delegate = self
    }
    
    override public func didLoad() {
        super.didLoad()
        self.currentTypingAttribute = rule.defaultAttribute()
        self.supernode?.setNeedsLayout()
        self.setNeedsLayout()
    }
    
    public func editableTextNodeShouldBeginEditing(_ editableTextNode: ASEditableTextNode) -> Bool {
        return self.isEdit
    }
    
    public func editableTextNodeDidBeginEditing(_ editableTextNode: ASEditableTextNode) {
  
    }
    
    public func editableTextNodeDidFinishEditing(_ editableTextNode: ASEditableTextNode) {
     
    }
    
    public func editableTextNodeDidChangeSelection(_ editableTextNode: ASEditableTextNode,
                                                   fromSelectedRange: NSRange,
                                                   toSelectedRange: NSRange,
                                                   dueToEditing: Bool) {
        if !dueToEditing {
            // move cursor and pick attribute on cursor
            let attributes = self.textStorage?
                .attributes(at: max(toSelectedRange.location - 1, 0),
                            effectiveRange: nil)
            
            guard let xmlTags = attributes?[VEditorAttributeKey] as? [String] else {
                return
            }
            self.currentLocationXMLTagsRelay.accept(xmlTags)
        } else {
            guard let textPostion: UITextPosition = editableTextNode.textView.selectedTextRange?.end else {
                return
            }
            let caretRect: CGRect = editableTextNode.textView.caretRect(for: textPostion)
            self.caretRectRelay.accept(caretRect)
        }
    }
    
    public func editableTextNodeDidUpdateText(_ editableTextNode: ASEditableTextNode) {
        self.textStorage?.didUpdateText(self)
    }
    
    public func updateCurrentTypingAttribute(_ attribute: VEditorStyleAttribute, isBlock: Bool) {
        self.textStorage?.updateCurrentTypingAttribute(self, attribute: attribute, isBlock: isBlock)
    }
}
