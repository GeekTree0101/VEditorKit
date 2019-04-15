//
//  VEditorNodeSpec.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Quick
import Nimble
import RxTest
import AsyncDisplayKit
import RxBlocking
import VEditorKit

class VEditorNodeSpec: QuickSpec {
    
    let controlAreaNode = EditorControlAreaNode(rule: EditorRule())
    let rule = EditorRule()
    
    override func spec() {
        
        describe("VEditorNode Unit Test") {
            
            var node: VEditorNode!
            
            context("initialization test") {
                
                var nonControlAreaEditor: VEditorNode!
                
                beforeEach {
                    node = VEditorNode
                        .init(editorRule: self.rule,
                              controlAreaNode: self.controlAreaNode)
                    node.delegate = self
                    
                    nonControlAreaEditor = VEditorNode
                        .init(editorRule: self.rule,
                              controlAreaNode: nil)
                }
                
                it("should be success") {
                    expect(node).to(beAKindOf(VEditorNode.self))
                    expect(node.automaticallyManagesSubnodes).to(beTrue())
                    expect(node.automaticallyRelayoutOnSafeAreaChanges).to(beTrue())
                    expect(node.backgroundColor).to(equal(UIColor.white))
                    expect(node.delegate).toNot(beNil())
                }
                
                it("should be didLoad success") {
                    node.didLoad()
                    expect(node.tableNode.view.separatorStyle == .none).to(beTrue())
                    expect(node.tableNode.view.showsVerticalScrollIndicator).to(beFalse())
                    expect(node.tableNode.view.showsHorizontalScrollIndicator).to(beFalse())
                }
                
                it("should get controlNodes") {
                    expect(node.delegate.getRegisterTypingControls())
                        .to(equal(self.controlAreaNode.typingControlNodes))
                    expect(node.delegate.dismissKeyboardNode())
                        .to(equal(self.controlAreaNode.dismissNode))
                }
                
                it("shouldn't get controlNodes") {
                    expect(nonControlAreaEditor.delegate?.getRegisterTypingControls())
                        .to(beNil())
                    expect(nonControlAreaEditor.delegate?.dismissKeyboardNode())
                        .to(beNil())
                }
            }
            
            context("parse xmlString test") {
                
                beforeEach {
                    node = VEditorNode
                        .init(editorRule: self.rule,
                              controlAreaNode: self.controlAreaNode)
                    node.delegate = self
                    node.didLoad()
                    let path = Bundle.main.path(forResource: "content", ofType: "xml")!
                    let pathURL = URL(fileURLWithPath: path)
                    let data = try! Data(contentsOf: pathURL)
                    let content = String(data: data, encoding: .utf8)!
                    node.parseXMLString(content)
                }
                
                it("should be append new content") {
                    expect(node.editorContents.count)
                        .to(equal(9))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(2))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                }
            }

            context("active text node test") {
                
                var textCellNodeIndexPaths: [IndexPath]!
                
                beforeEach {
                    node = VEditorNode
                        .init(editorRule: self.rule,
                              controlAreaNode: self.controlAreaNode)
                    node.delegate = self
                    node.didLoad()
                    let path = Bundle.main.path(forResource: "content", ofType: "xml")!
                    let pathURL = URL(fileURLWithPath: path)
                    let data = try! Data(contentsOf: pathURL)
                    let content = String(data: data, encoding: .utf8)!
                    node.parseXMLString(content)
                    textCellNodeIndexPaths = node.editorContents
                        .enumerated()
                        .map({ index, content -> IndexPath? in
                            if content is NSAttributedString {
                                return IndexPath.init(row: index, section: 0)
                            } else {
                                return nil
                            }
                        })
                        .filter({ $0 != nil })
                        .map({ $0! })
                }
                
                it("should get activeText") {
                    // become first textNode activeStatus
                    let cellNode = node.tableNode
                        .nodeForRow(at: textCellNodeIndexPaths.first!) as! VEditorTextCellNode
                    node.fetchNewActiveTextNode(cellNode)
                    
                    expect(node.activeTextIndexPath)
                        .to(equal(textCellNodeIndexPaths.first!))
                    expect(node.loadActiveTextCellNode()).toNot(beNil())
                    
                    // replace from first to last active textNode
                    let cellNode2 = node.tableNode
                        .nodeForRow(at: textCellNodeIndexPaths.last!) as! VEditorTextCellNode
                    node.fetchNewActiveTextNode(cellNode2)
                    
                    expect(node.activeTextIndexPath)
                        .to(equal(textCellNodeIndexPaths.last!))
                    expect(node.loadActiveTextCellNode()).toNot(beNil())
                }
                
                it("should be resign activeText") {
                    // become first textNode activeStatus
                    let cellNode = node.tableNode
                        .nodeForRow(at: textCellNodeIndexPaths.first!) as! VEditorTextCellNode
                    node.fetchNewActiveTextNode(cellNode)
                    
                    expect(node.activeTextIndexPath)
                        .to(equal(textCellNodeIndexPaths.first!))
                    expect(node.loadActiveTextCellNode()).toNot(beNil())
                    
                    // resign activeTextNode
                    node.resignActiveTextNode()
                    expect(node.activeTextIndexPath).to(beNil())
                    expect(node.loadActiveTextCellNode()).to(beNil())
                }
            }
        }
        
        describe("VEditorNode Fetch Content Unit Test") {
            
            var node: VEditorNode!
            
            context("append new content") {
                
                beforeEach {
                    node = VEditorNode
                        .init(editorRule: self.rule,
                              controlAreaNode: self.controlAreaNode)
                    node.delegate = self
                    node.didLoad()
                    let path = Bundle.main.path(forResource: "content", ofType: "xml")!
                    let pathURL = URL(fileURLWithPath: path)
                    let data = try! Data(contentsOf: pathURL)
                    let content = String(data: data, encoding: .utf8)!
                    node.parseXMLString(content)
                }
                
                it("should be append content at last") {
                    expect(node.editorContents.count)
                        .to(equal(9))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(2))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.last is VImageContent).to(beFalse())
                    
                    let mockContent = VImageContent.init("img", attributes: [:])
                    node.fetchNewContent(mockContent, scope: .last)
                    
                    expect(node.editorContents.count)
                        .to(equal(11))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(6))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(2))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(2))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.last is VImageContent).to(beFalse())
                    expect(node.editorContents[node.editorContents.count - 2] is VImageContent).to(beTrue())
                }
                
                it("should be append contents at last") {
                    expect(node.editorContents.count)
                        .to(equal(9))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(2))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.last is VVideoContent).to(beFalse())
                    
                    let mockContent = VVideoContent.init("video", attributes: [:])
                    node.fetchNewContents([mockContent, mockContent, mockContent], scope: .last)
                    
                    expect(node.editorContents.count)
                        .to(equal(13))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(6))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.last is VVideoContent).to(beFalse())
                    expect(node.editorContents[node.editorContents.count - 2] is VVideoContent).to(beTrue())
                }
                
                it("should be append content at fisrt") {
                    expect(node.editorContents.count)
                        .to(equal(9))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(2))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.first is VImageContent).to(beFalse())
                    
                    let mockContent = VImageContent.init("img", attributes: [:])
                    node.fetchNewContent(mockContent, scope: .first)
                    
                    expect(node.editorContents.count)
                        .to(equal(10))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(2))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(2))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.first is VImageContent).to(beTrue())
                }
                
                it("should be append contents at first") {
                    expect(node.editorContents.count)
                        .to(equal(9))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(2))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.first is VVideoContent).to(beFalse())
                    
                    let mockContent = VVideoContent.init("video", attributes: [:])
                    node.fetchNewContents([mockContent, mockContent, mockContent], scope: .first)
                    
                    expect(node.editorContents.count)
                        .to(equal(12))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.first is VVideoContent).to(beTrue())
                }
                
                it("should be insert content") {
                    expect(node.editorContents.count)
                        .to(equal(9))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(2))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                    expect(node.editorContents[1] is VVideoContent).to(beFalse())
                    
                    let mockContent = VVideoContent.init("video", attributes: [:])
                    node.fetchNewContent(mockContent, scope: .insert(.init(row: 1, section: 0)))
                    
                    expect(node.editorContents.count)
                        .to(equal(10))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(3))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                    expect(node.editorContents[1] is VVideoContent).to(beTrue())
                }
                
                it("should be insert contents") {
                    expect(node.editorContents.count)
                        .to(equal(9))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(2))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                    expect(node.editorContents[1] is VVideoContent).to(beFalse())
                    expect(node.editorContents[2] is VVideoContent).to(beFalse())
                    
                    let mockContent = VVideoContent.init("video", attributes: [:])
                    node.fetchNewContents([mockContent, mockContent], scope: .insert(.init(row: 1, section: 0)))
                    
                    expect(node.editorContents.count)
                        .to(equal(11))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(4))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                    expect(node.editorContents[1] is VVideoContent).to(beTrue())
                    expect(node.editorContents[2] is VVideoContent).to(beTrue())
                    expect(node.editorContents[3] is VVideoContent).to(beFalse())
                }
                
                
                it("should be insert mediaContent on text with split") {
                    expect(node.editorContents.count)
                        .to(equal(9))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(2))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                    
                    let mockContent = VVideoContent.init("video", attributes: [:])
                    let targetNode = node.tableNode.nodeForRow(at: .init(row: 2, section: 0)) as! VEditorTextCellNode
                    node.fetchNewActiveTextNode(targetNode)
                    node.fetchNewContent(mockContent, scope: .automatic)
                    
                    expect(node.editorContents.count)
                        .to(equal(10))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(3))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                }
                
                it("should be insert mediaContent on text without split text") {
                    expect(node.editorContents.count)
                        .to(equal(9))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(5))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(2))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.last is VVideoContent).to(beFalse())
                    
                    let mockContent = VVideoContent.init("video", attributes: [:])
                    node.resignActiveTextNode()
                    node.fetchNewContent(mockContent, scope: .automatic)
                    
                    expect(node.editorContents.count)
                        .to(equal(11))
                    expect(node.editorContents.filter({ $0 is NSAttributedString }).count)
                        .to(equal(6))
                    expect(node.editorContents.filter({ $0 is VVideoContent }).count)
                        .to(equal(3))
                    expect(node.editorContents.filter({ $0 is VImageContent }).count)
                        .to(equal(1))
                    expect(node.editorContents.filter({ $0 is VOpenGraphContent }).count)
                        .to(equal(1))
                    expect(node.editorContents[node.editorContents.count - 2] is VVideoContent).to(beTrue())
                    expect(node.editorContents.last is VVideoContent).to(beFalse())
                }
            }
        }
    }
}

extension VEditorNodeSpec: VEditorNodeDelegate {
    
    func getRegisterTypingControls() -> [VEditorTypingControlNode]? {
        return self.controlAreaNode.typingControlNodes
    }
    
    func dismissKeyboardNode() -> ASControlNode? {
        return self.controlAreaNode.dismissNode
    }
    
    func placeholderCellNode(_ content: VEditorPlaceholderContent, indexPath: IndexPath) -> VEditorMediaPlaceholderNode? {
        guard let xml = EditorRule.XML.init(rawValue: content.xmlTag) else { return nil }
        
        switch xml {
        case .article:
            guard let url = content.model as? URL else { return nil }
            return EditorOpenGraphPlaceholder(xmlTag: EditorRule.XML.opengraph.rawValue,
                                              url: url)
        default:
            break
        }
        return nil
    }
    
    func contentCellNode(_ content: VEditorContent,
                         indexPath: IndexPath) -> ASCellNode? {
        switch content {
        case let text as NSAttributedString:
            return VEditorTextCellNode(isEdit: true,
                                       placeholderText: nil,
                                       attributedText: text,
                                       rule: self.rule,
                                       regexDelegate: nil,
                                       automaticallyGenerateLinkPreview: false)
            
        case is VImageContent:
            return VEditorImageNode(isEdit: true)
            
        case is VVideoContent:
            return VEditorVideoNode(isEdit: true)
            
        case is VOpenGraphContent:
            return VEditorOpenGraphNode(isEdit: true)
        default:
            return nil
        }
    }
}
