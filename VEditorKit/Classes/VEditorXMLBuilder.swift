//
//  VEditorXMLBuilder.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import BonMot

public final class VEditorXMLBuilder {
    
    public static let shared: VEditorXMLBuilder = .init()
    
    public func buildXML(_ contents: [VEditorContent],
                         rule: VEditorRule,
                         packageTag: String) -> String? {
        
        var xmlString: String = ""
        
        for content in contents {
            switch content {
            case let mediaContent as VEditorMediaContent:
                let tag = mediaContent.xmlTag
                let attributes = mediaContent.parseAttributeToXML()
                xmlString += self.generateXMLTag(tag, scope: .selfClosing(attributes))
            case let attributedText as NSAttributedString:
                xmlString += self.parseAttributedStringToXML(attributedText, rule: rule)
            default:
                break
            }
        }
        
        xmlString = xmlString.squeezXMLString(rule)
        if xmlString.isEmpty {
            return nil
        } else {
            return self.packageXML(packageTag,
                                   content: xmlString)
        }
    }
    
    enum PackgingScope {
        
        case selfClosing([String: String])
        case open([String: String]?)
        case close
    }
    
    private func parseAttributedStringToXML(_ attrText: NSAttributedString,
                                            rule: VEditorRule) -> String {
        var xmlString: String = ""
        let range = NSRange(location: 0, length: attrText.length)
        
        attrText
            .enumerateAttributes(in: range,
                                 options: [],
                                 using: { attributes, subRange, _ in
                                    
                                    var content = attrText.attributedSubstring(from: subRange).string
                                    content = content
                                        .replacingOccurrences(of: "\"", with: "\\")
                                    
                                    let tags = (attributes[VEditorAttributeKey] as? [String])
                                        ?? [rule.defaultStyleXMLTag]
                                    
                                    guard !content.isEmpty else { return }
                                    
                                    
                                    let openTag = tags
                                        .map({ tag -> String in
                                            let attrs =
                                                rule.parseAttributeToXML(tag,
                                                                         attributes: attributes)
                                            return generateXMLTag(tag, scope: .open(attrs))
                                        }).joined()
                                    
                                    let closeTag = tags
                                        .reversed()
                                        .map({ tag -> String in
                                            return generateXMLTag(tag, scope: .close)
                                        }).joined()
                                    
                                    xmlString += [openTag, content, closeTag].joined()
            })
        
        return xmlString
    }
    
    private func generateXMLTag(_ xmlTag: String, scope: PackgingScope) -> String {
        
        switch scope {
        case .selfClosing(let attrs):
            return "<\(xmlTag) \(attrs.xmlAttributeToString()) />"
        case .open(let attrs):
            if let attrs = attrs, !attrs.isEmpty {
                return "<\(xmlTag) \(attrs.xmlAttributeToString())>"
            } else {
                return "<\(xmlTag)>"
            }
        case .close:
            return "</\(xmlTag)>"
        }
    }
    
    private func packageXML(_ xmlTag: String, content: String) -> String {
        return ["<\(xmlTag)>", content, "</\(xmlTag)>"].joined()
    }
}

extension String {
    
    internal func squeezXMLString(_ rule: VEditorRule) -> String {
        var xmlString: String = self
        let squeezTargetTags: [String] = rule.allXML.map({ "</\($0)><\($0)>" })
        for targetTag in squeezTargetTags {
            xmlString = xmlString.replacingOccurrences(of: targetTag, with: "")
        }
        return xmlString
    }
}
