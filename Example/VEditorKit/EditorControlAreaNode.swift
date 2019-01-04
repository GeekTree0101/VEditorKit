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
        static let insets: UIEdgeInsets = .init(top: 10.0, left: 5.0, bottom: 5.0, right: 10.0)
        static let controlSize: CGSize = .init(width: 44.0, height: 44.0)
    }
    
    lazy var boldNode: VEditorTypingControlNode = {
        let node = VEditorTypingControlNode(EditorRule.XML.bold.rawValue,
                                            rule: rule)
        node.style.preferredSize = Const.controlSize
        node.setTitle("<b>", with: UIFont.systemFont(ofSize: 20.0), with: .darkGray, for: .normal)
        node.setTitle("<b>", with: UIFont.systemFont(ofSize: 20.0), with: .lightGray, for: .disabled)
        node.setTitle("<b>", with: UIFont.systemFont(ofSize: 20.0, weight: .bold), with: .blue, for: .selected)
        return node
    }()
    
    lazy var italicNode: VEditorTypingControlNode = {
        let node = VEditorTypingControlNode(EditorRule.XML.italic.rawValue,
                                            rule: rule)
        node.style.preferredSize = Const.controlSize
        node.setTitle("<i>", with: UIFont.systemFont(ofSize: 20.0), with: .darkGray, for: .normal)
        node.setTitle("<i>", with: UIFont.systemFont(ofSize: 20.0), with: .lightGray, for: .disabled)
        node.setTitle("<i>", with: UIFont.systemFont(ofSize: 20.0, weight: .bold), with: .blue, for: .selected)
        return node
    }()
    
    lazy var headingNode: VEditorTypingControlNode = {
        let node = VEditorTypingControlNode(EditorRule.XML.heading.rawValue,
                                            rule: rule)
        node.style.preferredSize = Const.controlSize
        node.setTitle("<h>", with: UIFont.systemFont(ofSize: 20.0), with: .darkGray, for: .normal)
        node.setTitle("<h>", with: UIFont.systemFont(ofSize: 20.0), with: .lightGray, for: .disabled)
        node.setTitle("<h>", with: UIFont.systemFont(ofSize: 20.0, weight: .bold), with: .blue, for: .selected)
        return node
    }()
    
    lazy var quoteNode: VEditorTypingControlNode = {
        let node = VEditorTypingControlNode(EditorRule.XML.quote.rawValue,
                                            rule: rule)
        node.style.preferredSize = Const.controlSize
        node.setTitle("<q>", with: UIFont.systemFont(ofSize: 20.0), with: .darkGray, for: .normal)
        node.setTitle("<q>", with: UIFont.systemFont(ofSize: 20.0), with: .lightGray, for: .disabled)
        node.setTitle("<q>", with: UIFont.systemFont(ofSize: 20.0, weight: .bold), with: .blue, for: .selected)
        return node
    }()
    
    lazy var linkInsertNode: VEditorTypingControlNode = {
        let node = VEditorTypingControlNode(EditorRule.XML.article.rawValue,
                                            rule: rule)
        node.style.preferredSize = Const.controlSize
        node.setTitle("<a>", with: UIFont.systemFont(ofSize: 20.0), with: .darkGray, for: .normal)
        node.setTitle("<a>", with: UIFont.systemFont(ofSize: 20.0), with: .lightGray, for: .disabled)
        node.setTitle("<a>", with: UIFont.systemFont(ofSize: 20.0, weight: .bold), with: .blue, for: .selected)
        return node
    }()
    
    lazy var seperateLineNode: ASDisplayNode = {
        let node = ASDisplayNode()
        node.backgroundColor = .lightGray
        return node
    }()
    
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
    
    var typingControlNodes: [VEditorTypingControlNode] {
        return [boldNode, italicNode, quoteNode, headingNode, linkInsertNode]
    }
    
    let rule: EditorRule
    
    init(rule: EditorRule) {
        self.rule = rule
        super.init()
        self.automaticallyManagesSubnodes = true
        self.backgroundColor = .white
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
        let controlAreaLayout = ASInsetLayoutSpec(insets: Const.insets, child: stackLayout)
        seperateLineNode.style.height = .init(unit: .points, value: 0.5)
        return ASStackLayoutSpec(direction: .vertical,
                                 spacing: 0.0,
                                 justifyContent: .start,
                                 alignItems: .stretch,
                                 children: [seperateLineNode,
                                            controlAreaLayout])
    }
    
    private func controlButtonsGroupLayoutSpec() -> ASLayoutSpec {
        return ASStackLayoutSpec(direction: .horizontal,
                                 spacing: 10.0,
                                 justifyContent: .start,
                                 alignItems: .start,
                                 children: typingControlNodes)
    }
}
