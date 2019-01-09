//
//  VEditorMediaPlaceholderNodeSpce.swift
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

class VEditorMediaPlaceholderNodeSpec: QuickSpec {
    
    override func spec() {
        
        describe("VEditorPlaceholderNode Unit Test") {
            
            var node: VEditorMediaPlaceholderNode!
            
            context("Intialization test") {
                
                beforeEach {
                    node = VEditorMediaPlaceholderNode.init(xmlTag: "a")
                }
                
                it("should be success") {
                    expect(node.xmlTag).to(equal("a"))
                    expect(node.automaticallyManagesSubnodes).to(beTrue())
                    expect(node.selectionStyle == .none).to(beTrue())
                }
            }
        }
    }
}
