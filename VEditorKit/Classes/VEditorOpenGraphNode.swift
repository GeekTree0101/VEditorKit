//
//  VEditorOpenGraphNode.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import BonMot

public class VEditorOpenGraphNode: ASCellNode {
    
    public var insets: UIEdgeInsets = .zero
    public var isEdit: Bool = true
    
    lazy var imageNode = ASNetworkImageNode()
    
    public required init(_ insets: UIEdgeInsets,
                         isEdit: Bool,
                         title: String?,
                         desc: String?,
                         url: URL?,
                         imageURL: URL?) {
        self.insets = insets
        self.isEdit = isEdit
        super.init()
    }
}
