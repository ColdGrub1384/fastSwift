//
//  ThumbnailProvider.swift
//  execThumbnail
//
//  Created by Adrian on 18.07.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import QuickLook

class ThumbnailProvider: QLThumbnailProvider {
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        handler(nil, nil)
    }
}
