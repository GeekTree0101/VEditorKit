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
    
    public var didTapDelete: Observable<Void> {
        return base.deleteControlNode.rx.didTapDelete
    }
}

public class VEditorImageNode: ASCellNode {
    
    public var insets: UIEdgeInsets = .zero
    public var isEdit: Bool = true
    public let disposeBag = DisposeBag()
    
    private let ratio: CGFloat
    
    public lazy var deleteControlNode: VEditorDeleteMediaNode = .init(.red, deleteIconImage: nil)
    lazy var imageNode = ASNetworkImageNode()
    
    public required init(_ insets: UIEdgeInsets,
                         isEdit: Bool,
                         url: URL?,
                         ratio: CGFloat) {
        self.insets = insets
        self.isEdit = isEdit
        self.ratio = ratio
        super.init()
        self.imageNode.backgroundColor = .lightGray
        self.imageNode.setURL(url, resetToDefault: true)
        self.automaticallyManagesSubnodes = true
        self.selectionStyle = .none
    }
    
    override public func didLoad() {
        super.didLoad()
        guard self.isEdit else { return }
        self.deleteControlNode.isHidden = true
        imageNode.addTarget(self, action: #selector(didTapImage), forControlEvents: .touchUpInside)
        deleteControlNode.addTarget(self, action: #selector(didTapImage), forControlEvents: .touchUpInside)
    }
    
    @objc public func didTapImage() {
        guard self.isEdit else { return }
        self.deleteControlNode.isHidden = !self.deleteControlNode.isHidden
        self.setNeedsLayout()
    }
    
    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let ratioLayout = ASRatioLayoutSpec(ratio: ratio, child: imageNode)
        if isEdit {
            let deleteOverlayLayout = ASOverlayLayoutSpec(child: ratioLayout,
                                                          overlay: deleteControlNode)
            return ASInsetLayoutSpec(insets: insets, child: deleteOverlayLayout)
        } else {
            return ASInsetLayoutSpec(insets: insets, child: ratioLayout)
        }
    }
}
