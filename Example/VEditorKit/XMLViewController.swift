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
        self.node.backgroundColor = .white
        self.node.layoutSpecBlock = { [weak self] (_, sizeRange) -> ASLayoutSpec in
            return self?.layoutSpecThatFits(sizeRange) ?? ASLayoutSpec()
        }
        textNode.attributedText = xmlString.styled(with: .font(UIFont.systemFont(ofSize: 15.0)))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func layoutSpecThatFits(_ constraintedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(insets: .init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0), child: textNode)
    }
}
