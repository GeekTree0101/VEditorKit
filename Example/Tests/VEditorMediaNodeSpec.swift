//
//  VEditorMeidaNodeSpec.swift
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

class VEditorMediaNodeSpec: QuickSpec {
    
    override func spec() {
        
        describe("VEditorImageNode Unit Test") {
            
            
            context("intialization test") {
                
                var node: VEditorMediaNode<ASVideoNode>!
                var node2: VEditorMediaNode<ASNetworkImageNode>!
                
                beforeEach {
                    node = VEditorMediaNode.init(node: ASVideoNode(), isEdit: true)
                    node2 = VEditorMediaNode.init(node: ASNetworkImageNode(), isEdit: true)
                }
                
                it("should be success") {
                    expect(node.node).to(beAKindOf(ASVideoNode.self))
                    expect(node2.node).to(beAKindOf(ASNetworkImageNode.self))
                    
                    expect(node.isEdit).to(beTrue())
                    expect(node.insets).to(equal(.zero))
                    expect(node.ratio).to(equal(1.0))
                    expect(node.automaticallyManagesSubnodes).to(beTrue())
                    expect(node.selectionStyle == .none).to(beTrue())
                }
            }
            
            context("update property test") {
                
                var node: VEditorMediaNode<ASVideoNode>!
                
                beforeEach {
                    node = VEditorMediaNode.init(node: ASVideoNode(), isEdit: true)
                }
                
                it("should be update ratio") {
                    expect(node.ratio).to(equal(1.0))
                    node.setMediaRatio(0.5)
                    expect(node.ratio).to(equal(0.5))
                }
                
                it("should be update insets") {
                    expect(node.insets).to(equal(.zero))
                    node.setContentInsets(.init(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0))
                    expect(node.insets)
                        .to(equal(.init(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)))
                }
                
                it("should be update text insertion touch area height") {
                    expect(node.textInsertionNode.style.height.value).to(equal(5.0))
                    node.setTextInsertionHeight(50.0)
                    expect(node.textInsertionNode.style.height.value).to(equal(50.0))
                }
            }
            
            context("media tap event test") {
                
                var node: VEditorMediaNode<ASVideoNode>!
                var viewOnlyNode: VEditorMediaNode<ASVideoNode>!
                
                beforeEach {
                    node = VEditorMediaNode.init(node: ASVideoNode(), isEdit: true)
                    viewOnlyNode = VEditorMediaNode.init(node: ASVideoNode(), isEdit: false)
                    node.didLoad()
                    viewOnlyNode.didLoad()
                }
                
                it("should be control isHidden status about delete frame") {
                    expect(node.deleteControlNode.isHidden).to(beTrue())
                    node.deleteControlNode.sendActions(forControlEvents: .touchUpInside, with: nil)
                    expect(node.deleteControlNode.isHidden).to(beFalse())
                    node.node.sendActions(forControlEvents: .touchUpInside, with: nil)
                    expect(node.deleteControlNode.isHidden).to(beTrue())
                }
                
                it("shouldn't be control isHidden status about delete frame") {
                    expect(viewOnlyNode.deleteControlNode.isHidden).to(beTrue())
                    viewOnlyNode.deleteControlNode.sendActions(forControlEvents: .touchUpInside, with: nil)
                    expect(viewOnlyNode.deleteControlNode.isHidden).to(beTrue())
                    viewOnlyNode.node.sendActions(forControlEvents: .touchUpInside, with: nil)
                    expect(viewOnlyNode.deleteControlNode.isHidden).to(beTrue())
                }
            }
        }
    }
}
