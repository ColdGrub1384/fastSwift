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
    var html: String!
    
    @IBOutlet weak var doneBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if url != nil {
            webview.loadRequest(URLRequest(url: url))
        }
        
        if html != nil {
            webview.loadHTMLString(html, baseURL: nil)
        }
        
        webview.delegate = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        print(request.url!.absoluteString)
        if request.url!.absoluteString.hasSuffix(".swiftc") {
            self.present(ActivityViewController.init(message: "Downloading..."), animated: true, completion: nil)

            AppDelegate.shared.clearCaches()
            URLSession.shared.downloadTask(with: request.url!, completionHandler: { (url, response, error) in
                if error == nil {
                    if url != nil {
                        let finalURL = url!.deletingLastPathComponent().appendingPathComponent(response!.suggestedFilename!)
                        do {
                            try FileManager.default.moveItem(at: url!, to: finalURL)
                            self.dismiss(animated: true, completion: {
                                let _ = AppDelegate.shared.application(UIApplication.shared, open: finalURL)
                            })
                        } catch let error {
                            self.dismiss(animated: true, completion: {
                                AlertManager.shared.presentAlert(withTitle: "Error moving file!", message: error.localizedDescription, style: .alert, actions: [AlertManager.shared.cancel], inside: self, animated: true, completion: nil)
                            })
                        }
                    } else {
                        self.dismiss(animated: true, completion: {
                            AlertManager.shared.presentAlert(withTitle: "Error downloading file!", message: "Returned data is empty", style: .alert, actions: [AlertManager.shared.cancel], inside: self, animated: true, completion: nil)
                        })
                    }
                } else {
                    self.dismiss(animated: true, completion: {
                        AlertManager.shared.present(error: error!, withTitle: "Error downloading file!", inside: self)
                    })
                }
            }).resume()
            
            return false
        } else {
            return true
        }
    }
}
