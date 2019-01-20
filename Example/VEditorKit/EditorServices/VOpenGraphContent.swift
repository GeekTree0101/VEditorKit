//
//  VOpenGraphContent.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import VEditorKit

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
