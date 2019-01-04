//
//  EditorControlAreaNode.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import VEditorKit

class EditorControlAreaNode: ASDisplayNode {
    
    struct Const {
        static let insets: UIEdgeInsets = .init(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
        static let controlSize: CGSize = .init(width: 44.0, height: 44.0)
    }
    
    // Typing Control Node
    
    
    lazy var scrollNode: ASScrollNode = {
        let node = ASScrollNode()
        node.automaticallyManagesContentSize = true
        node.automaticallyManagesSubnodes = true
        node.scrollableDirections = [.left, .right]
        return node
    }()
    
    lazy var dismissNode: ASButtonNode = {
        let node = ASButtonNode()
        node.setImage(#imageLiteral(resourceName: "keyboard.png"), for: .normal)
        node.style.preferredSize = Const.controlSize
        return node
    }()
    
    override init() {
        super.init()
        self.automaticallyManagesSubnodes = true
        self.backgroundColor = .clear
        self.scrollNode.layoutSpecBlock = { [weak self] (_, _) -> ASLayoutSpec in
            return self?.controlButtonsGroupLayoutSpec() ?? ASLayoutSpec()
        }
    }
    
    override func didLoad() {
        super.didLoad()
        self.scrollNode.view.showsVerticalScrollIndicator = false
        self.scrollNode.view.showsHorizontalScrollIndicator = false
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        scrollNode.style.flexShrink = 1.0
        scrollNode.style.flexGrow = 0.0
        dismissNode.style.flexShrink = 1.0
        dismissNode.style.flexGrow = 0.0
        let stackLayout = ASStackLayoutSpec(direction: .horizontal,
                                            spacing: 5.0,
                                            justifyContent: .spaceBetween,
                                            alignItems: .stretch,
                                            children: [scrollNode, dismissNode])
        return ASInsetLayoutSpec(insets: Const.insets, child: stackLayout)
    }
    
    private func controlButtonsGroupLayoutSpec() -> ASLayoutSpec {
        return ASStackLayoutSpec(direction: .horizontal,
                                 spacing: 0.0,
                                 justifyContent: .start,
                                 alignItems: .start,
                                 children: [])
    }
}
