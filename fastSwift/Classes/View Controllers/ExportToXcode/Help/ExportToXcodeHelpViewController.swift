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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppDelegate.shared.theme.color
        textView.textColor = AppDelegate.shared.theme.textColor
    }
    
    @IBAction func done(_ sender:Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
