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
    
    public func deleteContent(animated: Bool) -> Binder<IndexPath?> {
        return Binder(base) { vc, indexPath in
            vc.deleteTargetContent(indexPath, animated: animated)
        }
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
    public var activeTextNode: VEditorTextNode?
    
    private var typingControls: [VEditorTypingControlNode] = []
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
    
    /**
     Setup editor content factory
     
     - important: Recommend read reference
     
     - parameters:
     - factory: you will got VEditorContent and than return optional ASCellNode
     */
    public func setEditorContentFactory(_ factory: @escaping ContentFactory) {
        self.editorContentFactory = factory
        self.tableNode.reloadData()
    }
    
    public override func didLoad() {
        super.didLoad()
        self.tableNode.view.separatorStyle = .none
        self.tableNode.view.showsVerticalScrollIndicator = false
        self.tableNode.view.showsHorizontalScrollIndicator = false
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
    
    override public func layout() {
        super.layout()
        guard let height = controlAreaNode?.frame.height else { return }
        self.tableNode.contentInset.bottom = height
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

// MARK: - Editor Text Control
extension VEditorNode {
    
    /**
     Register Typing Control Nodes
     
     - parameters:
     - controls: Array of VEditorTypingControlNode
     */
    @discardableResult public func registerTypingContols(_ controls: [VEditorTypingControlNode]) -> Self {
        guard self.typingControls.isEmpty else {
            fatalError("VEditorKit Error: Already registed typing controls")
        }
        self.typingControls = controls
        for controlNode in self.typingControls {
            controlNode.addTarget(self, action: #selector(didTapTypingControl(_:)), forControlEvents: .touchUpInside)
        }
        self.disableAllOfTypingControls()
        return self
    }
    
    @objc private func didTapTypingControl(_ sender: VEditorTypingControlNode) {
        guard !sender.isExternalHandler else { return }
        guard let activeTextNode = self.loadActiveTextNode() else { return }
        
        let isActive: Bool = sender.isSelected
        let currentXMLTag: String = sender.xmlTag
        
        var activeXMLs: [String] =
            typingControls
                .filter({ $0 != sender })
                .filter({ $0.isSelected })
                .map({ $0.xmlTag })
        
        var inactiveXMLs: [String] = []
        var disableXMLs: [String] = []
        
        if isActive {
            inactiveXMLs.append(currentXMLTag)
            inactiveXMLs.append(contentsOf: editorRule.enableTypingXMLs(currentXMLTag) ?? [])
            activeXMLs.append(contentsOf: editorRule.activeTypingXMLs(currentXMLTag) ?? [])
        } else {
            activeXMLs.append(currentXMLTag)
            disableXMLs.append(contentsOf: editorRule.disableTypingXMLs(currentXMLTag) ?? [])
            inactiveXMLs.append(contentsOf: editorRule.inactiveTypingXMLs(currentXMLTag) ?? [])
        }
        
        activeXMLs = activeXMLs
            .filter({ !inactiveXMLs.contains($0) })
            .filter({ !disableXMLs.contains($0) })
        
        inactiveXMLs = inactiveXMLs
            .filter({ !disableXMLs.contains($0) })
        
        for control in typingControls {
            if activeXMLs.contains(control.xmlTag) {
                control.isSelected = true
                control.isEnabled = true
            } else if inactiveXMLs.contains(control.xmlTag) {
                control.isSelected = false
                control.isEnabled = true
            } else if disableXMLs.contains(control.xmlTag) {
                control.isEnabled = false
            }
        }
        
        var currentActiveXMLs: [String] = typingControls
            .filter({ $0.isSelected })
            .map({ $0.xmlTag })
        
        
        if currentActiveXMLs.isEmpty {
            currentActiveXMLs.append(editorRule.defaultStyleXMLTag)
        }
        
        let initialStyle = VEditorStyle([.extraAttributes([VEditorAttributeKey: currentActiveXMLs])])
        
        let currentAttribute: VEditorStyleAttribute = currentActiveXMLs
            .map({ self.editorRule.paragraphStyle($0, attributes: [:]) })
            .filter { $0 != nil }
            .map { $0! }
            .reduce(initialStyle, { result, style -> VEditorStyle in
                return result.byAdding(stringStyle: style)
            }).attributes
        
        self.activeTextNode?.updateCurrentTypingAttribute(currentAttribute,
                                                          isBlock: sender.isBlockStyle)
    }
    
    private func disableAllOfTypingControls() {
        self.typingControls.forEach({ node in
            node.isEnabled = false
        })
    }
    
    private func enableAllOfTypingControls() {
        self.typingControls.forEach({ node in
            node.isEnabled = true
            node.isSelected = false
        })
    }
    
    /**
     Load already active(firstResponder) textNode from cells
     */
    public func loadActiveTextNode() -> VEditorTextNode? {
        guard let aciveTextCellNode: VEditorTextCellNode? =
            self.tableNode.visibleNodes
                .map({ $0 as? VEditorTextCellNode })
                .filter({ $0?.textNode.isFirstResponder() ?? false })
                .first,
            let textNode = aciveTextCellNode?.textNode else {
                return nil
        }
        self.activeTextNode = textNode
        return textNode
    }
}

// MARK - Editor XML Parser & Builder
extension VEditorNode {
    
    /**
     Parse XML string to Contents
     
     - parameters:
     - xlmString: XML String
     */
    public func parseXMLString(_ xmlString: String) {
        self.editorStatusRelay.accept(.loading)
        self.parser.parseXML(xmlString)
    }
    
    /**
     Build content to XML string
     
     - important: package tag means capsule tag. eg: <PACKAGE>...output...</PACKAGE>
     
     - parameters:
     - customRule: if you set customReule params than default rule will ignore
     - packageTag: capsule tag for output xml content string
     */
    public func buildXML(_ customRule: VEditorRule? = nil, packageTag: String) -> String? {
        return VEditorXMLBuilder.shared
            .buildXML(self.editorContents,
                      rule: customRule ?? editorRule,
                      packageTag: packageTag)
    }
    
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
    
    /**
     Synchronize contents fetching
     
     - important: You can use this method before make & save editor draft
     - parameters:
     - section: editor target section
     - complate: complate syncronize callback
     */
    public func synchronizeFetchContents(in section: Int = 0,
                                         _ complate: @escaping () -> Void) {
        let numberOfSection = self.tableNode.numberOfSections
        guard section >= 0, section < numberOfSection else {
            fatalError("Invalid access section \(section) in \(numberOfSection)")
        }
        
        let nodeCount = tableNode.numberOfRows(inSection: section)
        let nodes = (0 ..< nodeCount)
            .map({ IndexPath.init(row: $0, section: section) })
            .map({ tableNode.nodeForRow(at: $0) })
            .map({ $0 as? VEditorTextCellNode })
            .filter({ $0 != nil })
            .map({ $0! })
        
        for node in nodes {
            guard let index = node.indexPath?.row,
                let currentAttributedText = node.textNode.textStorage?
                    .attributedString() else { return }
            self.editorContents[index] = currentAttributedText
        }
        
        complate()
    }
    
    /**
     merge two text content
     
     - important: when you remove media content between text nodes than it should be run
     - parameters:
     - target: remove target indexPath
     - to: attach text node indexPath
     - animated: remove node animation
     */
    public func mergeTextContents(target: IndexPath,
                                  to: IndexPath,
                                  animated: Bool) {
        
        guard let targetNode = tableNode.nodeForRow(at: target) as? VEditorTextCellNode,
            let sourceNode = tableNode.nodeForRow(at: to) as? VEditorTextCellNode,
            let targetAttributedText = targetNode.textNode.attributedText else {
                return
        }
        
        var mutableAttrText = NSMutableAttributedString(attributedString: targetAttributedText)
        var newlineAttribute = self.editorRule.defaultAttribute()
        newlineAttribute[VEditorAttributeKey] = [self.editorRule.defaultStyleXMLTag]
        mutableAttrText.append(NSAttributedString.init(string: "\n",
                                                       attributes: newlineAttribute))
        
        self.editorContents.remove(at: target.row)
        self.tableNode.deleteRows(at: [target], with: animated ? .automatic: .none)
        sourceNode.textNode.textStorage?.insert(mutableAttrText, at: 0)
        sourceNode.textNode.setNeedsLayout()
    }
    
    /**
     delete target content indexPath
     
     - parameters:
     - indexPath: delete target indexPath
     */
    public func deleteTargetContent(_ indexPath: IndexPath?, animated: Bool) {
        guard let indexPath = indexPath,
            indexPath.row < self.editorContents.count else { return }
        self.editorContents.remove(at: indexPath.row)
        self.tableNode.performBatch(animated: animated, updates: {
            self.tableNode.deleteRows(at: [indexPath], with: animated ? .automatic: .none)
        }, completion: { fin in
            guard fin,
                indexPath.row < self.editorContents.count,
                indexPath.row - 1 >= 0 else { return }
            // merge if needs
            
            let beforeCell = self.tableNode
                .nodeForRow(at: .init(row: indexPath.row - 1,
                                      section: indexPath.section)) as? VEditorTextCellNode
            let currentCell = self.tableNode
                .nodeForRow(at: .init(row: indexPath.row,
                                      section: indexPath.section)) as? VEditorTextCellNode
            
            guard let target = beforeCell?.indexPath,
                let to = currentCell?.indexPath else {
                return
            }
            self.mergeTextContents(target: target, to: to, animated: animated)
        })
    }
}

// MARK: - observe Keyboard
extension VEditorNode {
    
    /**
     Observe keyboard event and observe dismiss node touchUpInside event.
     
     - parameters:
     - node: Dismiss keyboard button node
     */
    @discardableResult public func observeKeyboardEvent(_ node: ASControlNode?) -> Self {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(VEditorNode.keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(VEditorNode.keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        node?.addTarget(self,
                        action: #selector(keyboardDismissIfNeeds),
                        forControlEvents: .touchUpInside)
        return self
    }
    
    /**
     Dismiss Keyboard from ActiveTextNode
     */
    @objc public func keyboardDismissIfNeeds() {
        guard let textNode = self.loadActiveTextNode() else { return }
        textNode.resignFirstResponder()
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        self.keyboardHeight = keyboardSize.height
        self.enableAllOfTypingControls()
        self.transitionLayout(withAnimation: true,
                              shouldMeasureAsync: false,
                              measurementCompletion: nil)
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        self.keyboardHeight = 0.0
        self.disableAllOfTypingControls()
        self.transitionLayout(withAnimation: true,
                              shouldMeasureAsync: false,
                              measurementCompletion: nil)
    }
}
