//
//  ExporToXcodeActivity.swift
//  fastSwift
//
//  Created by Adrian on 08.07.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class ExportToXcodeActivty: UIActivity {
    
    var delegate: OrganizerTableViewController?
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "fastSwift.xcode")
    }
    
    override var activityTitle: String? {
        return Strings.ExportToXcodeActivity.title
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        NSLog("%@", #function)
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        NSLog("%@", #function)
    }
    
    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "xcode")
    }
    
    override func perform() {
        if let delegate = self.delegate {
            if !delegate.delegate!.firstLaunch {
                let vc = AppViewControllers().exportToXcode
                vc.delegate = delegate
                delegate.present(vc, animated: true, completion: nil)
            } else {
                AlertManager.shared.presentAlert(withTitle: Strings.noMainFileAlert.title, message: Strings.noMainFileAlert.message, style: .alert, actions: [AlertManager.shared.ok(handler: nil)], inside: delegate, animated: true, completion: nil)
            }
        }
    }
    
    override class var activityCategory:UIActivityCategory {
        return .share
    }
    
}
