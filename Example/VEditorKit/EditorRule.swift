//
//  EditorRule.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import VEditorKit

struct EditorRule: VEditorRule {
    
    enum XML: String, CaseIterable {
        
        case article = "a"
        case paragraph = "p"
        case bold = "b"
        case italic = "i"
        case heading = "h2"
        case quote = "blockquote"
        case image = "img"
    }
    
    var defaultStyleXMLTag: String {
        return XML.paragraph.rawValue
    }
    
    var allXML: [String] {
        return XML.allCases.map({ $0.rawValue })
    }
    
    func paragraphStyle(_ xmlTag: String, attributes: [String : String]) -> VEditorStyle? {
        guard let xml = XML.init(rawValue: xmlTag) else { return nil }
        
        switch xml {
        case .paragraph:
            return .init([.font(UIFont.systemFont(ofSize: 16)),
                          .minimumLineHeight(26.0),
                          .color(.black)])
        case .bold:
            return .init([.emphasis(.bold),
                          .font(UIFont.systemFont(ofSize: 16)),
                          .minimumLineHeight(26.0),
                          .color(.black)])
        case .italic:
            return .init([.emphasis(.italic),
                          .font(UIFont.systemFont(ofSize: 16)),
                          .minimumLineHeight(26.0),
                          .color(.black)])
        case .heading:
            return .init([.font(UIFont.systemFont(ofSize: 30, weight: .medium)),
                          .minimumLineHeight(40.0),
                          .color(.black)])
        case .quote:
            return .init([.font(UIFont.systemFont(ofSize: 20)),
                          .color(.gray),
                          .firstLineHeadIndent(19.0),
                          .minimumLineHeight(30.0),
                          .headIndent(19.0)])
        case .article:
            let style: VEditorStyle = .init([.font(UIFont.systemFont(ofSize: 16)),
                                             .minimumLineHeight(26.0),
                                             .color(.black)])
            if let url = URL(string: attributes["href"] ?? "") {
                return style.byAdding([.underline(.single, .black), .link(url)])
            } else {
                return style
            }
        
        default:
            return nil
        }
    }
    
    func build(_ xmlTag: String, attributes: [String : String]) -> VEdiorMediaContent? {
        guard let xml = XML.init(rawValue: xmlTag) else { return nil }
        
        switch xml {
        case .image:
            return VImageContent(xmlTag, attributes: attributes)
        default:
            return nil
        }
    }
    
    func parseAttributeToXML(_ xmlTag: String,
                             attributes: [NSAttributedString.Key : Any]) -> [String : String]? {
        guard let xml = XML.init(rawValue: xmlTag) else { return nil }
        
        switch xml {
        case .article:
            if let url = attributes[.link] as? URL,
                case let urlString = url.absoluteString {
                return ["href": urlString]
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    func enableTypingXMLs(_ inActiveXML: String) -> [String]? {
        guard let xml = XML.init(rawValue: inActiveXML) else { return nil }
        
        switch xml {
        case .heading, .quote:
            return [XML.bold.rawValue,
                    XML.italic.rawValue,
                    XML.paragraph.rawValue]
        default:
            return nil
        }
    }
    
    func disableTypingXMLs(_ activeXML: String) -> [String]? {
        guard let xml = XML.init(rawValue: activeXML) else { return nil }
        
        switch xml {
        case .heading, .quote:
            return [XML.bold.rawValue,
                    XML.italic.rawValue,
                    XML.paragraph.rawValue]
        default:
            return nil
        }
    }
    
    func inactiveTypingXMLs(_ activeXML: String) -> [String]? {
        guard let xml = XML.init(rawValue: activeXML) else { return nil }
        
        switch xml {
        case .heading:
            return [XML.quote.rawValue]
        case .quote:
            return [XML.heading.rawValue]
        default:
            return nil
        }
    }
    
    func activeTypingXMLs(_ inactiveXML: String) -> [String]? {
        return nil
    }
    
}

class VImageContent: VEdiorMediaContent {
    
    var xmlTag: String
    
    var url: URL?
    var width: CGFloat
    var height: CGFloat
    
    var ratio: CGFloat {
        return height / width
    }
    
    required init(_ xmlTag: String, attributes: [String : String]) {
        self.xmlTag = xmlTag
        self.url = URL(string: attributes["src"] ?? "")
        self.width = CGFloat(Int(attributes["width"] ?? "") ?? 1)
        self.height = CGFloat(Int(attributes["height"] ?? "") ?? 1)
    }
    
    func parseAttributeToXML() -> [String : String] {
        return ["src": url?.absoluteString ?? "",
                "width": "\(Int(width))",
                "height": "\(Int(height))"]
    }
}
