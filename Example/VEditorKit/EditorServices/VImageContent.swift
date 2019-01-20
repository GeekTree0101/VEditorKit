//
//  VImageContent.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import VEditorKit

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
