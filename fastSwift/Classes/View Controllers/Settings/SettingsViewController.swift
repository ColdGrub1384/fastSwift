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
        
        self.tableView.backgroundColor = AppDelegate.shared.theme.color
        self.neverShowPrivacySettings = false
        self.backgroundColor = AppDelegate.shared.theme.color
        self.textColor = AppDelegate.shared.theme.textColor
        self.navigationController?.navigationBar.barStyle = AppDelegate.shared.theme.barStyle
        self.navigationController?.navigationBar.barTintColor = AppDelegate.shared.theme.color
        self.navigationController?.navigationBar.tintColor = AppDelegate.shared.theme.tintColor
    }

}
