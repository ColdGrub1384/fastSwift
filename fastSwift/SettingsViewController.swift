//
//  SettingsViewController.swift
//  fastSwift
//
//  Created by Adrian on 16.07.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import InAppSettingsKit

class SettingsViewController: IASKAppSettingsViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.neverShowPrivacySettings = false
    }

}
