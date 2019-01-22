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
    
    public var didTapDelete: Observable<IndexPath> {
        return base.didTapDeleteRelay.asObservable()
    }
}

@objcMembers open class VEditorOpenGraphNode: ASCellNode {
    
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
        node.borderColor = UIColor.lightGray.cgColor
        node.cornerRadius = 10.0
        return node
    }()
    
    public let deleteControlNode: VEditorDeleteMediaNode
    
    public var insets: UIEdgeInsets = .zero
    public var containerInsets: UIEdgeInsets = .zero
    public var isEdit: Bool = true
    public var imageRatio: CGFloat?
    public var contentSpacing: CGFloat = 5.0
    public var imageWithContentSpacing: CGFloat = 5.0
    public var disposeBag = DisposeBag()
    public let didTapDeleteRelay = PublishRelay<IndexPath>()
    
    public required init(isEdit: Bool,
                         deleteNode: VEditorDeleteMediaNode = .init()) {
        self.isEdit = isEdit
        self.deleteControlNode = deleteNode
        super.init()
        self.automaticallyManagesSubnodes = true
        self.selectionStyle = .none
        self.containerNode.layoutSpecBlock = { [weak self] (_, _) -> ASLayoutSpec in
            return self?.containerLayoutSpec() ?? ASLayoutSpec()
        }
    }
    
    override open func didLoad() {
        super.didLoad()
        guard self.isEdit else { return }
        self.deleteControlNode.isHidden = true
        containerNode.addTarget(self, action: #selector(didTapOpengraph), forControlEvents: .touchUpInside)
        deleteControlNode.addTarget(self, action: #selector(didTapOpengraph), forControlEvents: .touchUpInside)
        deleteControlNode.deleteButtonNode
            .addTarget(self,
                       action: #selector(didTapDelete),
                       forControlEvents: .touchUpInside)
    }
    
    @objc func didTapDelete() {
        guard let indexPath = self.indexPath else { return }
        self.didTapDeleteRelay.accept(indexPath)
    }
    
    @objc public func didTapOpengraph() {
        guard self.isEdit else { return }
        self.deleteControlNode.isHidden = !self.deleteControlNode.isHidden
        self.containerNode.setNeedsLayout()
    }
    
    @discardableResult open func setContentInsets(_ insets: UIEdgeInsets) -> Self {
        self.insets = insets
        return self
    }
    
    @discardableResult open func setOpenGraphContainerInsets(_ insets: UIEdgeInsets) -> Self {
        self.containerInsets = insets
        return self
    }
    
    @discardableResult open func setPreviewImageRatio(_ ratio: CGFloat) -> Self {
        self.imageRatio = ratio
        return self
    }
    
    @discardableResult open func setPreviewImageSize(_ size: CGSize,
                                                     cornerRadius: CGFloat) -> Self {
        self.imageNode.style.preferredSize = size
        self.imageNode.cornerRadius = cornerRadius
        self.imageRatio = nil
        return self
    }
    
    @discardableResult open func setPreviewImageURL(_ url: URL?) -> Self {
        self.imageNode.setURL(url, resetToDefault: true)
        return self
    }
    
    @discardableResult open func setPlaceholderColor(_ color: UIColor) -> Self {
        self.imageNode.placeholderColor = color
        return self
    }
    
    @discardableResult open func setTitleAttribute(_ text: String?,
                                                   attrStyle: VEditorStyle) -> Self {
        self.titleNode.attributedText = text?.styled(with: attrStyle)
        return self
    }
    
    @discardableResult open func setDescAttribute(_ text: String?,
                                                  attrStyle: VEditorStyle) -> Self {
        self.descNode.attributedText = text?.styled(with: attrStyle)
        return self
    }
    
    @discardableResult open func setSourceAttribute(_ url: URL?,
                                                    attrStyle: VEditorStyle) -> Self {
        guard let url = url else { return self }
        self.sourceNode.attributedText =
            url.absoluteString.styled(with: attrStyle.byAdding([.link(url)]))
        return self
    }
    
    override open func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        if isEdit {
            let overlayLayout = ASOverlayLayoutSpec(child: containerNode,
                                                    overlay: deleteControlNode)
            return ASInsetLayoutSpec(insets: insets, child: overlayLayout)
        } else {
            return ASInsetLayoutSpec(insets: insets, child: containerNode)
        }
    }
    
    open func containerLayoutSpec() -> ASLayoutSpec {
        var elements: [ASLayoutElement] = []
        
        if titleNode.attributedText?.length ?? 0 > 0 {
            elements.append(titleNode)
        }
        
        if descNode.attributedText?.length ?? 0 > 0 {
            elements.append(descNode)
        }
        
        if sourceNode.attributedText?.length ?? 0 > 0 {
            elements.append(sourceNode)
        }
        
        let contentAreaLayout = ASStackLayoutSpec(direction: .vertical,
                                                  spacing: contentSpacing,
                                                  justifyContent: .start,
                                                  alignItems: .stretch,
                                                  children: elements)
        contentAreaLayout.style.flexShrink = 1.0
        contentAreaLayout.style.flexGrow = 0.0
        imageNode.style.flexShrink = 0.0
        imageNode.style.flexGrow = 0.0
        
        let openGraphLayout = ASStackLayoutSpec(direction: .horizontal,
                                                spacing: imageWithContentSpacing,
                                                justifyContent: .spaceBetween,
                                                alignItems: .center,
                                                children: [contentAreaLayout,
                                                           imageNode])
        
        return ASInsetLayoutSpec(insets: containerInsets,
                                 child: openGraphLayout)
    }
}
