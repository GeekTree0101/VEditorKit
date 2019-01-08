//
//  VEditorVideoNode.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import RxSwift
import RxCocoa

extension Reactive where Base: VEditorVideoNode {
    
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

open class VEditorVideoNode: ASCellNode {
    
    public lazy var videoNode: ASVideoNode = {
        let node = ASVideoNode()
        node.backgroundColor = .black
        node.shouldAutoplay = false
        return node
    }()
    
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
    public var assetURL: URL?
    public var posterURL: URL?
    public var videoAsset: AVAsset? {
        guard let url = assetURL else { return nil }
        return AVURLAsset(url: url)
    }
    public let disposeBag = DisposeBag()
    
    public required init(isEdit: Bool) {
        self.isEdit = isEdit
        super.init()
        self.automaticallyManagesSubnodes = true
        self.selectionStyle = .none
        self.videoNode.backgroundColor = .lightGray
        self.videoNode.placeholderColor = .lightGray
    }
    
    @discardableResult open func setContentInsets(_ insets: UIEdgeInsets) -> Self {
        self.insets = insets
        return self
    }
    
    @discardableResult open func setTextInsertionHeight(_ height: CGFloat) -> Self {
        self.textInsertionNode.style.height = .init(unit: .points, value: height)
        return self
    }
    
    @discardableResult open func setPreviewURL(_ url: URL?) -> Self {
        self.videoNode.setURL(url, resetToDefault: true)
        return self
    }
    
    @discardableResult open func setAssetURL(_ url: URL?) -> Self {
        self.assetURL = url
        return self
    }
    
    @discardableResult open func setVideoRatio(_ ratio: CGFloat) -> Self {
        self.ratio = ratio
        return self
    }
    
    @discardableResult open func setPlaceholderColor(_ color: UIColor) -> Self {
        self.videoNode.placeholderColor = color
        return self
    }
    
    @discardableResult open func setBackgroundColor(_ color: UIColor) -> Self {
        self.videoNode.backgroundColor = color
        return self
    }
    
    override open func didLoad() {
        super.didLoad()
        self.videoNode.asset = self.videoAsset
        guard self.isEdit else { return }
        self.deleteControlNode.isHidden = true
        videoNode.addTarget(self,
                            action: #selector(didTapVideo),
                            forControlEvents: .touchUpInside)
        deleteControlNode.addTarget(self,
                                    action: #selector(didTapVideo),
                                    forControlEvents: .touchUpInside)
        textInsertionNode.addTarget(self,
                                    action: #selector(didTapTextInsertion),
                                    forControlEvents: .touchUpInside)
    }
    
    @objc public func didTapVideo() {
        guard self.isEdit else { return }
        self.deleteControlNode.isHidden = !self.deleteControlNode.isHidden
        if self.deleteControlNode.isHidden {
            self.videoNode.pause()
        } else {
            self.videoNode.play()
        }
        self.setNeedsLayout()
    }
    
    @objc public func didTapTextInsertion() {
        guard let indexPath = self.indexPath else { return }
        self.textInsertionRelay.accept(indexPath)
    }
    
    override open func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let mediaRatioLayout = ASRatioLayoutSpec(ratio: ratio, child: videoNode)
        
        let mediaContentLayout: ASLayoutElement
        
        if isEdit {
            mediaContentLayout = ASOverlayLayoutSpec(child: mediaRatioLayout,
                                                     overlay: deleteControlNode)
        } else {
            mediaContentLayout = mediaRatioLayout
        }
        
        let videoNodeLayout: ASLayoutElement
        
        if isEdit {
            videoNodeLayout =
                ASStackLayoutSpec(direction: .vertical,
                                  spacing: 0.0,
                                  justifyContent: .start,
                                  alignItems: .stretch,
                                  children: [textInsertionNode,
                                             mediaContentLayout])
        } else {
            videoNodeLayout = mediaContentLayout
        }
        
        return ASInsetLayoutSpec(insets: insets,
                                 child: videoNodeLayout)
    }
}
