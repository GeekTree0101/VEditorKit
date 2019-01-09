//
//  VEditorTypingControlNodeSpec.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Quick
import Nimble
import RxTest
import RxBlocking
import VEditorKit

class VEditorTypingControlNodeSpec: QuickSpec {

    override func spec() {
        
        describe("VEditor Typing ControlNode Test") {
            
            var node: VEditorTypingControlNode!
            var touchableAttributeNode: VEditorTypingControlNode!
            var blockAttributeNode: VEditorTypingControlNode!
            
            context("intialization test") {
                
                beforeEach {
                    node = VEditorTypingControlNode.init("p", rule: EditorRule())
                    touchableAttributeNode = VEditorTypingControlNode
                        .init("a", rule: EditorRule(), isExternalHandler: true)
                    blockAttributeNode = VEditorTypingControlNode
                        .init("h2", rule: EditorRule(), isBlockStyle: true)
                }
                
                it("should be success") {
                    expect(node.xmlTag).to(equal("p"))
                    expect(node.typingStyle).toNot(beNil())
                    expect(node.isBlockStyle).to(beFalse())
                    expect(node.isExternalHandler).to(beFalse())
                }
                
                it("should be success touchable attribute control node") {
                    expect(touchableAttributeNode.isBlockStyle).to(beFalse())
                    expect(touchableAttributeNode.isExternalHandler).to(beTrue())
                }
                
                it("should be success block attribute control node") {
                    expect(blockAttributeNode.isBlockStyle).to(beTrue())
                    expect(blockAttributeNode.isExternalHandler).to(beFalse())
                }
            }
        }
    }
}
