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
    
    let controlAreaNode: EditorControlAreaNode = .init()
    let disposeBag = DisposeBag()
    let parser = VEditorParser(rule: EditorRule())
    
    init() {
        super.init(node: .init(controlAreaNode: controlAreaNode))
        
        guard let path = Bundle.main.path(forResource: "content", ofType: "xml"),
            case let pathURL = URL(fileURLWithPath: path),
            let data = try? Data(contentsOf: pathURL),
            let content = String(data: data, encoding: .utf8) else { return }
        
        parser.rx.result.debug("DEBUG*", trimOutput: true).subscribe(onNext: { scope in
            switch scope {
            case .success(let contents):
                print("DEBUG* \(contents)")
            default:
                break
            }
        }).disposed(by: disposeBag)
        
        parser.parseXML(content)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
