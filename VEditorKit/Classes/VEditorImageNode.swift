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
    
    /**
     Text insertion event
     */
    public var didTapTextInsert: Observable<IndexPath> {
        return base.textInsertionRelay.asObservable()
    }
}

open class VEditorImageNode: ASCellNode {
    
    public lazy var imageNode = ASNetworkImageNode()
    
    public lazy var textInsertionNode: ASControlNode = {
        let node = ASControlNode()
        node.backgroundColor = .clear
        node.style.height = .init(unit: .points, value: 5.0)
        return node
    }()
    
    public lazy var deleteControlNode: VEditorDeleteMediaNode =
        .init(.red, deleteIconImage: nil)
    
    public let textInsertionRelay = PublishRelay<IndexPath>()
    public var insets: UIEdgeInsets = .zero
    public var isEdit: Bool = true
    public var ratio: CGFloat = 1.0
    public let disposeBag = DisposeBag()
    
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
    
    @discardableResult open func setTextInsertionHeight(_ height: CGFloat) -> Self {
        self.textInsertionNode.style.height = .init(unit: .points, value: height)
        return self
    }
    
    @discardableResult open func setURL(_ url: URL?) -> Self {
        if url?.isFileURL ?? false {
            guard let imageFileURL = url,
                let imageData = try? Data(contentsOf: imageFileURL,
                                          options: []) else { return self }
            self.imageNode.image = UIImage(data: imageData)
        } else {
            self.imageNode.setURL(url, resetToDefault: true)
        }
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
        textInsertionNode.addTarget(self,
                                    action: #selector(didTapTextInsertion),
                                    forControlEvents: .touchUpInside)
    }
    
    @objc public func didTapTextInsertion() {
        guard let indexPath = self.indexPath else { return }
        self.textInsertionRelay.accept(indexPath)
    }
    
    @objc public func didTapImage() {
        guard self.isEdit else { return }
        self.deleteControlNode.isHidden = !self.deleteControlNode.isHidden
        self.setNeedsLayout()
    }
    
    override open func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let mediaRatioLayout = ASRatioLayoutSpec(ratio: ratio, child: imageNode)
        
        let mediaContentLayout: ASLayoutElement
        
        if isEdit {
            mediaContentLayout = ASOverlayLayoutSpec(child: mediaRatioLayout,
                                                     overlay: deleteControlNode)
        } else {
            mediaContentLayout = mediaRatioLayout
        }
        
        let imageNodeLayout: ASLayoutElement
        
        if isEdit {
            imageNodeLayout =
                ASStackLayoutSpec(direction: .vertical,
                                  spacing: 0.0,
                                  justifyContent: .start,
                                  alignItems: .stretch,
                                  children: [textInsertionNode,
                                             mediaContentLayout])
        } else {
            imageNodeLayout = mediaContentLayout
        }
        
        return ASInsetLayoutSpec(insets: insets,
                                 child: imageNodeLayout)
    }
}
