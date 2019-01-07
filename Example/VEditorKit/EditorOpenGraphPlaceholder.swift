//
//  EditorPlaceholderCells.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AsyncDisplayKit
import VEditorKit

public class EditorOpenGraphPlaceholder: VEditorMediaPlaceholderNode {
    
    lazy var containerNode: ASDisplayNode = {
        let node = ASDisplayNode()
        node.backgroundColor = .lightGray
        node.style.height = .init(unit: .points, value: 150)
        node.cornerRadius = 20.0
        return node
    }()
    
    lazy var indicatorNode: ASDisplayNode =
        ASDisplayNode.init(viewBlock: { () -> UIView in
            return UIActivityIndicatorView.init(style: .white)
        })
    
    var indicatorView: UIActivityIndicatorView? {
        return indicatorNode.view as? UIActivityIndicatorView
    }
    
    init(xmlTag: String, url: URL) {
        super.init(xmlTag: xmlTag)
        
        MockService
            .getOgObject(url)
            .subscribe(onNext: { [weak self] attributes in
                guard let `self` = self else {
                    fatalError()
                }
                let replaceContent = VOpenGraphContent(self.xmlTag,
                                                       attributes: attributes)
                self.onSuccess(replaceContent)
                }, onError: { [weak self] _ in
                    self?.onFailed()
            }).disposed(by: disposeBag)
    }
    
    override public func didEnterVisibleState() {
        super.didEnterVisibleState()
        self.indicatorView?.startAnimating()
    }
    
    override public func didExitVisibleState() {
        super.didExitVisibleState()
        self.indicatorView?.stopAnimating()
    }
    
    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let centerLayout = ASCenterLayoutSpec(centeringOptions: .XY,
                                              sizingOptions: [],
                                              child: indicatorNode)
        let indicatorOverlayedLayout = ASOverlayLayoutSpec(child: containerNode,
                                                           overlay: centerLayout)
        let insets: UIEdgeInsets = .init(top: 15.0, left: 5.0, bottom: 15.0, right: 5.0)
        return ASInsetLayoutSpec(insets: insets, child: indicatorOverlayedLayout)
    }
}
