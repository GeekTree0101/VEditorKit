//
//  Platform.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import BonMot
import RxSwift
import AsyncDisplayKit

public typealias VEditorStyleAttribute = BonMot.StyleAttributes
public typealias VEditorStyle = BonMot.StringStyle

// MARK: - VEditor Parser Scope
public enum VEditorParserResultScope {
    
    case error(Error?)
    case success([VEditorContent])
}

// MARK: - VEditor Unit Content

extension NSAttributedString: VEditorContent { }

public let VEditorAttributeKey: NSAttributedString.Key = .init(rawValue: "VEditorKit.AttributeKey")

public protocol VEditorMediaContent: VEditorContent {
    
    var xmlTag: String { get }
    init(_ xmlTag: String, attributes: [String: String])
    func parseAttributeToXML() -> [String: String] // parseto xml attribute from media content
}

public struct VEditorPlaceholderContent: VEditorContent {
    public var xmlTag: String
    public var model: Any
    
    public init(xmlTag: String, model: Any) {
        self.xmlTag = xmlTag
        self.model = model
    }
}

// MARK: - VEditorKit Editor Rule
public protocol VEditorRule {
    
    var allXML: [String] { get }
    var defaultStyleXMLTag: String { get }
    var linkStyleXMLTag: String? { get }
    func paragraphStyle(_ xmlTag: String, attributes: [String: String]) -> VEditorStyle?
    func build(_ xmlTag: String, attributes: [String: String]) -> VEditorMediaContent?
    func parseAttributeToXML(_ xmlTag: String, attributes: [NSAttributedString.Key: Any]) -> [String: String]?
    
    func enableTypingXMLs(_ inActiveXML: String) -> [String]?
    func disableTypingXMLs(_ activeXML: String) -> [String]?
    func inactiveTypingXMLs(_ activeXML: String) -> [String]?
    func activeTypingXMLs(_ inactiveXML: String) -> [String]?
}

extension VEditorRule {
    
    public func defaultAttribute() -> [NSAttributedString.Key: Any] {
        guard let attr = self.paragraphStyle(self.defaultStyleXMLTag, attributes: [:]) else {
            fatalError("Please setup default:\(self.defaultStyleXMLTag) xml tag style")
        }
        return attr.byAdding([.extraAttributes([VEditorAttributeKey: [self.defaultStyleXMLTag]])]).attributes
    }
    
    public func linkAttribute(_ url: URL) -> [NSAttributedString.Key: Any]? {
        guard let xml = self.linkStyleXMLTag,
            let attr = self.paragraphStyle(xml, attributes: [:]) else { return nil }
        return attr.byAdding([.link(url), .extraAttributes([VEditorAttributeKey: [xml]])]).attributes
    }
}

// MARK: VEditotKit EditorNodeDelegate
public protocol VEditorNodeDelegate: class {
    
    func getRegisterTypingControls() -> [VEditorTypingControlNode]?
    func dismissKeyboardNode() -> ASControlNode?
    func placeholderCellNode(_ content: VEditorPlaceholderContent,
                             indexPath: IndexPath) -> VEditorMediaPlaceholderNode?
    func contentCellNode(_ content: VEditorContent,
                         indexPath: IndexPath) -> ASCellNode?
}

// MARK: - VEditor Regex Text Atttribute Apply Delegate
public protocol VEditorRegexApplierDelegate: class {
    
    var allPattern: [String] { get }
    func paragraphStyle(pattern: String) -> VEditorStyle?
    func handlePatternTouchEvent(_ pattern: String, value: Any)
    func handlURLTouchEvent(_ url: URL)
}

extension VEditorRegexApplierDelegate {
    
    func regex(_ pattern: String) -> NSRegularExpression {
        guard let reg = try? NSRegularExpression.init(pattern: pattern, options: []) else {
            fatalError("VEditorKit Fatal Error: \(pattern) is invalid regex pattern")
        }
        return reg
    }
}
