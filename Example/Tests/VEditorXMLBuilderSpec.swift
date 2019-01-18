//
//  VEditorXMLBuilderSpec.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Quick
import Nimble
import VEditorKit

class VEditorXMLBuilderSpec: QuickSpec {
    
    override func spec() {
        
        describe("VEditor XMLBuilder Test") {
            
            let rule = EditorRule.init()
            
            context("Build XML") {
                
                var testContents: [VEditorContent]!
                var testContents2: [VEditorContent]!
                var testContents3: [VEditorContent]!
                var testContents4: [VEditorContent]!
                var testContents5: [VEditorContent]!
                
                beforeEach {
                    var pTagStyle = EditorRule.init().paragraphStyle("p", attributes: [:])
                    pTagStyle?.add(extraAttributes: [VEditorAttributeKey: ["p"]])
                    var bTagStyle = EditorRule.init().paragraphStyle("b", attributes: [:])
                    bTagStyle?.add(extraAttributes: [VEditorAttributeKey: ["b"]])
                    var boldItalicTagStyle = EditorRule.init().paragraphStyle("b", attributes: [:])?
                        .byAdding(stringStyle: EditorRule.init().paragraphStyle("i", attributes: [:])!)
                    boldItalicTagStyle?.add(extraAttributes: [VEditorAttributeKey: ["b", "i"]])
                    
                    var headingTagStyle = EditorRule.init().paragraphStyle("h2", attributes: [:])
                    headingTagStyle?.add(extraAttributes: [VEditorAttributeKey: ["h2"]])
                    
                    let textNode = NSMutableAttributedString.init()
                    textNode.append("hello".styled(with: pTagStyle!))
                    textNode.append("world".styled(with: bTagStyle!))
                    textNode.append("!".styled(with: pTagStyle!))
                    
                    
                    let textNode2 = NSMutableAttributedString.init()
                    textNode2.append("hello".styled(with: pTagStyle!))
                    textNode2.append("world".styled(with: bTagStyle!))
                    textNode2.append("!".styled(with: pTagStyle!))
                    textNode2.append("boldItalicTest".styled(with: boldItalicTagStyle!))
                    
                    let imageNode = VImageContent.init("img", attributes: ["src": "https://test.jpg", "width": "540", "height": "810"])
                    
                    
                    let textNode3 = NSMutableAttributedString.init()
                    textNode3.append("hello".styled(with: pTagStyle!))
                    textNode3.append("world".styled(with: bTagStyle!))
                    textNode3.append("!".styled(with: pTagStyle!))
                    textNode3.append("headingTest".styled(with: headingTagStyle!))
                    textNode3.append("boldItalicTest".styled(with: boldItalicTagStyle!))
                    
                    testContents = [imageNode]
                    testContents2 = [textNode]
                    testContents3 = [textNode, imageNode]
                    testContents4 = [textNode2]
                    testContents5 = [textNode3]
                }
                
                it("shouldn't be nil after build to xmlString") {
                    
                    expect(VEditorXMLBuilder.shared.buildXML(testContents, rule: rule, packageTag: "content")).toNot(beNil())
                    expect(VEditorXMLBuilder.shared.buildXML(testContents2, rule: rule, packageTag: "content")).toNot(beNil())
                    expect(VEditorXMLBuilder.shared.buildXML(testContents3, rule: rule, packageTag: "content")).toNot(beNil())
                    expect(VEditorXMLBuilder.shared.buildXML(testContents4, rule: rule, packageTag: "content")).toNot(beNil())
                    
                    expect(VEditorXMLBuilder.shared.buildXML(testContents, rule: rule, packageTag: nil)).toNot(beNil())
                    expect(VEditorXMLBuilder.shared.buildXML(testContents2, rule: rule, packageTag: nil)).toNot(beNil())
                    expect(VEditorXMLBuilder.shared.buildXML(testContents3, rule: rule, packageTag: nil)).toNot(beNil())
                    expect(VEditorXMLBuilder.shared.buildXML(testContents4, rule: rule, packageTag: nil)).toNot(beNil())
                }
                
                it("should build expected xmlString") {
                    
                    expect(VEditorXMLBuilder.shared.buildXML(testContents2, rule: rule, packageTag: "content"))
                        .to(equal("<content><p>hello<b>world</b>!</p></content>"))
                    
                    expect(VEditorXMLBuilder.shared.buildXML(testContents4, rule: rule, packageTag: "content"))
                        .to(equal("<content><p>hello<b>world</b>!<b><i>boldItalicTest</i></b></p></content>"))
                    
                    expect(VEditorXMLBuilder.shared.buildXML(testContents5, rule: rule, packageTag: "content"))
                        .to(equal("<content><p>hello<b>world</b>!</p><h2>headingTest</h2><p><b><i>boldItalicTest</i></b></p></content>"))
                }
            }
        }
        
    }
}
