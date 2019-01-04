//
//  VEditorKit.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import RxSwift
import RxCocoa

extension Reactive where Base: VEditorNode {
    
    public var status: Observable<VEditorNode.Status> {
        return base.editorStatusRelay.asObservable()
    }
}

public class VEditorNode: ASDisplayNode, ASTableDelegate, ASTableDataSource {
    
    public typealias ContentFactory = (VEditorContent) -> ASCellNode?
    
    public enum Status {
        case loading
        case some
        case error(Error?)
    }
    
    public lazy var tableNode: ASTableNode = {
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
    
    public let parser: VEditorParser
    public let editorRule: VEditorRule
    public var editorContents: [VEditorContent] = []
    public let editorStatusRelay = PublishRelay<Status>()
    public let disposeBag = DisposeBag()
    public var editorContentFactory: (ContentFactory)? = nil
    
    private var keyboardHeight: CGFloat = 0.0
    
    public init(editorRule: VEditorRule,
                controlAreaNode: ASDisplayNode?) {
        self.controlAreaNode = controlAreaNode
        self.parser = VEditorParser(rule: editorRule)
        self.editorRule = editorRule
        super.init()
        self.automaticallyManagesSubnodes = true
        self.backgroundColor = .white
    }
    
    public func setEditorContentFactory(_ factory: @escaping ContentFactory) {
        self.editorContentFactory = factory
        self.tableNode.reloadData()
    }
    
    public override func didLoad() {
        super.didLoad()
        self.tableNode.view.separatorStyle = .none
        self.tableNode.view.showsVerticalScrollIndicator = false
        self.tableNode.view.showsHorizontalScrollIndicator = false
        self.observeKeyboardEvent()
        self.rxInitParser()
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        var tableNodeInsets: UIEdgeInsets = .zero
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
    
    public func tableNode(_ tableNode: ASTableNode,
                          numberOfRowsInSection section: Int) -> Int {
        return self.editorContents.count
    }
    
    public func tableNode(_ tableNode: ASTableNode,
                          nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            guard indexPath.row < self.editorContents.count,
                let factory = self.editorContentFactory else { return ASCellNode() }
            return factory(self.editorContents[indexPath.row]) ?? ASCellNode()
        }
    }
}

extension VEditorNode {
    
    private func rxInitParser() {
        
        parser.rx.result
            .subscribe(onNext: { [weak self] scope in
                switch scope {
                case .success(let contents):
                    self?.editorStatusRelay.accept(.some)
                    self?.editorContents = contents
                    self?.tableNode.reloadData()
                case .error(let error):
                    self?.editorStatusRelay.accept(.error(error))
                }
            }).disposed(by: disposeBag)
    }
    
    public func parseXMLString(_ xmlString: String) {
        self.editorStatusRelay.accept(.loading)
        self.parser.parseXML(xmlString)
    }
    
    public func buildXML(_ customRule: VEditorRule? = nil, packageTag: String) -> String? {
        return VEditorXMLBuilder.shared
            .buildXML(self.editorContents,
                      rule: customRule ?? editorRule,
                      packageTag: packageTag)
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
