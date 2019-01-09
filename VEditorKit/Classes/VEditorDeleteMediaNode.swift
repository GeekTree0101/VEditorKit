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
    
    open lazy var deleteButtonNode: ASControlNode = {
        let node = ASControlNode()
        node.cornerRadius = 5.0
        node.backgroundColor = self.deleteColor
        node.style.preferredSize = .init(width: 50.0, height: 50.0)
        return node
    }()
    
    open lazy var closeIconNode: ASImageNode = {
        let node = ASImageNode()
        node.isUserInteractionEnabled = false
        node.backgroundColor = .white
        node.style.preferredSize = .init(width: 30.0, height: 10.0)
        node.cornerRadius = 5.0
        return node
    }()
    
    open let deleteColor: UIColor
    open let deleteIconImage: UIImage?
    
    public init(_ color: UIColor, deleteIconImage: UIImage?) {
        self.deleteColor = color
        self.deleteIconImage = deleteIconImage
        super.init()
        self.borderWidth = 5.0
        self.borderColor = deleteColor.cgColor
        self.automaticallyManagesSubnodes = true
    }
    
    override open func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASRelativeLayoutSpec(horizontalPosition: .end,
                                    verticalPosition: .start,
                                    sizingOption: [],
                                    child: deleteButtonLayoutSpec())
    }
    
    open func deleteButtonLayoutSpec() -> ASLayoutSpec {
        let centerLayout = ASCenterLayoutSpec(centeringOptions: .XY,
                                              sizingOptions: [],
                                              child: closeIconNode)
        return ASOverlayLayoutSpec(child: deleteButtonNode, overlay: centerLayout)
    }
}
