//
//  Platform.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import BonMot

public typealias VEditorStyleAttribute = BonMot.StyleAttributes
public typealias VEditorStyle = BonMot.StringStyle

public enum VEditorParserResultScope {
    case error(Error?)
    case success([VEditorContent])
}

extension NSAttributedString: VEditorContent { }
public protocol VEdiorMediaContent: VEditorContent {
    init(_ attributes: [String: String])
}

public protocol VEditorParserRule {
    var allXML: [String] { get }
    func paragraph(_ xmlTag: String, attributes: [String: String]) -> VEditorStyle?
    func build(_ xmlTag: String, attributes: [String: String]) -> VEdiorMediaContent?
}
