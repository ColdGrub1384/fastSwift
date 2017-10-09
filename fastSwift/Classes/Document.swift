//
//  Document.swift
//  fastSwift
//
//  Created by Adrian on 10.06.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class Document: UIDocument {
    
    var delegate: DocumentDelegate?
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        return code
    }
    
    var code: String {
        do {
            let c = try String(contentsOfFile: fileURL.path)
            return c
        } catch let error {
            if let delegate = delegate {
                delegate.document(self, didLoadContentsWithError: error)
            }
            return ""
        }
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
        if let delegate = delegate {
            delegate.document(self, didLoadContents: code)
        }
    }
    
    override func close(completionHandler: ((Bool) -> Void)? = nil) {
        super.close(completionHandler: completionHandler)
        if let delegate = delegate {
            delegate.document(didClose: self)
        }
    }
    
    override func open(completionHandler: ((Bool) -> Void)? = nil) {
        if let delegate = delegate {
            delegate.document(willOpen: self)
        }
        super.open(completionHandler: completionHandler)
    }
}

protocol DocumentDelegate {
    func document(didClose document:Document)
    
    func document(_ document:Document, didLoadContents contents:String)
    
    func document(willOpen document:Document)
    
    func document(_ document:Document, didLoadContentsWithError error:Error)
}

