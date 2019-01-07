//
//  VEditorImageNode.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import RxCocoa
import RxSwift

extension Reactive where Base: VEditorImageNode {
    
    /**
     Delete imageNode event
     */
    public var didTapDelete: Observable<Void> {
        return base.deleteControlNode.rx.didTapDelete
    }
}

open class VEditorImageNode: ASCellNode {
    
    public var insets: UIEdgeInsets = .zero
    public var isEdit: Bool = true
    public var ratio: CGFloat = 1.0
    public let disposeBag = DisposeBag()
    
    public lazy var deleteControlNode: VEditorDeleteMediaNode =
        .init(.red, deleteIconImage: nil)
    lazy var imageNode = ASNetworkImageNode()
    
    public required init(isEdit: Bool) {
        self.isEdit = isEdit
        super.init()
        self.imageNode.backgroundColor = .lightGray
        self.imageNode.placeholderColor = .lightGray
        self.automaticallyManagesSubnodes = true
        self.selectionStyle = .none
    }
    
    @discardableResult open func setContentInsets(_ insets: UIEdgeInsets) -> Self {
        self.insets = insets
        return self
    }
    
    @discardableResult open func setURL(_ url: URL?) -> Self {
        self.imageNode.setURL(url, resetToDefault: true)
        return self
    }
    
    @discardableResult open func setImageRatio(_ ratio: CGFloat) -> Self {
        self.ratio = ratio
        return self
    }
    
    @discardableResult open func setPlaceholderColor(_ color: UIColor) -> Self {
        self.imageNode.placeholderColor = color
        return self
    }
    
    @discardableResult open func setBackgroundColor(_ color: UIColor) -> Self {
        self.imageNode.backgroundColor = color
        return self
    }
    
    override open func didLoad() {
        super.didLoad()
        guard self.isEdit else { return }
        self.deleteControlNode.isHidden = true
        imageNode.addTarget(self,
                            action: #selector(didTapImage),
                            forControlEvents: .touchUpInside)
        deleteControlNode.addTarget(self,
                                    action: #selector(didTapImage),
                                    forControlEvents: .touchUpInside)
    }
    
    @objc public func didTapImage() {
        guard self.isEdit else { return }
        self.deleteControlNode.isHidden = !self.deleteControlNode.isHidden
        self.setNeedsLayout()
    }
    
    override open func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let ratioLayout = ASRatioLayoutSpec(ratio: ratio, child: imageNode)
        if isEdit {
            let deleteOverlayLayout =
                ASOverlayLayoutSpec(child: ratioLayout,
                                    overlay: deleteControlNode)
            return ASInsetLayoutSpec(insets: insets,
                                     child: deleteOverlayLayout)
        } else {
            return ASInsetLayoutSpec(insets: insets,
                                     child: ratioLayout)
        }
    }
}
