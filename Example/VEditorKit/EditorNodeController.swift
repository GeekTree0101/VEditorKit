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
    }
    let controlAreaNode: EditorControlAreaNode
    let disposeBag = DisposeBag()
    
    init() {
        let rule = EditorRule()
        self.controlAreaNode = EditorControlAreaNode(rule: rule)
        super.init(node: .init(editorRule: rule, controlAreaNode: controlAreaNode))
        self.title = "Editor"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupEditorNode()
        self.setupNavigationBarButtonItem()
        self.loadXMLContent()
        self.rxAlbumAccess()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorNodeController {
    
    func setupEditorNode() {
        
        self.node
            .registerTypingContols(controlAreaNode.typingControlNodes)
            .observeKeyboardEvent(controlAreaNode.dismissNode)
        
        self.node.editorContentFactory = { [weak self] content -> ASCellNode? in
            guard let `self` = self else { return ASCellNode() }
            
            switch content {
            case let text as NSAttributedString:
                let node = VEditorTextCellNode(Const.defaultContentInsets,
                                               isEdit: true,
                                               placeholderText: nil,
                                               attributedText: text,
                                               rule: self.node.editorRule)
                
                return node
            case let imageNode as VImageContent:
                return VEditorImageNode(Const.defaultContentInsets,
                                        isEdit: true,
                                        url: imageNode.url,
                                        ratio: imageNode.ratio)
            default:
                return nil
            }
        }
    }
}

extension EditorNodeController {
    
    private func loadXMLContent() {
        
        guard let path = Bundle.main.path(forResource: "content", ofType: "xml"),
            case let pathURL = URL(fileURLWithPath: path),
            let data = try? Data(contentsOf: pathURL),
            let content = String(data: data, encoding: .utf8) else { return }
        
        self.node.parseXMLString(content)
    }
    
    private func setupNavigationBarButtonItem() {
        self.navigationItem.rightBarButtonItem =
            UIBarButtonItem.init(title: "Build",
                                 style: .plain,
                                 target: self,
                                 action: #selector(pushXMLViewer))
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
