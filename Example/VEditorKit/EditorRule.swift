//
//  EditorRule.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import VEditorKit

struct EditorRule: VEditorParserRule {
    
    enum XML: String, CaseIterable {
        
        case a
        case p
        case b
        case i
        case img
    }
    
    var allXML: [String] {
        return XML.allCases.map({ $0.rawValue })
    }
    
    func paragraph(_ xmlTag: String, attributes: [String : String]) -> VEditorStyle? {
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
            return VImageContent(attributes)
        default:
            return nil
        }
    }
}

class VImageContent: VEdiorMediaContent {
    
    var url: URL?
    var ratio: CGFloat = 0.0
    
    required init(_ attributes: [String : String]) {
        self.url = URL(string: attributes["src"] ?? "")
        let width = CGFloat(Int(attributes["width"] ?? "") ?? 1)
        let height = CGFloat(Int(attributes["height"] ?? "") ?? 1)
        self.ratio = height / width
    }
}
