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
    public var encodingHTMLEntitiesExternalHandler: ((String) -> String)?
    
    public func buildXML(_ contents: [VEditorContent],
                         rule: VEditorRule,
                         packageTag: String?) -> String? {
        
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
        
        for xml in rule.allXML {
            let open = self.generateXMLTag(xml, scope: .open(nil))
            let close = self.generateXMLTag(xml, scope: .close)
            let emptyContent = open + close
            let duplicatedPairedXMLTags = close + open
            xmlString = xmlString
                .replacingOccurrences(of: emptyContent, with: "")
                .replacingOccurrences(of: duplicatedPairedXMLTags, with: "")
        }
        
        if xmlString.isEmpty {
            return nil
        } else if let packageTag = packageTag {
            return self.packageXML(packageTag, content: xmlString)
        } else {
            return xmlString
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
        
        xmlString += self.generateXMLTag(rule.defaultStyleXMLTag, scope: .open(nil))
        
        attrText
            .enumerateAttributes(in: range,
                                 options: [],
                                 using: { attributes, subRange, _ in
                                    
                                    var content = attrText.attributedSubstring(from: subRange).string
                                    content = content.encodingHTMLEntities()
                                    
                                    guard !content.isEmpty else { return }
                                    
                                    guard let tags = (attributes[VEditorAttributeKey] as? [String])?
                                        .filter({ $0 != rule.defaultStyleXMLTag }) else {
                                            xmlString += content
                                            return
                                    }
                                    
                                    let isBlockStyle: Bool = tags.contains(where: { rule.blockStyleXMLTags.contains($0) })
                                    
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
                                    
                                    let inlineXMLString: String = [openTag, content, closeTag].joined()
                                    
                                    if isBlockStyle {
                                        xmlString += [self.generateXMLTag(rule.defaultStyleXMLTag, scope: .close),
                                                      inlineXMLString,
                                                      self.generateXMLTag(rule.defaultStyleXMLTag, scope: .open(nil))].joined()
                                    } else {
                                        xmlString += inlineXMLString
                                    }
            })
        
        
        xmlString += self.generateXMLTag(rule.defaultStyleXMLTag, scope: .close)
        
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
    
    internal func encodingHTMLEntities() -> String {
        guard let handler = VEditorXMLBuilder.shared.encodingHTMLEntitiesExternalHandler else {
            // NOTE: default encoding HTML Entities for VEditor
            // ref: https://dev.w3.org/html5/html-author/charref
            return self.replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&#x27;")
                .replacingOccurrences(of: "'", with: "&#x39;")
                .replacingOccurrences(of: "'", with: "&#x92;")
                .replacingOccurrences(of: "'", with: "&#x96;")
        }
        
        return handler(self)
    }
    
    internal func convertDuplicatedBackSlashToValidParserXML() -> String {
        return self.replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\", with: "")
    }
}
