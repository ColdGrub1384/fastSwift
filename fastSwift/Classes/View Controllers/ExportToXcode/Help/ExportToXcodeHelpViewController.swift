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
        
        textView = Strings.ExportToXcodeHelp.textView(for: self)
        
        textView.backgroundColor = Theme.current.color
        view.backgroundColor = Theme.current.color
        textView.textColor = Theme.current.textColor
        view.tintColor = Theme.current.tintColor
        navBar.barStyle = Theme.current.barStyle
        navBar.barTintColor = Theme.current.color        
    }
    
    @IBAction func done(_ sender:Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Theme.current.statusBarStyle
    }
}
