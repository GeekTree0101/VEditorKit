//
//  VEditorTextCellNode.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import RxSwift
import RxCocoa

extension Reactive where Base: VEditorTextCellNode {
    
    var becomeActive: Observable<Void> {
        return base.textNode.rx.becomeActive.asObservable()
    }
}

open class VEditorTextCellNode: ASCellNode {
    
    public var insets: UIEdgeInsets = .zero
    public var isEdit: Bool = true
    public var textNode: VEditorTextNode
    public let disposeBag = DisposeBag()
    
    public required init(isEdit: Bool,
                         placeholderText: NSAttributedString?,
                         attributedText: NSAttributedString,
                         rule: VEditorRule) {
        self.isEdit = isEdit
        self.textNode = VEditorTextNode(rule,
                                        isEdit: isEdit,
                                        placeholderText: placeholderText,
                                        attributedText: attributedText)
        super.init()
        self.automaticallyManagesSubnodes = true
        self.selectionStyle = .none
    }
    
    @discardableResult open func setContentInsets(_ insets: UIEdgeInsets) -> Self {
        self.insets = insets
        return self
    }
    
    override open func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(insets: insets, child: self.textNode)
    }
}
