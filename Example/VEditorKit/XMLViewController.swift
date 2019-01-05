//
//  XMLViewController.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//


import Foundation
import AsyncDisplayKit
import VEditorKit

class XMLViewController: ASViewController<ASScrollNode> {
    
    lazy var textNode = ASTextNode()
    
    init(_ xmlString: String) {
        super.init(node: .init())
        self.title = "XML Viewer"
        self.node.automaticallyManagesContentSize = true
        self.node.automaticallyManagesSubnodes = true
        self.node.automaticallyRelayoutOnSafeAreaChanges = true
        self.node.backgroundColor = .white
        self.node.layoutSpecBlock = { [weak self] (_, sizeRange) -> ASLayoutSpec in
            return self?.layoutSpecThatFits(sizeRange) ?? ASLayoutSpec()
        }
        textNode.attributedText = xmlString.styled(with: .font(UIFont.systemFont(ofSize: 15.0)))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.node.view.setContentOffset(.init(x: 0.0, y: -self.node.safeAreaInsets.top),
                                        animated: true)
    }
    
    private func layoutSpecThatFits(_ constraintedSize: ASSizeRange) -> ASLayoutSpec {
        var insets: UIEdgeInsets = self.node.safeAreaInsets
        insets.left += 10.0
        insets.right += 10.0
        insets.bottom += 10.0
        insets.top += 20.0
        return ASInsetLayoutSpec(insets: insets, child: textNode)
    }
}
