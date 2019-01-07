//
//  EditorNodeController.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import AsyncDisplayKit
import VEditorKit
import RxCocoa
import RxSwift
import Photos
import MobileCoreServices

class EditorNodeController: ASViewController<VEditorNode> {
    
    struct Const {
        static let defaultContentInsets: UIEdgeInsets =
            .init(top: 15.0, left: 5.0, bottom: 15.0, right: 5.0)
        static let ogObjectContainerInsets: UIEdgeInsets =
            .init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    }
    let controlAreaNode: EditorControlAreaNode
    let disposeBag = DisposeBag()
    let isEditMode: Bool
    let xmlString: String?
    
    init(isEditMode: Bool = true, xmlString: String? = nil) {
        let rule = EditorRule()
        self.controlAreaNode = EditorControlAreaNode(rule: rule)
        self.isEditMode = isEditMode
        self.xmlString = xmlString
        super.init(node: .init(editorRule: rule, controlAreaNode: controlAreaNode))
        self.title = "Editor"
        self.node.delegate = self
        self.controlAreaNode.isHidden = !isEditMode
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBarButtonItem()
        self.loadXMLContent()
        self.rxAlbumAccess()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorNodeController: VEditorNodeDelegate {
    
    func getRegisterTypingControls() -> [VEditorTypingControlNode]? {
        return controlAreaNode.typingControlNodes
    }
    
    func dismissKeyboardNode() -> ASControlNode? {
        return controlAreaNode.dismissNode
    }
    
    func placeholderCellNode(_ content: VEditorPlaceholderContent) -> VEditorMediaPlaceholderNode? {
        guard let xml = EditorRule.XML.init(rawValue: content.xmlTag) else { return nil }
    
        switch xml {
        case .article:
            guard let url = content.model as? URL else { return nil }
            return EditorOpenGraphPlaceholder(xmlTag: EditorRule.XML.opengraph.rawValue,
                                              url: url)
        default:
            break
        }
        return nil
    }
    
    func contentCellNode(_ content: VEditorContent) -> ASCellNode? {
        switch content {
        case let text as NSAttributedString:
            let cellNode = VEditorTextCellNode(Const.defaultContentInsets,
                                               isEdit: isEditMode,
                                               placeholderText: nil,
                                               attributedText: text,
                                               rule: self.node.editorRule)
            cellNode.textNode.regexDelegate = self
            cellNode.textNode.automaticallyGenerateLinkPreview = true
            
            return cellNode
        case let imageNode as VImageContent:
            let cellNode = VEditorImageNode(Const.defaultContentInsets,
                                            isEdit: isEditMode,
                                            url: imageNode.url,
                                            ratio: imageNode.ratio)
            
            cellNode.rx.didTapDelete
                .map({ [weak cellNode] () -> IndexPath? in
                    return cellNode?.indexPath
                })
                .bind(to: self.node.rx.deleteContent(animated: true))
                .disposed(by: cellNode.disposeBag)
            
            return cellNode
        case let videoNode as VVideoContent:
            let cellNode = VEditorVideoNode(Const.defaultContentInsets,
                                            isEdit: isEditMode,
                                            ratio: videoNode.ratio,
                                            source: videoNode.url,
                                            poster: videoNode.posterURL)
            
            cellNode.rx.didTapDelete
                .map({ [weak cellNode] () -> IndexPath? in
                    return cellNode?.indexPath
                })
                .bind(to: self.node.rx.deleteContent(animated: true))
                .disposed(by: cellNode.disposeBag)
            
            return cellNode
        case let ogObjectNode as VOpenGraphContent:
            let cellNode = VEditorOpenGraphNode(Const.defaultContentInsets,
                                                isEdit: isEditMode,
                                                title: ogObjectNode.title,
                                                desc: ogObjectNode.desc,
                                                url: ogObjectNode.url,
                                                imageURL: ogObjectNode.posterURL,
                                                containerInsets: Const.ogObjectContainerInsets)
                .setTitleAttribute(.init([.font(UIFont.systemFont(ofSize: 16, weight: .bold)),
                                          .minimumLineHeight(25.0),
                                          .color(.black)]))
                .setDescAttribute(.init([.font(UIFont.systemFont(ofSize: 13)),
                                         .minimumLineHeight(22.0),
                                         .color(.black)]))
                .setSourceAttribute(.init([.font(UIFont.systemFont(ofSize: 12)),
                                           .minimumLineHeight(21.0),
                                           .color(.gray),
                                           .underline(.single, .gray)]))
                .setPreviewImageSize(.init(width: 100.0, height: 100.0))
            
            cellNode.rx.didTapDelete
                .map({ [weak cellNode] () -> IndexPath? in
                    return cellNode?.indexPath
                })
                .bind(to: self.node.rx.deleteContent(animated: true))
                .disposed(by: cellNode.disposeBag)
            
            return cellNode
        default:
            return nil
        }
    }
}

extension EditorNodeController: VEditorRegexApplierDelegate {
    
    enum EditorTextRegexPattern: String, CaseIterable {
        
        case userTag = "@(\\w*[0-9A-Za-z])"
        case hashTag = "#(\\w*[0-9A-Za-zㄱ-ㅎ가-힣])"
    }
    
    var allPattern: [String] {
        return EditorTextRegexPattern.allCases.map({ $0.rawValue })
    }
    
    func paragraphStyle(pattern: String) -> VEditorStyle? {
        guard let scope = EditorTextRegexPattern.init(rawValue: pattern) else { return nil }
        switch scope {
        case .userTag:
            return .init([.color(UIColor.init(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0))])
        case .hashTag:
            return .init([.color(UIColor.init(red: 0.2, green: 0.3, blue: 0.8, alpha: 1.0))])
        }
    }
    
    func handlePatternTouchEvent(_ pattern: String, value: Any) {
        guard let scope = EditorTextRegexPattern.init(rawValue: pattern) else { return }
        switch scope {
        case .userTag:
            guard let username = value as? String else { return }
            let toast = UIAlertController(title: "You did tap username: \(username)",
                message: nil,
                preferredStyle: .alert)
            toast.addAction(.init(title: "OK", style: .cancel, handler: nil))
            self.present(toast, animated: true, completion: nil)
        case .hashTag:
            guard let tag = value as? String else { return }
            let toast = UIAlertController(title: "You did tap hashTag: \(tag)",
                message: nil,
                preferredStyle: .alert)
            toast.addAction(.init(title: "OK", style: .cancel, handler: nil))
            self.present(toast, animated: true, completion: nil)
        }
    }
    
    func handlURLTouchEvent(_ url: URL) {
        UIApplication.shared.openURL(url)
    }
}

extension EditorNodeController {
    
    private func loadXMLContent() {
        if let content = self.xmlString {
            self.node.parseXMLString(content)
        } else {
            guard let path = Bundle.main.path(forResource: "content", ofType: "xml"),
                case let pathURL = URL(fileURLWithPath: path),
                let data = try? Data(contentsOf: pathURL),
                let content = String(data: data, encoding: .utf8) else { return }
            
            self.node.parseXMLString(content)
        }
    }
    
    private func setupNavigationBarButtonItem() {
        guard self.isEditMode else { return }
        let xmlBuildItem = UIBarButtonItem.init(title: "XML",
                                                style: .plain,
                                                target: self,
                                                action: #selector(pushXMLViewer))
        let previewItem = UIBarButtonItem.init(title: "Preview",
                                               style: .plain,
                                               target: self,
                                               action: #selector(previewViewer))
        self.navigationItem.rightBarButtonItems = [xmlBuildItem, previewItem]
    }
    
    @objc func pushXMLViewer() {
        self.node.synchronizeFetchContents { [weak self] () in
            
            guard let output = self?.node.buildXML(packageTag: "content") else {
                return
            }
            let vc = XMLViewController.init(output)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func previewViewer() {
        self.node.synchronizeFetchContents { [weak self] () in
            guard let xmlString = self?.node
                .buildXML(packageTag: "content") else {
                    return
            }
            let vc = EditorNodeController(isEditMode: false, xmlString: xmlString)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension EditorNodeController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private func rxAlbumAccess() {
        
        self.controlAreaNode.photoLoadControlNode
            .addTarget(self,
                       action: #selector(didTapPhotoAlbumControl),
                       forControlEvents: .touchUpInside)
        
        self.controlAreaNode.videoLoadControlNode
            .addTarget(self,
                       action: #selector(didTapVideoAlbumControl),
                       forControlEvents: .touchUpInside)
    }
    
    @objc private func didTapPhotoAlbumControl() {
        self.openAlbum(.imageOnly)
    }
    
    @objc private func didTapVideoAlbumControl() {
        self.openAlbum(.videoOnly)
    }
    
    enum MeidaScope {
        
        case imageOnly
        case videoOnly
        
        var value: String {
            switch self {
            case .imageOnly:
                return kUTTypeImage as String
            case .videoOnly:
                return kUTTypeMovie as String
            }
        }
    }
    
    private func openAlbum(_ type: MeidaScope) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = [type.value]
        imagePickerController.allowsEditing = false
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let mediaURL = info[.referenceURL] as? URL {
            print("DEBUG* \(mediaURL.absoluteString)")
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
}
