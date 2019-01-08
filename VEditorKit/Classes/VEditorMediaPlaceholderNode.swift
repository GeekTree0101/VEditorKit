//
//  VEditorMediaPlaceholderNode.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AsyncDisplayKit

extension Reactive where Base: VEditorMediaPlaceholderNode {
    
    public var success: Observable<(VEditorMediaContent, IndexPath)> {
        return base.successRelay.asObservable().take(1)
    }
    
    public var failed: Observable<IndexPath> {
        return base.failedRelay.asObservable().take(1)
    }
}

open class VEditorMediaPlaceholderNode: ASCellNode {
    
    internal let successRelay = PublishRelay<(VEditorMediaContent, IndexPath)>()
    internal let failedRelay = PublishRelay<IndexPath>()
    internal var lazyHandlerWorkItem: DispatchWorkItem?
    
    public let xmlTag: String
    public let disposeBag = DisposeBag()
    
    public init(xmlTag: String) {
        self.xmlTag = xmlTag
        super.init()
        self.automaticallyManagesSubnodes = true
        self.selectionStyle = .none
    }
    
    override open func didLoad() {
        super.didLoad()
        guard let workItem = self.lazyHandlerWorkItem else { return }
        DispatchQueue.main.async(execute: workItem)
    }
    
    public func onSuccess(_ replaceContent: VEditorMediaContent) {
        guard let indexPath = self.indexPath else {
            lazyHandlerWorkItem = DispatchWorkItem(block: {
                self.onSuccess(replaceContent)
            })
            return
        }
        self.successRelay.accept((replaceContent, indexPath))
    }
    
    public func onFailed() {
        guard let indexPath = self.indexPath else {
            lazyHandlerWorkItem = DispatchWorkItem(block: {
                self.onFailed()
            })
            return
        }
        self.failedRelay.accept(indexPath)
    }
}
