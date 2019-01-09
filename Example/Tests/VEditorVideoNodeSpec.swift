import Quick
import Nimble
import RxTest
import AsyncDisplayKit
import RxBlocking
import VEditorKit

class VEditorVideoNodeSpec: QuickSpec {
    
    override func spec() {
        
        describe("VEditorVideoNode Unit Test") {
            
            var node: VEditorVideoNode!
            
            context("intialization test") {
                
                beforeEach {
                    node = VEditorVideoNode.init(isEdit: true)
                }
                
                it("should be success") {
                    expect(node.node).to(beAKindOf(ASVideoNode.self))
                    expect(node.automaticallyManagesSubnodes).to(beTrue())
                    expect(node.isEdit).to(beTrue())
                }
            }
            
            context("update property test") {
                
                beforeEach {
                    node = VEditorVideoNode.init(isEdit: true)
                }
                
                it("should be update previewImageURL") {
                    expect(node.node.url).to(beNil())
                    node.setPreviewURL(URL(string: "https://raw.githubusercontent.com/GeekTree0101/VEditorKit/master/screenshots/intro.png"))
                    expect(node.node.url).toNot(beNil())
                }
                
                it("should be update assetURL") {
                    expect(node.node.asset).to(beNil())
                    expect(node.node.assetURL).to(beNil())
                    node.setAssetURL(URL(string: "https://raw.githubusercontent.com/GeekTree0101/VEditorKit/master/screenshots/test2.mp4"))
                    expect(node.assetURL).toNot(beNil())
                    expect(node.videoAsset).toNot(beNil())
                    expect(node.node.asset).to(beNil())
                    expect(node.node.assetURL).to(beNil())
                    node.didLoad()
                    expect(node.node.asset).toNot(beNil())
                    expect(node.node.assetURL).toNot(beNil())
                }
            }
        }
    }
}
