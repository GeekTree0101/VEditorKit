//
//  VEditorPArserSpec.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Quick
import Nimble
import VEditorKit

class VEditorParserSpec: QuickSpec {
    
    override func spec() {
        
        describe("VEditorParser Test") {
            
            let xmlString = "<content><p>hello<b>world</b>!</p><img src=\"http://image/12345.jpg\" width=\"1000\" height=\"500\"/><a href=\"https://www.vingle.net\">LinkTest</a></content>"
            let parser = VEditorParser.init(rule: EditorRule.init())
            
            context("Parsing should be success") {
                
                var resultError: Error?
                var resultContents: [VEditorContent]?
                
                beforeEach {
                    parser.parseXML(xmlString, onSuccess: { contents in
                        resultContents = contents
                    }, onError: { error in
                        resultError = error
                    })
                }
                
                it("should be parse success") {
                    expect(resultError).to(beNil())
                    expect(resultContents?.count).to(equal(3))
                    expect(resultContents?[0]).to(beAKindOf(NSAttributedString.self))
                    expect(resultContents?[1]).to(beAKindOf(VImageContent.self))
                    expect(resultContents?[2]).to(beAKindOf(NSAttributedString.self))
                }
                
                it("should be parse attributedString") {
                    var pTagStyle = EditorRule.init().paragraphStyle("p", attributes: [:])
                    pTagStyle?.add(extraAttributes: [VEditorAttributeKey: ["p"]])
                    var bTagStyle = EditorRule.init().paragraphStyle("b", attributes: [:])
                    bTagStyle?.add(extraAttributes: [VEditorAttributeKey: ["b"]])
                    let expectedAttrText = NSMutableAttributedString.init()
                    expectedAttrText.append("hello".styled(with: pTagStyle!))
                    expectedAttrText.append("world".styled(with: bTagStyle!))
                    expectedAttrText.append("!".styled(with: pTagStyle!))
                    
                    expect(expectedAttrText == resultContents?.first as? NSAttributedString)
                        .to(beTrue())
                    expect(expectedAttrText.string == (resultContents?.first as? NSAttributedString)?.string ?? "")
                        .to(beTrue())
                }
                
                it("should be parse image content") {
                    expect((resultContents?[1] as? VImageContent)?.url?.absoluteString)
                        .to(equal("http://image/12345.jpg"))
                    expect((resultContents?[1] as? VImageContent)?.ratio).to(equal(0.5))
                }
                
                it("should be parse link") {
                    let url = (resultContents?.last as? NSAttributedString)?.attributes(at: 0, effectiveRange: nil)[NSAttributedString.Key.link] as? URL
                    expect(url?.absoluteString ?? "").to(equal("https://www.vingle.net"))
                }
                
                it("should be parse to NSAttributedString Only") {
                    expect(parser.parseXMLToAttributedString("<p>hello</p>").string == "hello")
                        .to(beTrue())
                }
            }
            
            context("HTML Entities handling test") {
                
                it("should be success to parse with HTML entities") {
                    
                    expect(parser.parseXMLToAttributedString("<p>hello &amp; world</p>").string == "hello & world")
                        .to(beTrue())
                }
                
                it("should be fail to parse with HTML entities") {
                    
                    expect(parser.parseXMLToAttributedString("<p>hello & world</p>").string == "hello & world")
                        .to(beFalse())
                }
            }
        }
    }
}
