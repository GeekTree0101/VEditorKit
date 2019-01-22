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

@objcMembers open class VEditorVideoNode: VEditorMediaNode<ASVideoNode> {
    
    public var assetURL: URL?
    public var posterURL: URL?
    public var videoAsset: AVAsset? {
        guard let url = assetURL else { return nil }
        return AVURLAsset(url: url)
    }
    
    public required init(isEdit: Bool,
                         deleteNode: VEditorDeleteMediaNode = .init()) {
        super.init(node: .init(),
                   deleteNode: deleteNode,
                   isEdit: isEdit)
        self.automaticallyManagesSubnodes = true
        self.selectionStyle = .none
        self.node.backgroundColor = .black
        self.node.shouldAutoplay = false
        self.node.backgroundColor = .lightGray
        self.node.placeholderColor = .lightGray
    }
    
    /**
     Set video preview image url
     
     - parameters:
     - url: video preview image url
     - returns: self (VEditorVideoNode)
     */
    @discardableResult open func setPreviewURL(_ url: URL?) -> Self {
        self.node.setURL(url, resetToDefault: true)
        return self
    }
    
    /**
     Set video asset url
     
     - parameters:
     - url: video asset url
     - returns: self (VEditorVideoNode)
     */
    @discardableResult open func setAssetURL(_ url: URL?) -> Self {
        self.assetURL = url
        return self
    }
    
    /**
     Set video gravity
     
     - parameters:
     - gravity: video gravity
     - returns: self (VEditorVideoNode)
     */
    @discardableResult open func setGravity(_ gravity: AVLayerVideoGravity) -> Self {
        self.node.contentsGravity = gravity.rawValue
        return self
    }
    
    /**
     Set video placeholder color
     
     - parameters:
     - color: video placeholder color
     - returns: self (VEditorVideoNode)
     */
    @discardableResult open func setPlaceholderColor(_ color: UIColor) -> Self {
        self.node.placeholderColor = color
        return self
    }
    
    /**
     Set video background color
     
     - parameters:
     - color: video background color
     - returns: self (VEditorVideoNode)
     */
    @discardableResult open func setBackgroundColor(_ color: UIColor) -> Self {
        self.node.backgroundColor = color
        return self
    }
    
    override open func didLoad() {
        super.didLoad()
        self.node.asset = self.videoAsset
    }
    
    @objc override open func didTapMedia() {
        super.didTapMedia()
        guard self.isEdit else { return }
        
        if self.deleteControlNode.isHidden {
            self.node.pause()
        } else {
            self.node.play()
        }
    }
}
