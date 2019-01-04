//
//  VEditorImageNode.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit

public class VEditorImageNode: ASCellNode {
    
    public var insets: UIEdgeInsets = .zero
    public var isEdit: Bool = true
    private let ratio: CGFloat
    
    lazy var imageNode = ASNetworkImageNode()
    
    public required init(_ insets: UIEdgeInsets,
                         isEdit: Bool,
                         url: URL?,
                         ratio: CGFloat) {
        self.insets = insets
        self.isEdit = isEdit
        self.ratio = ratio
        super.init()
        self.imageNode.backgroundColor = .lightGray
        self.imageNode.setURL(url, resetToDefault: true)
        self.automaticallyManagesSubnodes = true
        self.selectionStyle = .none
    }
    
    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let ratioLayout = ASRatioLayoutSpec(ratio: ratio, child: imageNode)
        
        return ASInsetLayoutSpec(insets: insets, child: ratioLayout)
    }
}
