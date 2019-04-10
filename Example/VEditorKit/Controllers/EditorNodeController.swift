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
        static let deleteIcon = UIImage.init(named: "cancel")?.withColor(.white)
        static let defaultContentInsets: UIEdgeInsets =
            .init(top: 15.0, left: 5.0, bottom: 15.0, right: 5.0)
        static let ogObjectContainerInsets: UIEdgeInsets =
            .init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        static let placeholderTextStyle: VEditorStyle = .init([.font(UIFont.systemFont(ofSize: 16)),
                                                               .minimumLineHeight(24.0),
                                                               .color(.lightGray)])
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
        self.title = isEditMode ? "Editor": "Preview"
        self.node.delegate = self
        self.controlAreaNode.isHidden = !isEditMode
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBarButtonItem()
        self.loadXMLContent()
        self.rxAlbumAccess()
        self.rxLinkInsert()
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
    
    func placeholderCellNode(_ content: VEditorPlaceholderContent, indexPath: IndexPath) -> VEditorMediaPlaceholderNode? {
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
    
    func contentCellNode(_ content: VEditorContent, indexPath: IndexPath) -> ASCellNode? {
        switch content {
        case let text as NSAttributedString:
            let placeholderText: NSAttributedString? =
                indexPath.row == 0 ? "Insert text...".styled(with: Const.placeholderTextStyle): nil
            return VEditorTextCellNode(isEdit: isEditMode,
                                       placeholderText: placeholderText,
                                       attributedText: text,
                                       rule: self.node.editorRule,
                                       regexDelegate: self,
                                       automaticallyGenerateLinkPreview: true)
                .setContentInsets(Const.defaultContentInsets)
            
        case let imageNode as VImageContent:
            return VEditorImageNode(isEdit: isEditMode,
                                    deleteNode: .init(iconImage: Const.deleteIcon))
                .setContentInsets(Const.defaultContentInsets)
                .setTextInsertionHeight(16.0)
                .setURL(imageNode.url)
                .setMediaRatio(imageNode.ratio)
                .setPlaceholderColor(.lightGray)
                .setBackgroundColor(.lightGray)
            
        case let videoNode as VVideoContent:
            return VEditorVideoNode(isEdit: isEditMode,
                                    deleteNode: .init(iconImage: Const.deleteIcon))
                .setContentInsets(Const.defaultContentInsets)
                .setTextInsertionHeight(16.0)
                .setAssetURL(videoNode.url)
                .setPreviewURL(videoNode.posterURL)
                .setMediaRatio(videoNode.ratio)
                .setPlaceholderColor(.lightGray)
                .setBackgroundColor(.black)
            
        case let ogObjectNode as VOpenGraphContent:
            // custom media content example
            let cellNode = VEditorOpenGraphNode(isEdit: isEditMode,
                                                deleteNode: .init(iconImage: Const.deleteIcon))
                .setContentInsets(Const.ogObjectContainerInsets)
                .setContainerInsets(Const.ogObjectContainerInsets)
                .setPreviewImageURL(ogObjectNode.posterURL)
                .setPreviewImageSize(.init(width: 100.0, height: 100.0), cornerRadius: 5.0)
                .setTitleAttribute(ogObjectNode.title,
                                   attrStyle: .init([.font(UIFont.systemFont(ofSize: 16, weight: .bold)),
                                                     .minimumLineHeight(25.0),
                                                     .color(.black)]))
                .setDescAttribute(ogObjectNode.desc,
                                  attrStyle: .init([.font(UIFont.systemFont(ofSize: 13)),
                                                    .minimumLineHeight(22.0),
                                                    .color(.black)]))
                .setSourceAttribute(ogObjectNode.url,
                                    attrStyle: .init([.font(UIFont.systemFont(ofSize: 12)),
                                                      .minimumLineHeight(21.0),
                                                      .color(.gray),
                                                      .underline(.single, .gray)]))
            
            cellNode.rx.didTapDelete
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
        self.node.synchronizeFetchContents()
        guard let output = self.node.buildXML(packageTag: "content") else { return }
        let vc = XMLViewController.init(output)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func previewViewer() {
        self.node.synchronizeFetchContents()
        let xmlString = self.node.buildXML(packageTag: "content")
        let vc = EditorNodeController(isEditMode: false, xmlString: xmlString)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension EditorNodeController {
    
    private func rxLinkInsert() {
        self.controlAreaNode.linkInsertNode
            .addTarget(self,
                       action: #selector(didTapLinkInsert),
                       forControlEvents: .touchUpInside)
    }
    
    @objc private func didTapLinkInsert() {
        let vc = UIAlertController.init(title: "Link Insert", message: nil, preferredStyle: .alert)
        vc.addTextField(configurationHandler: { field in
            field.placeholder = "Link Insert..."
            return
        })
        vc.addAction(.init(title: "Confirm", style: .default, handler: { [weak self] action in
            guard let `self` = self else { return }
            
            guard let field: UITextField = vc.textFields?.first,
                let text = field.text,
                !text.isEmpty,
                let url = URL(string: text) else { return }
            
            self.node.insertLinkOnActiveTextSelectedRange(url)
            vc.dismiss(animated: true, completion: nil)
        }))
        vc.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(vc, animated: true, completion: nil)
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
        
        if let videoURL = info[.mediaURL] as? URL,
            case let asset = AVAsset.init(url: videoURL),
            let size = asset.tracks.map({ $0.naturalSize }).filter({ $0 != .zero }).first {
            
            let content = VVideoContent.init(EditorRule.XML.video.rawValue, attributes: [:])
            content.url = videoURL
            content.height = size.height
            content.width = size.width
            picker.dismiss(animated: true, completion: {
                self.node.fetchNewContent(content, scope: .automatic)
            })
            return
        }
        
        if #available(iOS 11.0, *) {
            if let imageURL = info[.imageURL] as? URL,
                let imageData = try? Data(contentsOf: imageURL, options: []),
                let image = UIImage(data: imageData) {
                let imageSize = image.size
                
                let content = VImageContent.init(EditorRule.XML.image.rawValue, attributes: [:])
                content.url = imageURL
                content.height = imageSize.height
                content.width = imageSize.width
                picker.dismiss(animated: true, completion: {
                    self.node.fetchNewContent(content, scope: .automatic)
                })
                return
            }
        } else {
            // :( i don't care
            picker.dismiss(animated: true, completion: nil)
        }
        
    }
}
