//
//  PreviewViewController.swift
//  QuickLook
//
//  Created by Adrian on 18.06.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import QuickLook

class PreviewViewController: UIViewController, QLPreviewingController {
        
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping QLPreviewItemLoadingBlock) {
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        handler(nil)
    }
    
    
    func preparePreviewOfFile(at URL: URL, completionHandler handler: @escaping QLPreviewItemLoadingBlock) {
        label.text = URL.deletingPathExtension().lastPathComponent
        handler(nil)
    }
    
}
