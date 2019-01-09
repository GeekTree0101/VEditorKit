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
    
    public var currentLocationXMLTags: Observable<[String]> {
        return base.currentLocationXMLTagsRelay
            .throttle(0.1, scheduler: MainScheduler.instance)
    }
    
    public var becomeActive: Observable<Void> {
        return base.becomeActiveRelay.asObservable()
    }
    
    internal var caretRect: Observable<CGRect> {
        return base.caretRectRelay
            .distinctUntilChanged()
            .throttle(0.1, scheduler: MainScheduler.instance)
    }
    
    internal var generateLinkPreview: Observable<(URL, Int)> {
        return base.generateLinkPreviewRelay.asObservable()
    }
    
    internal var textEmptied: Observable<Void> {
        return base.textEmptiedRelay.asObservable()
    }
}

open class VEditorTextNode: ASEditableTextNode, ASEditableTextNodeDelegate {
    
    open var textStorage: VEditorTextStorage? {
        return self.textView.textStorage as? VEditorTextStorage
    }
    
    open var currentTypingAttribute: [NSAttributedString.Key: Any] = [:] {
        didSet {
            self.typingAttributes = currentTypingAttribute.typingAttribute()
            self.textStorage?.currentTypingAttribute = currentTypingAttribute
        }
    }
    
    open var isEdit: Bool = true
    open weak var regexDelegate: VEditorRegexApplierDelegate!
    open var automaticallyGenerateLinkPreview: Bool = false
    open let becomeActiveRelay = PublishRelay<Void>()
    
    open var linkRegexPattern: String? {
        // default: "((?:http|https)://)(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
        get {
            return self.textStorage?.urlPattern
        }
        set(pattern) {
            guard let pattern = pattern else { return }
            self.textStorage?.urlPattern = pattern
        }
    }
    
    internal let rule: VEditorRule
    internal let currentLocationXMLTagsRelay = PublishRelay<[String]>()
    internal let caretRectRelay = PublishRelay<CGRect>()
    internal let generateLinkPreviewRelay = PublishRelay<(URL, Int)>()
    internal let textEmptiedRelay = PublishRelay<Void>()
    
    public required init(_ rule: VEditorRule,
                         isEdit: Bool,
                         placeholderText: NSAttributedString?,
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
            .init(attributedSeedString: placeholderText,
                  textContainerSize: .zero)
        
        super.init(textKitComponents: textKitComponents,
                   placeholderTextKitComponents: placeholderTextKit)
        super.delegate = self
    }
    
    override open func didLoad() {
        super.didLoad()
        self.currentTypingAttribute = rule.defaultAttribute()
        if let linkXML = rule.linkStyleXMLTag,
            let attrStyle = rule.paragraphStyle(linkXML, attributes: [:]) {
            self.textView.linkTextAttributes = attrStyle.attributes
        }
        
        self.textStorage?.replaceAttributeWithRegexPattenIfNeeds(self)
    }
    
    override open func calculatedLayoutDidChange() {
        super.calculatedLayoutDidChange()
        guard let expectedHeight = self.textStorage?
            .internalAttributedString.size().height,
            expectedHeight > self.frame.height else {
                // NOTE: pass setNeedsLayout
                return
        }
        // NOTE: Unsyncronized frame height between storage with viewFrame
        self.setNeedsLayout()
        self.supernode?.setNeedsLayout()
    }
    
    open func editableTextNodeShouldBeginEditing(_ editableTextNode: ASEditableTextNode) -> Bool {
        return self.isEdit
    }
    
    open func editableTextNodeDidBeginEditing(_ editableTextNode: ASEditableTextNode) {
        self.becomeActiveRelay.accept(())
    }
    
    open func editableTextNode(_ editableTextNode: ASEditableTextNode,
                               shouldChangeTextIn range: NSRange,
                               replacementText text: String) -> Bool {
        
        if (text == "\n" || text == " "),
            let context = self.textStorage?
                .automaticallyApplyLinkAttribute(self) {
            guard self.automaticallyGenerateLinkPreview else { return true }
            self.generateLinkPreviewRelay.accept(context)
            return false
        }
        
        return true
    }
    
    open func editableTextNodeDidChangeSelection(_ editableTextNode: ASEditableTextNode,
                                                 fromSelectedRange: NSRange,
                                                 toSelectedRange: NSRange,
                                                 dueToEditing: Bool) {
        if !dueToEditing {
            // NOTE: Move cursor and pick attribute on cursor
            let attributes = self.textStorage?
                .attributes(at: max(toSelectedRange.location - 1, 0),
                            effectiveRange: nil)
            
            // NOTE: Block current location attributes during drag-selection
            guard toSelectedRange.length < 1 else { return }
            
            guard let xmlTags = attributes?[VEditorAttributeKey] as? [String] else {
                return
            }
            self.currentLocationXMLTagsRelay.accept(xmlTags)
            self.textStorage?.triggerTouchEventIfNeeds(self)
        } else {
            guard let textPostion: UITextPosition =
                editableTextNode.textView.selectedTextRange?.end else {
                return
            }
            let caretRect: CGRect = editableTextNode.textView.caretRect(for: textPostion)
            self.caretRectRelay.accept(caretRect)
        }
    }
    
    open func forceFetchCurrentLocationAttribute() {
        let attributes = self.textStorage?
            .attributes(at: max(self.selectedRange.location - 1, 0),
                        effectiveRange: nil)
        guard let xmlTags = attributes?[VEditorAttributeKey] as? [String] else {
            return
        }
        self.currentLocationXMLTagsRelay.accept(xmlTags)
    }
    
    open func editableTextNodeDidUpdateText(_ editableTextNode: ASEditableTextNode) {
        self.textStorage?.didUpdateText(self)
        
        guard self.isDisplayingPlaceholder() else { return }
        self.textEmptiedRelay.accept(())
    }
    
    open func updateCurrentTypingAttribute(_ attribute: VEditorStyleAttribute,
                                           isBlock: Bool) {
        self.textStorage?
            .updateCurrentTypingAttribute(self,
                                          attribute: attribute,
                                          isBlock: isBlock)
    }
}
