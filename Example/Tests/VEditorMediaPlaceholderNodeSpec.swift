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
