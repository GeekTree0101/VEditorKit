//
//  VEditorVideoNode.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import RxSwift
import RxCocoa

extension Reactive where Base: VEditorVideoNode {
    
    public var didTapDelete: Observable<Void> {
        return base.deleteControlNode.rx.didTapDelete
    }
}
public class VEditorVideoNode: ASCellNode {
    
    public var insets: UIEdgeInsets = .zero
    public var isEdit: Bool = true
    public let disposeBag = DisposeBag()
    
    public lazy var deleteControlNode: VEditorDeleteMediaNode = .init(.red, deleteIconImage: nil)
    
    public required init(_ insets: UIEdgeInsets, isEdit: Bool) {
        self.insets = insets
        self.isEdit = isEdit
        super.init()
        self.automaticallyManagesSubnodes = true
        self.selectionStyle = .none
    }
}
