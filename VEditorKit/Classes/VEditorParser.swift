//
//  VEditorParser.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import BonMot
import RxSwift
import RxCocoa

public protocol VEditorContent { }
extension String: VEditorContent { }

public extension Reactive where Base: VEditorParser {
    
    public var result: Observable<VEditorParserResultScope> {
        return base.resultRelay.asObservable()
    }
}

public class VEditorParser: NSObject, XMLStyler {
    
    private let parserRule: VEditorRule
    private let styleRules: [XMLStyleRule]
    public let resultRelay = PublishRelay<VEditorParserResultScope>()
    
    public init(rule: VEditorRule) {
        self.parserRule = rule
        self.styleRules = rule.allXML.map({ xmlTag -> XMLStyleRule in
            return XMLStyleRule.style(xmlTag, StringStyle.init())
        })
        super.init()
    }
    
    public func parseXML(_ xmlString: String,
                         onSuccess: (([VEditorContent]) -> Void)? = nil,
                         onError: ((Error?) -> Void)? = nil) {
        let parser = VEditorContentParser(xmlString
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\", with: ""), rule: self.parserRule)
        
        switch parser.parseXMLContents() {
        case .success(let contents):
            let styleAppliedContents = contents
                .map({ content -> VEditorContent in
                    if let xmlContent = content as? String {
                        return xmlContent.styled(with: StringStyle(.xmlStyler(self)))
                    } else {
                        return content
                    }
                })
            onSuccess?(styleAppliedContents)
            resultRelay.accept(.success(styleAppliedContents))
        case .error(let error):
            onError?(error)
            resultRelay.accept(.error(error))
        }
    }
    
    public func style(forElement name: String,
                      attributes: [String : String],
                      currentStyle: StringStyle) -> StringStyle? {
        for rule in styleRules {
            switch rule {
            case let .style(string, style) where string == name:
                var mutableStyle: StringStyle
                if let paragraphStyle = parserRule.paragraphStyle(name, attributes: attributes) {
                    mutableStyle = paragraphStyle
                } else {
                    mutableStyle = style
                }
                
                // *** Merge topStyle cached xmlTags list with current xmlTag ***
                if let cachedXmlTags = currentStyle.attributes[VEditorAttributeKey] as? [String],
                    cachedXmlTags.contains(name) {
                    mutableStyle.add(extraAttributes: [VEditorAttributeKey: [name] + cachedXmlTags])
                } else {
                    mutableStyle.add(extraAttributes: [VEditorAttributeKey: [name]])
                }
                
                return mutableStyle

            default:
                break
            }
        }
        for rule in styleRules {
            if case let .styles(namedStyles) = rule {
                return namedStyles.style(forName: name)
            }
        }
        return nil
    }
    
    public func prefix(forElement name: String,
                       attributes: [String: String]) -> Composable? {
        for rule in styleRules {
            switch rule {
            case let .enter(string, composable) where string == name:
                return composable
            default: break
            }
        }
        return nil
    }
    
    public func suffix(forElement name: String) -> Composable? {
        for rule in styleRules {
            switch rule {
            case let .exit(string, composable) where string == name:
                return composable
            default: break
            }
        }
        return nil
    }
}

/**
 Editor Content Parser
 
 General pattern would be:
 xml: <content><p>hello <b>world</b></p><img src="~~~~" /><p>done></p></content>
 will convert to
 - [0]: <p>hello <b>world</b></p>
 - [1]: VEdiorMediaContent
 - [2]: <p>done></p>
 */
internal class VEditorContentParser: NSObject, XMLParserDelegate {
    
    private let parser: XMLParser
    private let parserRule: VEditorRule
    private var contents: [VEditorContent] = []
    
    init(_ xmlString: String,
         rule: VEditorRule) {
        guard let data = xmlString.data(using: .utf8) else {
            fatalError("Failed to convert data from string as utf8")
        }
        self.parser = XMLParser.init(data: data)
        self.parserRule = rule
        super.init()
        self.parser.delegate = self
        self.parser.shouldProcessNamespaces = false
        self.parser.shouldReportNamespacePrefixes = false
        self.parser.shouldResolveExternalEntities = false
    }
    
    func parseXMLContents() -> VEditorParserResultScope {
        guard parser.parse() else {
            return .error(parser.parserError)
        }
        return .success(contents)
    }
    
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        if parserRule.paragraphStyle(elementName, attributes: attributeDict) != nil {
            self.contents.append("<\(elementName) \(attributeDict.xmlAttributeToString())>")
        } else if let build = parserRule.build(elementName, attributes: attributeDict) {
            self.contents.append(build)
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if self.contents.last is String {
            self.contents.append(string)
        }
    }
    
    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        if parserRule.paragraphStyle(elementName, attributes: [:]) != nil {
            self.contents.append("</\(elementName)>")
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        self.contents = contents.reduce([], { result, item -> [VEditorContent] in
            var result: [VEditorContent] = result
            if result.last is String,
                let strItem = item as? String {
                result.append(((result.removeLast() as? String) ?? "") + strItem)
            } else {
                result.append(item)
            }
            return result
        })
    }
}

extension Dictionary where Key == String, Value == String {
    
    internal func xmlAttributeToString() -> String {
        var attributes: [String] = []
        self.enumerated().forEach({ _, context in
            let (key, value) = context
            attributes.append("\(key)=\"\(value)\"")
        })
        return attributes.joined(separator: " ")
    }
}
