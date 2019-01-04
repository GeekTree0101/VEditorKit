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

public class VEditorTextNode: ASEditableTextNode, ASEditableTextNodeDelegate {
    
    public var isEdit: Bool = true
    
    public var textStorage: VEditorTextStorage? {
        return self.textView.textStorage as? VEditorTextStorage
    }
    
    public required init(_ isEdit: Bool,
                         placeholderText: String?,
                         attributedText: NSAttributedString) {
        self.isEdit = isEdit
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
    
    public func editableTextNodeShouldBeginEditing(_ editableTextNode: ASEditableTextNode) -> Bool {
        return self.isEdit
    }
    
    public func editableTextNodeDidBeginEditing(_ editableTextNode: ASEditableTextNode) {
  
    }
    
    public func editableTextNodeDidFinishEditing(_ editableTextNode: ASEditableTextNode) {
     
    }
    
    public func editableTextNodeDidUpdateText(_ editableTextNode: ASEditableTextNode) {
        self.supernode?.setNeedsLayout()
    }
}
