//
//  VEditorKit.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit


public class VEditorNode: ASDisplayNode, ASTableDelegate, ASTableDataSource {
    
    lazy var tableNode: ASTableNode = {
        let node = ASTableNode()
        node.delegate = self
        node.dataSource = self
        node.backgroundColor = .white
        return node
    }()
    
    public var controlAreaNode: ASDisplayNode? {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    private var keyboardHeight: CGFloat = 0.0
    
    public init(controlAreaNode: ASDisplayNode?) {
        self.controlAreaNode = controlAreaNode
        super.init()
        self.automaticallyManagesSubnodes = true
        self.backgroundColor = .white
    }
    
    public override func didLoad() {
        super.didLoad()
        self.tableNode.view.separatorStyle = .none
        self.tableNode.view.showsVerticalScrollIndicator = false
        self.tableNode.view.showsHorizontalScrollIndicator = false
        self.observeKeyboardEvent()
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        var tableNodeInsets: UIEdgeInsets = .zero
        tableNodeInsets.top = -keyboardHeight
        tableNodeInsets.bottom = keyboardHeight
        
        let tableLayout = ASInsetLayoutSpec(insets: tableNodeInsets,
                                            child: tableNode)
        
        if let node = controlAreaNode {
            var controlAreaInsets: UIEdgeInsets = .init(top: .infinity, left: 0.0, bottom: 0.0, right: 0.0)
            controlAreaInsets.bottom = keyboardHeight
            let controlLayout = ASInsetLayoutSpec(insets: controlAreaInsets,
                                                  child: node)
            return ASOverlayLayoutSpec(child: tableLayout, overlay: controlLayout)
        } else {
            return tableLayout
        }
    }
    
    public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            return ASCellNode()
        }
    }
}

// MARK: - observe Keyboard
extension VEditorNode {
    
    private func observeKeyboardEvent() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(VEditorNode.keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(VEditorNode.keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        self.keyboardHeight = keyboardSize.height
        self.transitionLayout(withAnimation: true, shouldMeasureAsync: false, measurementCompletion: nil)
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        self.keyboardHeight = 0.0
        self.transitionLayout(withAnimation: true, shouldMeasureAsync: false, measurementCompletion: nil)
    }
}
