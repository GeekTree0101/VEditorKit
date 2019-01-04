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
        
        case a
        case p
        case b
        case i
        case img
    }
    
    var defaultStyleXMLTag: String {
        return XML.p.rawValue
    }
    
    var allXML: [String] {
        return XML.allCases.map({ $0.rawValue })
    }
    
    func paragraphStyle(_ xmlTag: String, attributes: [String : String]) -> VEditorStyle? {
        guard let xml = XML.init(rawValue: xmlTag) else { return nil }
        
        switch xml {
        case .p:
            return .init([.font(UIFont.systemFont(ofSize: 15)),
                          .color(.black)])
        case .b:
            return .init([.emphasis(.bold),
                          .font(UIFont.systemFont(ofSize: 15)),
                          .color(.black)])
        case .i:
            return .init([.emphasis(.italic),
                          .font(UIFont.systemFont(ofSize: 15)),
                          .color(.black)])
        case .a:
            let style: VEditorStyle = .init([.font(UIFont.systemFont(ofSize: 15)),
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
        case .img:
            return VImageContent(xmlTag, attributes: attributes)
        default:
            return nil
        }
    }
    
    func parseAttributeToXML(_ xmlTag: String,
                             attributes: [NSAttributedString.Key : Any]) -> [String : String]? {
        guard let xml = XML.init(rawValue: xmlTag) else { return nil }
        
        switch xml {
        case .a:
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
