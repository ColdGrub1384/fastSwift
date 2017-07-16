//
//  ThumbnailProvider.swift
//  SwiftFileIcon
//
//  Created by Adrian on 18.06.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import QuickLook

class ThumbnailProvider: QLThumbnailProvider {
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        print("Handle file icon request!!!!!!!!!!")
        print(request.fileURL)
        handler(QLThumbnailReply(imageFileURL: Bundle.main.url(forResource: "fastSwift file icon", withExtension: "png")!), nil)
    }
    
}
