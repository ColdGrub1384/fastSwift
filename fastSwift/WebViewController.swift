//
//  WebViewController.swift
//  fastSwift
//
//  Created by Adrian on 28.07.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate {
    @IBAction func done(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var webview: UIWebView!
    var url: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webview.loadRequest(URLRequest(url: url))
        webview.delegate = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if webview.request!.url!.absoluteString.hasSuffix(".swiftc") {
            UIApplication.shared.open(webview.request!.url!, options: [:], completionHandler: nil)
            webview.goBack()
        }
    }
}
