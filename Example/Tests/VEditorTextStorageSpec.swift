//
//  VEditorTextStorageSpec.swift
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

class VEditorTextStorageSpec: QuickSpec {
    
    override func spec() {
        
        describe("VEditorTextStorage Unit Test") {
            
            var storage: VEditorTextStorage!
            let rule = EditorRule()
            
            context("Intialization test") {
                
                beforeEach {
                    storage = VEditorTextStorage.init()
                    storage.setAttributedString(NSAttributedString(string: "test",
                                                                   attributes: rule.defaultAttribute()))
                }
                
                it("should be success initialize") {
                    expect(storage.string).to(equal("test"))
                }
            }
            
            context("update property test") {
                
                beforeEach {
                    storage = VEditorTextStorage.init()
                    storage.setAttributedString(NSAttributedString(string: "test",
                                                                   attributes: rule.defaultAttribute()))
                }
                
                it("shold be success setAttribute") {
                    storage.setAttributes(rule.linkAttribute(URL(string: "https://www.vingle.net")!),
                                          range: NSRange.init(location: 0, length: storage.length))
                    let url = storage.attributes(at: 0, effectiveRange: nil)[NSAttributedString.Key.link] as? URL
                    expect(url?.absoluteString).to(equal("https://www.vingle.net"))
                }
                
                it("should be return paragraphBlockRange") {
                    expect(storage.paragraphBlockRange(.init(location: 2, length: 1)))
                        .to(equal(NSRange.init(location: 0, length: storage.length)))
                    expect(storage.paragraphBlockRange(.init(location: 0, length: 2)))
                        .to(equal(NSRange.init(location: 0, length: storage.length)))
                    expect(storage.paragraphBlockRange(.init(location: 0, length: 0)))
                        .to(equal(NSRange.init(location: 0, length: storage.length)))
                    expect(storage.paragraphBlockRange(.init(location: 3, length: 0)))
                        .to(equal(NSRange.init(location: 0, length: storage.length)))
                }
            }
            
            context("trigger touch event") {
                
                var content: NSAttributedString!
                var node: VEditorTextNode!
                var viewOnlyNode: VEditorTextNode!
                
                beforeEach {
                    let xmlString = "<content><p>hello world @Geektree0101 <a href=\"https://www.vingle.net\">https://www.vingle.net</a></p></content>"
                    VEditorParser.init(rule: rule).parseXML(xmlString, onSuccess: { contents in
                        content = contents.first as? NSAttributedString
                    }, onError: nil)
                    node = VEditorTextNode(rule,
                                           isEdit: true,
                                           placeholderText: nil,
                                           attributedText: content)
                    node.regexDelegate = self
                    
                    viewOnlyNode = VEditorTextNode(rule,
                                                   isEdit: false,
                                                   placeholderText: nil,
                                                   attributedText: content)
                    viewOnlyNode.regexDelegate = self
                }
                
                it("should be trigger touch event [ViewOnly Avaliable]") {
                    expect(viewOnlyNode.textStorage?
                        .triggerTouchEventIfNeeds(viewOnlyNode,
                                                  customRange: NSRange.init(location: 0, length: 0)))
                        .to(beFalse())
                    expect(viewOnlyNode.textStorage?
                        .triggerTouchEventIfNeeds(viewOnlyNode,
                                                  customRange: NSRange.init(location: 15, length: 0)))
                        .to(beTrue())
                    expect(viewOnlyNode.textStorage?
                        .triggerTouchEventIfNeeds(viewOnlyNode,
                                                  customRange: NSRange.init(location: 26, length: 0)))
                        .to(beFalse())
                    expect(viewOnlyNode.textStorage?
                        .triggerTouchEventIfNeeds(viewOnlyNode,
                                                  customRange: NSRange.init(location: 32, length: 0)))
                        .to(beTrue())
                }
                
                it("shouldn't be trigger touch event") {
                    expect(node.textStorage?
                        .triggerTouchEventIfNeeds(node,
                                                  customRange: NSRange.init(location: 0, length: 0)))
                        .to(beFalse())
                    expect(node.textStorage?
                        .triggerTouchEventIfNeeds(node,
                                                  customRange: NSRange.init(location: 15, length: 0)))
                        .to(beFalse())
                    expect(node.textStorage?
                        .triggerTouchEventIfNeeds(node,
                                                  customRange: NSRange.init(location: 26, length: 0)))
                        .to(beFalse())
                    expect(node.textStorage?
                        .triggerTouchEventIfNeeds(node,
                                                  customRange: NSRange.init(location: 32, length: 0)))
                        .to(beFalse())
                }
            }
            
            context("replace attribute with regex patten match test") {
                
                var content: NSAttributedString!
                var node: VEditorTextNode!
                
                beforeEach {
                    let xmlString = "<content><p>hello world @Geektree0101 <a href=\"https://www.vingle.net\">https://www.vingle.net</a> @Hello</p></content>"
                    VEditorParser.init(rule: rule).parseXML(xmlString, onSuccess: { contents in
                        content = contents.first as? NSAttributedString
                    }, onError: nil)
                    node = VEditorTextNode(rule,
                                           isEdit: true,
                                           placeholderText: nil,
                                           attributedText: content)
                }
                
                it("should be success replace attribute with regex pattern") {
                    let fullRange = NSRange.init(location: 0, length: node.textStorage?.length ?? 0)
                    
                    expect(node.textStorage?
                        .replaceAttributeWithRegexPattenIfNeeds(node, customRange: fullRange) ?? -1)
                        .to(equal(0))
                    
                    node.regexDelegate = self
                    
                    expect(node.textStorage?
                        .replaceAttributeWithRegexPattenIfNeeds(node, customRange: fullRange) ?? -1)
                        .to(equal(2))
                }
            }
        }
    }
}

extension VEditorTextStorageSpec: VEditorRegexApplierDelegate {
    
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
