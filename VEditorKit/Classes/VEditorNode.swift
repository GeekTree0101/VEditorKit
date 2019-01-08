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
    
    public func insertText(with: UITableView.RowAnimation = .automatic) -> Binder<IndexPath> {
        return Binder(base) { vc, indexPath in
            vc.insertEditableTextIfNeeds(indexPath, with: with)
        }
    }
}

open class VEditorNode: ASDisplayNode, ASTableDelegate, ASTableDataSource {
    
    public enum Status {
        case loading
        case some
        case error(Error?)
    }
    
    open lazy var tableNode: ASTableNode = {
        let node = ASTableNode()
        node.delegate = self
        node.dataSource = self
        node.backgroundColor = .white
        return node
    }()
    
    open var controlAreaNode: ASDisplayNode? {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    open let parser: VEditorParser
    open let editorRule: VEditorRule
    open var editorContents: [VEditorContent] = []
    open let editorStatusRelay = PublishRelay<Status>()
    open let disposeBag = DisposeBag()
    open weak var delegate: VEditorNodeDelegate!
    
    open var activeTextNode: VEditorTextNode? {
        didSet {
            self.observeActiveTextNode()
        }
    }
    
    private var typingControls: [VEditorTypingControlNode] = []
    private var keyboardHeight: CGFloat = 0.0
    private var activeTextDisposeBag = DisposeBag()
    
    public init(editorRule: VEditorRule,
                controlAreaNode: ASDisplayNode?) {
        self.controlAreaNode = controlAreaNode
        self.parser = VEditorParser(rule: editorRule)
        self.editorRule = editorRule
        super.init()
        self.automaticallyManagesSubnodes = true
        self.backgroundColor = .white
    }
    
    open override func didLoad() {
        super.didLoad()
        self.tableNode.view.separatorStyle = .none
        self.tableNode.view.showsVerticalScrollIndicator = false
        self.tableNode.view.showsHorizontalScrollIndicator = false
        self.rxInitParser()
        
        if let typingControls = self.delegate.getRegisterTypingControls() {
            self.registerTypingContols(typingControls)
        }
        
        if let dismissKeyboardNode = self.delegate.dismissKeyboardNode() {
            self.observeKeyboardEvent(dismissKeyboardNode)
        }
    }
    
    open override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
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
    
    override open func layout() {
        super.layout()
        guard let height = controlAreaNode?.frame.height else { return }
        self.tableNode.contentInset.bottom = height
    }
    
    open func tableNode(_ tableNode: ASTableNode,
                          numberOfRowsInSection section: Int) -> Int {
        return self.editorContents.count
    }
    
    open func tableNode(_ tableNode: ASTableNode,
                          nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            guard indexPath.row < self.editorContents.count else { return ASCellNode() }
            let content = self.editorContents[indexPath.row]
            
            if let placeholderContent = content as? VEditorPlaceholderContent {
                guard let cellNode = self.delegate.placeholderCellNode(placeholderContent, indexPath: indexPath) else {
                    return ASCellNode()
                }
                
                cellNode.rx.success
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] context in
                        let (replaceContent, indexPath) = context
                        self?.editorContents[indexPath.row] = replaceContent
                        self?.tableNode.reloadRows(at: [indexPath], with: .automatic)
                    })
                    .disposed(by: cellNode.disposeBag)
                
                cellNode.rx.failed
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] indexPath in
                        self?.editorContents.remove(at: indexPath.row)
                        self?.tableNode.deleteRows(at: [indexPath], with: .automatic)
                    })
                    .disposed(by: cellNode.disposeBag)
                
                return cellNode
            } else {
                return self.delegate.contentCellNode(content, indexPath: indexPath) ?? ASCellNode()
            }
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
    @discardableResult open func registerTypingContols(_ controls: [VEditorTypingControlNode]) -> Self {
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
    
    /**
     Load already active(firstResponder) textNode from cells
     
     - returns: ActiveTextNode from first responder cellNode
     */
    open func loadActiveTextNode() -> VEditorTextNode? {
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
    
    /**
     Load already active(firstResponder) textNode indexPath from cells
     
     - returns: indexPath of activeTextNode
     */
    open func loadActiveTextNodeIndexPath() -> IndexPath? {
        guard let aciveTextCellNode: VEditorTextCellNode? =
            self.tableNode.visibleNodes
                .map({ $0 as? VEditorTextCellNode })
                .filter({ $0?.textNode.isFirstResponder() ?? false })
                .first else {
                    return nil
        }
        
        return aciveTextCellNode?.indexPath
    }
    
    internal func observeActiveTextNode() {
        // dispose prev activeText observers
        self.activeTextDisposeBag = DisposeBag()
        
        activeTextNode?.rx.currentLocationXMLTags
            .subscribe(onNext: { [weak self] activeXMLs in
                // reset control status before fetch current attribute
                self?.enableAllOfTypingControls()
                self?.currentAttributeFetch(.location,
                                           activeXMLs: activeXMLs,
                                           isBlockStyle: false)
            }).disposed(by: activeTextDisposeBag)
        
        activeTextNode?.rx.caretRect
            .subscribe(onNext: { [weak self] rect in
                self?.scrollToCursor(rect)
            }).disposed(by: activeTextDisposeBag)
        
        activeTextNode?.rx.generateLinkPreview
            .subscribe(onNext: { [weak self] link, index in
                self?.generateLinkPreview(link, splitIndex: index)
            }).disposed(by: activeTextDisposeBag)
        
        activeTextNode?.rx.textEmptied
            .subscribe(onNext: { [weak self] () in
                self?.deleteUnnecessaryEditableTextIfNeeds()
            }).disposed(by: activeTextDisposeBag)
    }
    
    internal enum VEditorAttributeControlScope {
        case controlTap(Bool, String)
        case location
    }
    
    @objc private func didTapTypingControl(_ sender: VEditorTypingControlNode) {
        guard !sender.isExternalHandler else { return }
        guard let activeTextNode = self.loadActiveTextNode() else { return }
        
        let isActive: Bool = sender.isSelected
        let currentXMLTag: String = sender.xmlTag
        
        let activeXMLs: [String] =
            typingControls
                .filter({ $0 != sender })
                .filter({ $0.isSelected })
                .map({ $0.xmlTag })
        
        self.currentAttributeFetch(.controlTap(isActive, currentXMLTag),
                                   activeXMLs: activeXMLs,
                                   isBlockStyle: sender.isBlockStyle)
    }
    
    private func currentAttributeFetch(_ scope: VEditorAttributeControlScope,
                                       activeXMLs: [String],
                                       isBlockStyle: Bool) {
        
        var activeXMLs: [String] = activeXMLs
        var inactiveXMLs: [String] = []
        var disableXMLs: [String] = []
        
        switch scope {
        case .controlTap(let isActive, let currentXMLTag):
            if isActive {
                inactiveXMLs.append(currentXMLTag)
                inactiveXMLs.append(contentsOf: editorRule.enableTypingXMLs(currentXMLTag) ?? [])
                activeXMLs.append(contentsOf: editorRule.activeTypingXMLs(currentXMLTag) ?? [])
            } else {
                activeXMLs.append(currentXMLTag)
                disableXMLs.append(contentsOf: editorRule.disableTypingXMLs(currentXMLTag) ?? [])
                inactiveXMLs.append(contentsOf: editorRule.inactiveTypingXMLs(currentXMLTag) ?? [])
            }
        case .location:
            break
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
                                                          isBlock: isBlockStyle)
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
    
    private func scrollToCursor(_ caretRect: CGRect) {
        let visibleRect =
            self.tableNode.view.convert(caretRect,
                                        from: self.activeTextNode?.view)
        (self.tableNode.view as UIScrollView)
            .scrollRectToVisible(visibleRect, animated: false)
    }
    
    private func generateLinkPreview(_ url: URL, splitIndex: Int) {
        guard let tag = self.editorRule.linkStyleXMLTag else { return }
        self.insertContent(VEditorPlaceholderContent.init(xmlTag: tag, model: url as Any),
                           splitIndex: splitIndex)
    }
}

// MARK: - Editor Content Management
extension VEditorNode {
    
    
    /**
     append Content
     - important: Do not pass NSAttributedString on content parameter
     - parameters:
     - content: placeholder or media content
     */
    open func appendContent(_ content: VEditorContent,
                            section: Int = 0,
                            scrollPosition: UITableView.ScrollPosition = .bottom,
                            animated: Bool = true) {
        let indexPath = IndexPath(row: max(0, self.editorContents.count - 1), section: section)
        self.insertContent(content, indexPath: indexPath)
    }
    
    /**
     append Contents
     - important: Do not pass NSAttributedString on content parameter
     - parameters:
     - content: placeholder or media content
     */
    open func appendContent(_ contents: [VEditorContent],
                            section: Int = 0,
                            scrollPosition: UITableView.ScrollPosition = .bottom,
                            animated: Bool = true) {
        let indexPath = IndexPath(row: max(0, self.editorContents.count - 1), section: section)
        self.insertContent(contents, indexPath: indexPath)
    }
    
    /**
     Insertion Content
     - important: Do not pass NSAttributedString on content parameter
     - parameters:
     - content: placeholder or media content
     - indexPath: insert indexPath
     */
    open func insertContent(_ content: VEditorContent,
                              indexPath: IndexPath,
                              scrollPosition: UITableView.ScrollPosition = .bottom,
                              animated: Bool = true) {
        guard !(content is NSAttributedString) else {
            fatalError("VEditorFatalError: Do not pass NSAttributedString on content parameter")
        }
        
        if editorContents.count == indexPath.row + 1 {
            self.editorContents.append(content)
        } else{
            self.editorContents.insert(content, at: indexPath.row + 1)
        }
        
        let contentIndexPath: IndexPath = .init(row: indexPath.row + 1, section: indexPath.section)
        
        self.tableNode.performBatchUpdates({
            self.tableNode.insertRows(at: [contentIndexPath],
                                      with: animated ? .automatic: .none)
        }, completion: { fin in
            guard fin else { return }
            self.tableNode.scrollToRow(at: contentIndexPath,
                                       at: scrollPosition,
                                       animated: animated)
        })
    }
    
    /**
     Insertion Content Array
     
     - important: Do not pass NSAttributedString on content parameter
     - parameters:
     - contents: Array of placeholder or media content
     - indexPath: IndexPath
     */
    open func insertContent(_ contents: [VEditorContent],
                              indexPath: IndexPath,
                              scrollPosition: UITableView.ScrollPosition = .bottom,
                              animated: Bool = true) {
        guard !contents.contains(where: { $0 is NSAttributedString }) else {
            fatalError("VEditorFatalError: Do not pass NSAttributedString on content parameter")
        }
        
        if editorContents.count == indexPath.row + 1 {
            self.editorContents.append(contentsOf: contents)
        } else{
            self.editorContents.insert(contentsOf: contents, at: indexPath.row + 1)
        }
        
        let contentIndexPaths: [IndexPath] = contents.enumerated().map({ index, _ -> IndexPath in
            return .init(row: indexPath.row + 1 + index, section: indexPath.section)
        })
        
        self.tableNode.performBatchUpdates({
            self.tableNode.insertRows(at: contentIndexPaths,
                                      with: animated ? .automatic: .none)
        }, completion: { fin in
            guard fin, let lastIndexPath = contentIndexPaths.last else { return }
            self.tableNode.scrollToRow(at: lastIndexPath,
                                       at: scrollPosition,
                                       animated: animated)
        })
    }
    
    /**
     Insertion Content with Text Split Index
     
     - important: Do not pass NSAttributedString on content parameter
     - parameters:
     - content: placeholder or media content
     - splitIndex: SplitIndex on textNode
     */
    open func insertContent(_ content: VEditorContent,
                              splitIndex: Int,
                              scrollPosition: UITableView.ScrollPosition = .bottom,
                              animated: Bool = true) {
        guard !(content is NSAttributedString) else {
            fatalError("VEditorFatalError: Do not pass NSAttributedString on content parameter")
        }
        
        guard let indexPath = self.loadActiveTextNodeIndexPath(),
            let attrText = self.activeTextNode?.textStorage?.internalAttributedString else { return }
        
        // STEP1: Split textStorage with replaceTextStorage
        let length: Int = attrText.length
        let prefixRange: NSRange = .init(location: 0, length: splitIndex)
        let tailRange: NSRange = .init(location: splitIndex, length: length - splitIndex)
        
        let prefixAttrText = attrText.attributedSubstring(from: prefixRange)
        let tailAttrText = attrText.attributedSubstring(from: tailRange)
        
        self.activeTextNode?.textStorage?.setAttributedString(prefixAttrText)
        
        // STEP2: Get VEditorContent with prepare update editor
        let insertItems: [VEditorContent] = [content, tailAttrText]
        
        if editorContents.count == indexPath.row + 1 {
            self.editorContents.append(contentsOf: insertItems)
        } else{
            self.editorContents.insert(contentsOf: insertItems, at: indexPath.row + 1)
        }
        
        let contentIndexPath: IndexPath = .init(row: indexPath.row + 1, section: indexPath.section)
        let splitedTextIndexPath: IndexPath = .init(row: indexPath.row + 2, section: indexPath.section)
        
        // STEP3: Fetch Placeholder or MediaContent with splitted text
        self.tableNode.performBatchUpdates({
            self.tableNode.insertRows(at: [contentIndexPath, splitedTextIndexPath],
                                      with: animated ? .automatic: .none)
        }, completion: { fin in
            guard fin else { return }
            if let cellNode = self.tableNode.nodeForRow(at: splitedTextIndexPath) as? VEditorTextCellNode {
                self.activeTextNode?.resignFirstResponder()
                self.activeTextNode = cellNode.textNode
                self.activeTextNode?.becomeFirstResponder()
            }
            self.tableNode.scrollToRow(at: splitedTextIndexPath,
                                       at: scrollPosition,
                                       animated: animated)
        })
    }
    
    /**
     Editable textView insertion if needs
     
     - parameters:
     - indexPath: insert target indexPath
     - with: UITableView rowAnimation, default is automatic
     */
    open func insertEditableTextIfNeeds(_ indexPath: IndexPath,
                                        with: UITableView.RowAnimation = .automatic) {
        let beforeIndex: Int = max(0, indexPath.row - 1)
        guard !(self.editorContents[beforeIndex] is NSAttributedString) else { return }
        var defaultAttributes = self.editorRule.defaultAttribute()
        defaultAttributes[VEditorAttributeKey] = [self.editorRule.defaultStyleXMLTag]
        let emptyAttributedText = NSAttributedString(string: "",
                                                     attributes: defaultAttributes)
        
        self.editorContents.insert(emptyAttributedText, at: indexPath.row)
        let targetIndexPath: IndexPath =
            .init(row: indexPath.row, section: indexPath.section)
        
        self.tableNode.performBatch(animated: with != .none, updates: {
            self.tableNode.insertRows(at: [targetIndexPath], with: with)
        }, completion: { fin in
            guard fin else { return }
            guard let cellNode = self.tableNode
                .nodeForRow(at: targetIndexPath) as? VEditorTextCellNode else {
                return
            }
            self.activeTextNode?.resignFirstResponder()
            cellNode.textNode.becomeFirstResponder()
            self.activeTextNode = cellNode.textNode
        })
    }
    
    private func deleteUnnecessaryEditableTextIfNeeds(with: UITableView.RowAnimation = .automatic) {
        guard let indexPath = self.loadActiveTextNodeIndexPath() else { return }
        
        self.activeTextNode?.resignFirstResponder()
        self.activeTextNode = nil
        self.editorContents.remove(at: indexPath.row)
        self.tableNode.deleteRows(at: [indexPath], with: with)
    }
}

// MARK: - Editor XML Parser & Builder
extension VEditorNode {
    
    /**
     Parse XML string to Contents
     
     - parameters:
     - xlmString: XML String
     */
    open func parseXMLString(_ xmlString: String) {
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
    open func buildXML(_ customRule: VEditorRule? = nil, packageTag: String) -> String? {
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
    open func synchronizeFetchContents(in section: Int = 0,
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
    open func mergeTextContents(target: IndexPath,
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
    open func deleteTargetContent(_ indexPath: IndexPath?, animated: Bool) {
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
    @discardableResult open func observeKeyboardEvent(_ node: ASControlNode?) -> Self {
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
    @objc open func keyboardDismissIfNeeds() {
        guard let textNode = self.loadActiveTextNode() else { return }
        textNode.resignFirstResponder()
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        self.keyboardHeight = keyboardSize.height
        self.enableAllOfTypingControls()
        self.activeTextNode = self.loadActiveTextNode()
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
