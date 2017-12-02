//
//  ConnectionErrorViewController.swift
//  fastSwift
//
//  Created by Adrian on 01.07.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import NMSSH

class ConnectionErrorViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var errorText: UITextView!
    @IBOutlet weak var settingBtn: UIButton!
    
    // -------------------------------------------------------------------------
    // MARK: UIViewController
    // -------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.ConnectionError.title
        settingBtn.setTitle(Strings.ConnectionError.serverSettings, for: .normal)
        
        if AccountManager.shared.customServerEnabled {
            errorText.text = Strings.ConnectionError.Errors.errorForCustomServer
            errorText.delegate = self
        } else {
            errorText.text = Strings.ConnectionError.Errors.errorForDefaultServer
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: Buttons
    // -------------------------------------------------------------------------
    
    @IBAction func retry(sender:Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func settings(_ sender: Any) {
        let vc = AppViewControllers().settings
        if let settings = vc.viewControllers.first as? SettingsViewController {
            settings.file = "Server"
            settings.title = "Custom server"
            
            self.present(vc, animated: true, completion: nil)
        }
    }
}
