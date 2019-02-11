//
//  VEditorTextNodeSpec.swift
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

class VEditorTextNodeSpec: QuickSpec {
    
    override func spec() {
        
        describe("VEditor TextNode Unit Test") {
            
            var content: NSAttributedString!
            var node: VEditorTextNode!
            let rule = EditorRule()
            
            beforeEach {
                let xmlString = "<content><p>a<b>b<i>c</i></b></p></content>"
                VEditorParser.init(rule: rule).parseXML(xmlString, onSuccess: { contents in
                    content = contents.first as? NSAttributedString
                }, onError: nil)
            }
            
            context("Initialization test") {
                
                beforeEach {
                    node = VEditorTextNode(rule,
                                           isEdit: true,
                                           placeholderText: nil,
                                           attributedText: content)
                    node.regexDelegate = self
                    node.didLoad()
                }
                
                it("should be success") {
                    expect(node.isEdit).to(beTrue())
                    expect(node.delegate).toNot(beNil())
                    expect(node.regexDelegate).toNot(beNil())
                    expect(node.automaticallyGenerateLinkPreview).to(beFalse())
                    expect(node.currentTypingAttribute.isEmpty).to(beFalse())
                }
                
                it("should be begin editing") {
                    expect(node.editableTextNodeShouldBeginEditing(node)).to(beTrue())
                    node.isEdit = false
                    expect(node.editableTextNodeShouldBeginEditing(node)).to(beFalse())
                    node.isEdit = true
                }
                
                it("should be setup minimum text container line height") {
                    expect(node.minimumTextContainerTextLineHeight())
                        .to(equal(((rule.defaultAttribute()[.paragraphStyle] as? NSParagraphStyle)?.minimumLineHeight ?? -1.0)))
                }
            }
            
            context("forceFetchCurrentLocationAttribute: test") {
                
                beforeEach {
                    node = VEditorTextNode(rule,
                                           isEdit: true,
                                           placeholderText: nil,
                                           attributedText: content)
                    node.regexDelegate = self
                    node.didLoad()
                }
                
                it("should be get expected xmlTags") {
                    node.selectedRange = .init(location: 0, length: 0)
                    expect(node.forceFetchCurrentLocationAttribute()?.sorted())
                        .to(equal(["p"]))
                    node.selectedRange = .init(location: 1, length: 0)
                    expect(node.forceFetchCurrentLocationAttribute()?.sorted())
                        .to(equal(["p"]))
                    node.selectedRange = .init(location: 2, length: 0)
                    expect(node.forceFetchCurrentLocationAttribute()?.sorted())
                        .to(equal(["b"]))
                    node.selectedRange = .init(location: 3, length: 0)
                    expect(node.forceFetchCurrentLocationAttribute()?.sorted())
                        .to(equal(["b", "i"]))
                }
            }
        }
    }
}

extension VEditorTextNodeSpec: VEditorRegexApplierDelegate {
    
    enum EditorTextRegexPattern: String, CaseIterable {
        
        case userTag = "@(\\w*[0-9A-Za-z])"
        case hashTag = "#(\\w*[0-9A-Za-zㄱ-ㅎ가-힣])"
    }
    
    var allPattern: [String] {
        return EditorTextRegexPattern.allCases.map({ $0.rawValue })
    }
    
    func paragraphStyle(pattern: String) -> VEditorStyle? {
        guard let scope = EditorTextRegexPattern.init(rawValue: pattern) else { return nil }
        switch scope {
        case .userTag:
            return .init([.color(UIColor.init(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0))])
        case .hashTag:
            return .init([.color(UIColor.init(red: 0.2, green: 0.3, blue: 0.8, alpha: 1.0))])
        }
    }
    
    func handlePatternTouchEvent(_ pattern: String, value: Any) {
        // pass
    }
    
    func handlURLTouchEvent(_ url: URL) {
        // pass
    }
}
