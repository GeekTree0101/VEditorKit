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
                
                beforeEach {
                    var pTagStyle = EditorRule.init().paragraphStyle("p", attributes: [:])
                    pTagStyle?.add(extraAttributes: [VEditorAttributeKey: ["p"]])
                    var bTagStyle = EditorRule.init().paragraphStyle("b", attributes: [:])
                    bTagStyle?.add(extraAttributes: [VEditorAttributeKey: ["b"]])
                    let textNode = NSMutableAttributedString.init()
                    textNode.append("hello".styled(with: pTagStyle!))
                    textNode.append("world".styled(with: bTagStyle!))
                    textNode.append("!".styled(with: pTagStyle!))
                    
                    let imageNode = VImageContent.init("img", attributes: ["src": "https://test.jpg", "width": "540", "height": "810"])
                    
                    testContents = [imageNode]
                    testContents2 = [textNode]
                    testContents3 = [textNode, imageNode]
                }
                
                it("should be build to xmlString") {
                    expect(VEditorXMLBuilder.shared.buildXML(testContents, rule: rule, packageTag: "content")).toNot(beNil())
                    expect(VEditorXMLBuilder.shared.buildXML(testContents2, rule: rule, packageTag: "content")).toNot(beNil())
                    expect(VEditorXMLBuilder.shared.buildXML(testContents3, rule: rule, packageTag: "content")).toNot(beNil())
                }
            }
        }
        
    }
}
