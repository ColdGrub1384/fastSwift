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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        retryBtn.tintColor = AppDelegate.shared.theme.tintColor
        if let error = view.viewWithTag(1) as? UILabel {
            error.textColor = AppDelegate.shared.theme.textColor
        }
        
        view.backgroundColor = AppDelegate.shared.theme.color
    }
    
    @IBAction func retry(_ sender: Any) {
        AppDelegate.shared.applicationWillTerminate(UIApplication.shared)
        _ = AppDelegate.shared.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
        
        AppDelegate.shared.window?.rootViewController = self.storyboard?.instantiateInitialViewController()
    }
}
