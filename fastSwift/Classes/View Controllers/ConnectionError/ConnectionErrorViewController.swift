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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AccountManager.shared.customServerEnabled {
            errorText.text = "There is a problem connecting to \(Server.host). Please check for your internet connection or check your server's host, user, password and availabilty."
            errorText.delegate = self
        } else {
            errorText.text = "There is a problem connecting to \(Server.host). Please check for your internet connection or retry later if you think is a server problem."
        }
    }
    
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
