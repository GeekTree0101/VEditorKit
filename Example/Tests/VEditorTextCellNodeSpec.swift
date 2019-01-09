//
//  VEditorTextCellNodeSpec.swift
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

class VEditorTextCellNodeSpec: QuickSpec {

    override func spec() {
        
        describe("VEditor TextCellNode Unit Test") {
            
            var node: VEditorTextCellNode!
            
            context("intialization test") {
                
                beforeEach {
                    node = VEditorTextCellNode(isEdit: true,
                                               placeholderText: nil,
                                               attributedText: .init(string: "test"),
                                               rule: EditorRule())
                }
                
                it("should be success") {
                    expect(node.isEdit).to(beTrue())
                    expect(node.textNode).to(beAKindOf(VEditorTextNode.self))
                    expect(node.automaticallyManagesSubnodes).to(beTrue())
                    expect(node.insets).to(equal(.zero))
                }
            }
            
            context("update layout test") {
                
                beforeEach {
                    node = VEditorTextCellNode(isEdit: true,
                                               placeholderText: nil,
                                               attributedText: .init(string: "test"),
                                               rule: EditorRule())
                }
                
                it("should be set default(zero) insets") {
                    expect(node.insets).to(equal(.zero))
                }
                
                it("should be update insets") {
                    node.setContentInsets(.init(top: 50, left: 50, bottom: 50, right: 50))
                    expect(node.insets).to(equal(.init(top: 50, left: 50, bottom: 50, right: 50)))
                }
            }
        }
    }
}
