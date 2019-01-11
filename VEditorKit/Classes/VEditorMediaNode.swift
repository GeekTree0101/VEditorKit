//
//  VEditorMedia.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import RxSwift
import RxCocoa

// ***** TIP *****
// If you make VEditorMediaNode subclass
// you will got advantage about delete & textInsertion automatically binding on VEditorNode
public protocol VEditorMediaNodeEventProtocol {
    
    var didTapDeleteObservable: Observable<IndexPath> { get }
    var didTapTextInsertObservable: Observable<IndexPath> { get }
    var isEdit: Bool { get }
    var disposeBag: DisposeBag { get }
}

open class VEditorMediaNode<TargetNode: ASControlNode>: ASCellNode, VEditorMediaNodeEventProtocol {
    
    open let node: TargetNode
    
    open lazy var textInsertionNode: ASControlNode = {
        let node = ASControlNode()
        node.backgroundColor = .clear
        node.style.height = .init(unit: .points, value: 5.0)
        return node
    }()
    
    open let deleteControlNode: VEditorDeleteMediaNode
    
    public let textInsertionRelay = PublishRelay<IndexPath>()
    public let didTapDeleteRelay = PublishRelay<IndexPath>()
    open var insets: UIEdgeInsets = .zero
    open var ratio: CGFloat = 1.0
    open var isEdit: Bool = true
    
    open var didTapDeleteObservable: Observable<IndexPath> {
        return self.didTapDeleteRelay.asObservable()
    }
    
    open var didTapTextInsertObservable: Observable<IndexPath> {
        return self.textInsertionRelay.asObservable()
    }
    
    public var disposeBag: DisposeBag = DisposeBag()
    
    public init(node: TargetNode,
                deleteNode: VEditorDeleteMediaNode = .init(),
                isEdit: Bool) {
        self.node = node as! TargetNode
        self.isEdit = isEdit
        self.deleteControlNode = deleteNode
        super.init()
        self.automaticallyManagesSubnodes = true
        self.selectionStyle = .none
    }
    
    /**
     Set insets
     
     - parameters:
     - insets: update insets
     - returns: self (VEditorMediaNode or subclass)
     */
    @discardableResult open func setContentInsets(_ insets: UIEdgeInsets) -> Self {
        self.insets = insets
        return self
    }
    
    /**
     Set media node ratio
     
     - parameters:
     - ratio: update media node ratio
     - returns: self (VEditorMediaNode or subclass)
     */
    @discardableResult open func setMediaRatio(_ ratio: CGFloat) -> Self {
        self.ratio = ratio
        return self
    }
    
    /**
     Set text insertion area height
     
     - parameters:
     - height: touch area height
     - returns: self (VEditorMediaNode or subclass)
     */
    @discardableResult open func setTextInsertionHeight(_ height: CGFloat) -> Self {
        self.textInsertionNode.style.height = .init(unit: .points, value: height)
        return self
    }
    
    override open func didLoad() {
        super.didLoad()
        guard self.isEdit else { return }
        node.addTarget(self,
                       action: #selector(didTapMedia),
                       forControlEvents: .touchUpInside)
        deleteControlNode.addTarget(self,
                                    action: #selector(didTapMedia),
                                    forControlEvents: .touchUpInside)
        textInsertionNode.addTarget(self,
                                    action: #selector(didTapTextInsertion),
                                    forControlEvents: .touchUpInside)
        deleteControlNode.deleteButtonNode
            .addTarget(self,
                       action: #selector(didTapDelete),
                       forControlEvents: .touchUpInside)
    }
    
    /**
     Did tap media content event
     
     - important: It can control delete control box hidden status with anything else
     If you needs more customize logic than have to override this method!
     - returns: (Void)
     */
    @objc open func didTapMedia() {
        guard self.isEdit else { return }
        self.deleteControlNode.isHidden = !self.deleteControlNode.isHidden
        self.setNeedsLayout()
    }
    
    /**
     Did tap text insertion event
     
     - important: It emit textInsert event (insert textView between medias)
     If you needs more customize logic than have to override this method!
     - returns: (Void)
     */
    @objc open func didTapTextInsertion() {
        guard let indexPath = self.indexPath else { return }
        self.textInsertionRelay.accept(indexPath)
    }
    
    /**
     Did tap delete media
     
     - important: It emit delete touched media content from editor
     If you needs more customize logic than have to override this method!
     - returns: (Void)
     */
    @objc open func didTapDelete() {
        guard let indexPath = self.indexPath else { return }
        self.didTapDeleteRelay.accept(indexPath)
    }
    
    /**
     Make media content layoutSpec
     
     - important: If you needs attach subnodes or layout on media content
     than you have to override this method
     
     - parameters: constrainedSize(ASSizeRange)
     - returns: Media content layout spec (default is media ratioLayout)
     */
    open func mediaContentLayoutSpec(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASRatioLayoutSpec(ratio: ratio, child: node)
    }
    
    override open func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let mediaRatioLayout = self.mediaContentLayoutSpec(constrainedSize)
        
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
