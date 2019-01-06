//
//  VEditorOpenGraphNode.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import BonMot
import RxSwift
import RxCocoa

extension Reactive where Base: VEditorOpenGraphNode {

    public var didTapDelete: Observable<Void> {
        return base.deleteControlNode.rx.didTapDelete
    }
}

public class VEditorOpenGraphNode: ASCellNode {
    
    lazy var imageNode: ASNetworkImageNode = {
        let node = ASNetworkImageNode()
        node.cornerRadius = 5.0
        node.backgroundColor = .lightGray
        return node
    }()
    
    lazy var titleNode: ASTextNode = {
        let node = ASTextNode()
        node.maximumNumberOfLines = 1
        return node
    }()
    
    lazy var descNode: ASTextNode = {
        let node = ASTextNode()
        node.maximumNumberOfLines = 3
        return node
    }()
    
    lazy var sourceNode: ASTextNode = {
        let node = ASTextNode()
        node.maximumNumberOfLines = 1
        return node
    }()
    
    lazy var containerNode: ASControlNode = {
        let node = ASControlNode()
        node.automaticallyManagesSubnodes = true
        node.borderWidth = 1.0
        node.borderColor = UIColor.gray.cgColor
        node.cornerRadius = 10.0
        return node
    }()
    
    public lazy var deleteControlNode: VEditorDeleteMediaNode =
        .init(.red, deleteIconImage: nil)
    
    public var title: String?
    public var desc: String?
    public var sourceURL: URL?
    public var insets: UIEdgeInsets = .zero
    public var containerInsets: UIEdgeInsets
    public var isEdit: Bool = true
    
    public var disposeBag = DisposeBag()
    
    public required init(_ insets: UIEdgeInsets,
                         isEdit: Bool,
                         title: String?,
                         desc: String?,
                         url: URL?,
                         imageURL: URL?,
                         containerInsets: UIEdgeInsets) {
        self.insets = insets
        self.isEdit = isEdit
        self.title = title
        self.desc = desc
        self.sourceURL = url
        self.containerInsets = containerInsets
        super.init()
        self.automaticallyManagesSubnodes = true
        self.selectionStyle = .none
        self.imageNode.setURL(imageURL, resetToDefault: true)
        self.containerNode.layoutSpecBlock = { [weak self] (_, _) -> ASLayoutSpec in
            return self?.containerLayoutSpec() ?? ASLayoutSpec()
        }
    }
    
    override public func didLoad() {
        super.didLoad()
        guard self.isEdit else { return }
        self.deleteControlNode.isHidden = true
        containerNode.addTarget(self, action: #selector(didTapOpengraph), forControlEvents: .touchUpInside)
        deleteControlNode.addTarget(self, action: #selector(didTapOpengraph), forControlEvents: .touchUpInside)
    }
    
    @objc public func didTapOpengraph() {
        guard self.isEdit else { return }
        self.deleteControlNode.isHidden = !self.deleteControlNode.isHidden
        self.containerNode.setNeedsLayout()
    }
    
    @discardableResult public func setTitleAttribute(_ attrStyle: VEditorStyle) -> Self {
        self.titleNode.attributedText = title?.styled(with: attrStyle)
        return self
    }
    
    @discardableResult public func setDescAttribute(_ attrStyle: VEditorStyle) -> Self {
        self.descNode.attributedText = desc?.styled(with: attrStyle)
        return self
    }
    
    @discardableResult public func setSourceAttribute(_ attrStyle: VEditorStyle) -> Self {
        guard let url = sourceURL else { return self }
        self.sourceNode.attributedText = url.absoluteString
            .styled(with: attrStyle.byAdding([.link(url)]))
        return self
    }
    
    @discardableResult public func setPreviewImageSize(_ size: CGSize) -> Self {
        self.imageNode.style.preferredSize = size
        return self
    }
    
    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        if isEdit {
            let overlayLayout = ASOverlayLayoutSpec(child: containerNode,
                                                    overlay: deleteControlNode)
            return ASInsetLayoutSpec(insets: insets, child: overlayLayout)
        } else {
            return ASInsetLayoutSpec(insets: insets, child: containerNode)
        }
    }
    
    public func containerLayoutSpec() -> ASLayoutSpec {
        var elements: [ASLayoutElement] = []
        
        if title != nil {
            elements.append(titleNode)
        }
        
        if desc != nil {
            elements.append(descNode)
        }
        
        if sourceURL != nil {
            elements.append(sourceNode)
        }
        
        let contentAreaLayout = ASStackLayoutSpec(direction: .vertical,
                                                  spacing: 5.0,
                                                  justifyContent: .start,
                                                  alignItems: .stretch,
                                                  children: elements)
        contentAreaLayout.style.flexShrink = 1.0
        contentAreaLayout.style.flexGrow = 0.0
        imageNode.style.flexShrink = 0.0
        imageNode.style.flexGrow = 0.0

        let openGraphLayout = ASStackLayoutSpec(direction: .horizontal,
                                                spacing: 5.0,
                                                justifyContent: .spaceBetween,
                                                alignItems: .center,
                                                children: [contentAreaLayout, imageNode])
        
        return ASInsetLayoutSpec(insets: containerInsets, child: openGraphLayout)
    }
}
