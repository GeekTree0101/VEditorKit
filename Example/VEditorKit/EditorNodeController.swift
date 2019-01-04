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

class EditorNodeController: ASViewController<VEditorNode> {
    
    struct Const {
        static let defaultContentInsets: UIEdgeInsets =
            .init(top: 15.0, left: 5.0, bottom: 15.0, right: 5.0)
    }
    let controlAreaNode: EditorControlAreaNode = .init()
    let disposeBag = DisposeBag()
    
    init() {
        super.init(node: .init(editorRule: EditorRule(), controlAreaNode: controlAreaNode))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.node.editorContentFactory = { content -> ASCellNode? in
            switch content {
            case let text as NSAttributedString:
                return VEditorTextCellNode(Const.defaultContentInsets,
                                           isEdit: true,
                                           placeholderText: nil,
                                           attributedText: text)
            case let imageNode as VImageContent:
                return VEditorImageNode(Const.defaultContentInsets,
                                        isEdit: true,
                                        url: imageNode.url,
                                        ratio: imageNode.ratio)
            default:
                return nil
            }
        }
        
        
        self.navigationItem.rightBarButtonItem =
            UIBarButtonItem.init(title: "Build",
                                 style: .plain,
                                 target: self,
                                 action: #selector(build))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let path = Bundle.main.path(forResource: "content", ofType: "xml"),
            case let pathURL = URL(fileURLWithPath: path),
            let data = try? Data(contentsOf: pathURL),
            let content = String(data: data, encoding: .utf8) else { return }
        
        self.node.parseXMLString(content)
    }
    
    @objc func build() {
        guard let output = self.node.buildXML(packageTag: "content") else {
            return
        }
        let vc = XMLViewController.init(output)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
