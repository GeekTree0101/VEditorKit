//
//  VEditorTypingControlNode.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit

public class VEditorTypingControlNode: ASButtonNode {
    
    public var typingStyle: VEditorStyle
    public let xmlTag: String
    public let rule: VEditorRule
    
    public init(_ xmlTag: String, rule: VEditorRule) {
        self.xmlTag = xmlTag
        self.rule = rule
        guard let typingStyle = rule.paragraphStyle(xmlTag, attributes: [:]) else {
            fatalError("\(xmlTag) doesn't have attributedStyle, Please check your Editor Rule")
        }
        self.typingStyle = typingStyle
        super.init()
    }
}
