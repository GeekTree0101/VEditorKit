import AsyncDisplayKit
import RxCocoa
import RxSwift

extension Reactive where Base: VEditorDeleteMediaNode {
    
    public var didTapDelete: Observable<Void> {
        return base.didTapDeleteRelay.asObservable()
    }
}

public class VEditorDeleteMediaNode: ASControlNode {
    
    lazy var deleteButtonNode: ASControlNode = {
        let node = ASControlNode()
        node.cornerRadius = 5.0
        node.backgroundColor = self.deleteColor
        node.style.preferredSize = .init(width: 50.0, height: 50.0)
        return node
    }()
    
    lazy var closeIconNode: ASImageNode = {
        let node = ASImageNode()
        node.isUserInteractionEnabled = false
        node.backgroundColor = .white
        node.style.preferredSize = .init(width: 30.0, height: 10.0)
        node.cornerRadius = 5.0
        return node
    }()
    
    private let deleteColor: UIColor
    private let deleteIconImage: UIImage?
    internal let didTapDeleteRelay = PublishRelay<Void>()
    
    public init(_ color: UIColor, deleteIconImage: UIImage?) {
        self.deleteColor = color
        self.deleteIconImage = deleteIconImage
        super.init()
        self.borderWidth = 5.0
        self.borderColor = deleteColor.cgColor
        self.automaticallyManagesSubnodes = true
    }
    
    override public func didLoad() {
        super.didLoad()
        deleteButtonNode.addTarget(self,
                                   action: #selector(didTapDeleteButton),
                                   forControlEvents: .touchUpInside)
    }
    
    @objc public func didTapDeleteButton() {
        self.didTapDeleteRelay.accept(())
    }
    
    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASRelativeLayoutSpec(horizontalPosition: .end,
                                    verticalPosition: .start,
                                    sizingOption: [],
                                    child: deleteButtonLayoutSpec())
    }
    
    private func deleteButtonLayoutSpec() -> ASLayoutSpec {
        let centerLayout = ASCenterLayoutSpec(centeringOptions: .XY,
                                              sizingOptions: [],
                                              child: closeIconNode)
        return ASOverlayLayoutSpec(child: deleteButtonNode, overlay: centerLayout)
    }
}
