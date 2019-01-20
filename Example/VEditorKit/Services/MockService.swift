//
//  MockService.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import VEditorKit

struct MockService {
    
    static func getOgObject(_ url: URL) -> Observable<[String: String]> {
        return Observable.just(["title": "test title",
                                "desc": "test description",
                                "url": url.absoluteString,
                                "image": "https://cdn-images-1.medium.com/max/1600/0*XNcfCZEJrsXenM9c.jpg"])
            .delay(2.0, scheduler: MainScheduler.instance)
    }
}
