//
//  ExportToXcodeHelpViewController.swift
//  fastSwift
//
//  Created by Adrian on 09.07.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class ExportToXcodeHelpViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var navBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.backgroundColor = AppDelegate.shared.theme.color
        view.backgroundColor = AppDelegate.shared.theme.color
        textView.textColor = AppDelegate.shared.theme.textColor
        view.tintColor = AppDelegate.shared.theme.tintColor
        navBar.barStyle = AppDelegate.shared.theme.barStyle
        navBar.barTintColor = AppDelegate.shared.theme.color
    }
    
    @IBAction func done(_ sender:Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppDelegate.shared.theme.statusBarStyle
    }
}
