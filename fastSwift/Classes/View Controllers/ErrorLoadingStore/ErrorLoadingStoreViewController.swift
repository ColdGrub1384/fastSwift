//
//  ErrorLoadingStoreViewController.swift
//  fastSwift
//
//  Created by Adrian on 08.10.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class ErrorLoadingStoreViewController: UIViewController {
    @IBOutlet weak var retryBtn: UIButton!
    @IBOutlet weak var doneBtn: UIButton!
    
    var isSaved = true
    var delegate: DocumentViewController?
    @IBOutlet weak var errorText: UITextView!
    
    
    func reload() {
        AppDelegate.shared.window?.rootViewController = AppViewControllers().launchScreen
        _ = Afte.r(1, seconds: { (timer) in
            AppDelegate.shared.applicationWillTerminate(UIApplication.shared)
            _ = AppDelegate.shared.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
            self.view.backgroundColor = .black
            for subview in self.view.subviews {
                subview.removeFromSuperview()
            }
        })
    }
    
    func reloadError() {
        errorText.text = AppDelegate.shared.loadingStoreError
    }
    
    // -------------------------------------------------------------------------
    // MARK: UIViewController
    // -------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        retryBtn.tintColor = AppDelegate.shared.theme.tintColor
        doneBtn.tintColor = AppDelegate.shared.theme.tintColor
        if let error = view.viewWithTag(1) as? UILabel {
            error.textColor = AppDelegate.shared.theme.textColor
        }
        
        view.backgroundColor = AppDelegate.shared.theme.color
        
        reloadError()
        errorText.textColor = AppDelegate.shared.theme.textColor
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppDelegate.shared.theme.statusBarStyle
    }
    
    
    // -------------------------------------------------------------------------
    // MARK: Buttons
    // -------------------------------------------------------------------------
    
    @IBAction func retry(_ sender: Any) {
        if isSaved {
            reload()
        } else {
            AlertManager.shared.presentAlert(withTitle: "Unsaved changes!", message: "You made changes to your file\nretrying opening the store requiere to reload the app\nDo you want to save changes?", style: .alert, actions: [UIAlertAction.init(title: "Save", style: .default, handler: { (action) in
                if let delegate = self.delegate {
                    do {
                        try delegate.code.text.write(to: (delegate.document?.fileURL)!, atomically: true, encoding: String.Encoding.utf8)
                        self.reload()
                    } catch let error {
                        AlertManager.shared.present(error: error, withTitle: "Error saving file!", inside: self)
                    }
                    delegate.document?.close(completionHandler: nil)
                    
                }
            }), UIAlertAction.init(title: "Don't save", style: .destructive, handler: { (action) in
                self.reload()
            }), AlertManager.shared.cancel], inside: self, animated: true, completion: nil)
        }
    }
    
    @IBAction func done(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
}
