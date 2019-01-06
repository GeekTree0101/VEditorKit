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
    
    public var didTapDelete: Observable<Void> {
        return base.deleteControlNode.rx.didTapDelete
    }
}
public class VEditorVideoNode: ASCellNode {
    
    public lazy var videoNode: ASVideoNode = {
        let node = ASVideoNode()
        node.backgroundColor = .black
        node.shouldAutoplay = false
        return node
    }()
    
    public lazy var deleteControlNode: VEditorDeleteMediaNode = .init(.red, deleteIconImage: nil)
    
    public var insets: UIEdgeInsets = .zero
    public var isEdit: Bool = true
    public let ratio: CGFloat
    public let videoSrcURL: URL?
    public let posterURL: URL?
    public let disposeBag = DisposeBag()
    public var videoAsset: AVAsset? {
        guard let url = videoSrcURL else { return nil }
        return AVURLAsset(url: url)
    }
    public required init(_ insets: UIEdgeInsets,
                         isEdit: Bool,
                         ratio: CGFloat,
                         source: URL?,
                         poster: URL?) {
        self.insets = insets
        self.isEdit = isEdit
        self.ratio = ratio
        self.posterURL = poster
        self.videoSrcURL = source
        super.init()
        self.automaticallyManagesSubnodes = true
        self.selectionStyle = .none
        self.videoNode.setURL(self.posterURL, resetToDefault: true)
    }
    
    override public func didLoad() {
        super.didLoad()
        self.videoNode.asset = self.videoAsset
        guard self.isEdit else { return }
        self.deleteControlNode.isHidden = true
        videoNode.addTarget(self, action: #selector(didTapVideo), forControlEvents: .touchUpInside)
        deleteControlNode.addTarget(self, action: #selector(didTapVideo), forControlEvents: .touchUpInside)
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
    
    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let ratioLayout = ASRatioLayoutSpec(ratio: ratio, child: videoNode)
        if isEdit {
            let deleteOverlayLayout = ASOverlayLayoutSpec(child: ratioLayout,
                                                          overlay: deleteControlNode)
            return ASInsetLayoutSpec(insets: insets, child: deleteOverlayLayout)
        } else {
            return ASInsetLayoutSpec(insets: insets, child: ratioLayout)
        }
    }
}
