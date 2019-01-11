//
//  VEditorImageNode.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import RxCocoa
import RxSwift

open class VEditorImageNode: VEditorMediaNode<ASNetworkImageNode> {
    
    public required init(isEdit: Bool) {
        super.init(node: .init(), isEdit: isEdit)
        self.node.backgroundColor = .lightGray
        self.node.placeholderColor = .lightGray
        self.automaticallyManagesSubnodes = true
        self.selectionStyle = .none
    }
    
    /**
     Set image url
     
     - important: If you set filePath url than will load data from filepath with make image
     
     - parameters:
     - url: image network url or filepath local url
     - returns: self (VEditorImageNode)
     */
    @discardableResult open func setURL(_ url: URL?) -> Self {
        if url?.isFileURL ?? false {
            guard let imageFileURL = url,
                let imageData = try? Data(contentsOf: imageFileURL,
                                          options: []) else { return self }
            self.node.image = UIImage(data: imageData)
        } else {
            self.node.setURL(url, resetToDefault: true)
        }
        return self
    }
    
    /**
     Set imageNode placeholder color
     
     - parameters:
     - color: placeholder color, default is lightGray
     - returns: self (VEditorImageNode)
     */
    @discardableResult open func setPlaceholderColor(_ color: UIColor) -> Self {
        self.node.placeholderColor = color
        return self
    }
    
    /**
     Set imageNode background color
     
     - parameters:
     - color: background color, default is lightGray
     - returns: self (VEditorImageNode)
     */
    @discardableResult open func setBackgroundColor(_ color: UIColor) -> Self {
        self.node.backgroundColor = color
        return self
    }
}
