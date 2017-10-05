//
//  InstructionsViewController.swift
//  fastSwift
//
//  Created by Adrian on 05.10.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class InstructionsViewController: UIViewController {
    @IBAction func done(_ sender:Any) {
        self.view.removeFromSuperview()
        self.removeFromParentViewController()
    }
}
