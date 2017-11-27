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
        
        self.tableView.backgroundColor = Theme.current.color
        self.neverShowPrivacySettings = false
        self.backgroundColor = Theme.current.color
        self.textColor = Theme.current.textColor
        self.navigationController?.navigationBar.barStyle = Theme.current.barStyle
        self.navigationController?.navigationBar.barTintColor = Theme.current.color
        self.navigationController?.navigationBar.tintColor = Theme.current.tintColor
    }

}
