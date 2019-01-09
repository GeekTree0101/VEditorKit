import Quick
import Nimble
import RxTest
import AsyncDisplayKit
import RxBlocking
import VEditorKit

class VEditorImageNodeSpec: QuickSpec {
    
    override func spec() {
        
        describe("VEditorImageNode Unit Test") {
            
            var node: VEditorImageNode!
            
            context("intialization test") {
                
                beforeEach {
                    node = VEditorImageNode.init(isEdit: true)
                }
                
                it("should be success") {
                    expect(node.node).to(beAKindOf(ASNetworkImageNode.self))
                    expect(node.automaticallyManagesSubnodes).to(beTrue())
                    expect(node.isEdit).to(beTrue())
                }
            }
            
            context("update property test") {
                
                beforeEach {
                    node = VEditorImageNode.init(isEdit: true)
                }
                
                it("should be update previewImageURL") {
                    expect(node.node.url).to(beNil())
                    node.setURL(URL(string: "https://raw.githubusercontent.com/GeekTree0101/VEditorKit/master/screenshots/intro.png"))
                    expect(node.node.url).toNot(beNil())
                }
            }
        }
    }
}
