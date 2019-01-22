//
//  VEditorDeleteMediaNode.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import AsyncDisplayKit
import RxCocoa
import RxSwift

open class VEditorDeleteMediaNode: ASControlNode {
    
    open let deleteButtonNode = ASButtonNode()
    
    public init(_ color: UIColor = .red,
                borderWidth: CGFloat = 5.0, // default is 5.0pt
                iconImage: UIImage? = nil,
                buttonSize: CGSize = .init(width: 50.0, height: 50.0)) {
        super.init()
        self.deleteButtonNode.style.preferredSize = buttonSize
        self.deleteButtonNode.backgroundColor = color
        self.deleteButtonNode.setImage(iconImage, for: .normal)
        self.borderWidth = borderWidth
        self.borderColor = color.cgColor
        self.automaticallyManagesSubnodes = true
        self.isHidden = true
    }
    
    override open func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASRelativeLayoutSpec(horizontalPosition: .end,
                                    verticalPosition: .start,
                                    sizingOption: [],
                                    child: deleteButtonNode)
    }
}
