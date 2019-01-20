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
        case video = "video"
        case opengraph = "og-object"
    }
    
    var defaultStyleXMLTag: String {
        return XML.paragraph.rawValue
    }
    
    var linkStyleXMLTag: String? {
        return XML.article.rawValue
    }
    
    var blockStyleXMLTags: [String] {
        return [XML.heading, XML.quote].map({ $0.rawValue })
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
                                             .color(.black),
                                             .underline(.single, .black)])
            if let url = URL(string: attributes["href"] ?? "") {
                return style.byAdding([.link(url)])
            } else {
                return style
            }
        
        default:
            return nil
        }
    }
    
    func build(_ xmlTag: String, attributes: [String : String]) -> VEditorMediaContent? {
        guard let xml = XML.init(rawValue: xmlTag) else { return nil }
        
        switch xml {
        case .image:
            return VImageContent(xmlTag, attributes: attributes)
        case .video:
            return VVideoContent(xmlTag, attributes: attributes)
        case .opengraph:
            return VOpenGraphContent(xmlTag, attributes: attributes)
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

class VImageContent: VEditorMediaContent {
    
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

class VVideoContent: VEditorMediaContent {
    
    var xmlTag: String
    
    var url: URL?
    var posterURL: URL?
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
        self.posterURL = URL(string: attributes["poster"] ?? "")
    }
    
    func parseAttributeToXML() -> [String : String] {
        return ["src": url?.absoluteString ?? "",
                "poster": posterURL?.absoluteString ?? "",
                "width": "\(Int(width))",
                "height": "\(Int(height))"]
    }
}

class VOpenGraphContent: VEditorMediaContent {
    
    var xmlTag: String
    
    var title: String?
    var desc: String?
    var url: URL?
    var posterURL: URL?
    
    required init(_ xmlTag: String, attributes: [String : String]) {
        self.xmlTag = xmlTag
        self.title = attributes["title"]
        self.desc = attributes["description"]
        self.url = URL(string: attributes["url"] ?? "")
        self.posterURL = URL(string: attributes["image"] ?? "")
    }
    
    func parseAttributeToXML() -> [String : String] {
        return ["title": self.title ?? "",
                "desc": self.desc ?? "",
                "url": url?.absoluteString ?? "",
                "image": posterURL?.absoluteString ?? ""]
    }
}
