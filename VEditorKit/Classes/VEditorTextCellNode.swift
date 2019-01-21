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
    
    public var becomeActive: Observable<Void> {
        return base.textNode.rx.becomeActive.asObservable()
    }
    
    public var deleted: Observable<IndexPath> {
        return base.deleteRelay.filter({ $0 != nil }).map({ $0! })
    }
}

open class VEditorTextCellNode: ASCellNode {
    
    public var insets: UIEdgeInsets = .zero
    public var isEdit: Bool = true
    public var textNode: VEditorTextNode
    public let disposeBag = DisposeBag()
    public let deleteRelay = PublishRelay<IndexPath?>()
    
    public required init(isEdit: Bool,
                         placeholderText: NSAttributedString?,
                         attributedText: NSAttributedString,
                         rule: VEditorRule,
                         regexDelegate: VEditorRegexApplierDelegate? = nil,
                         automaticallyGenerateLinkPreview: Bool = false) {
        self.isEdit = isEdit
        self.textNode = VEditorTextNode(rule,
                                        isEdit: isEdit,
                                        placeholderText: placeholderText,
                                        attributedText: attributedText)
        self.textNode.regexDelegate = regexDelegate
        self.textNode.automaticallyGenerateLinkPreview = automaticallyGenerateLinkPreview
        super.init()
        self.automaticallyManagesSubnodes = true
        self.selectionStyle = .none
        
        self.textNode.rx.textEmptied
            .map { [weak self] _ -> IndexPath? in
                return self?.indexPath
            }
            .bind(to: deleteRelay)
            .disposed(by: disposeBag)
    }
    
    @discardableResult open func setContentInsets(_ insets: UIEdgeInsets) -> Self {
        self.insets = insets
        return self
    }
    
    override open func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(insets: insets, child: self.textNode)
    }
}
