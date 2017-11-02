//
//  ExportToBinaryActivity.swift
//  fastSwift
//
//  Created by Adrian on 19.07.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class ExportToBinaryActivity: UIActivity {
    var delegate: OrganizerTableViewController?
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "fastSwift.bin")
    }
    
    override var activityTitle: String? {
        return "Export to binary"
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        NSLog("%@", #function)
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        NSLog("%@", #function)
    }
    
    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "terminal")
    }
    
    override func perform() {
        if let delegate = self.delegate {
            
            if Server.host != Server.default.host && Server.user != Server.default.user {
                AlertManager.shared.presentAlert(withTitle: "Can't download binary!", message: "Binaries download are only allowed for default server", style: .alert, actions: [AlertManager.shared.ok(handler: nil)], inside: delegate, animated: true, completion: nil)
                
                return
            }
            
            if !delegate.delegate!.firstLaunch {
                delegate.downloadBinary()
            } else {
                AlertManager.shared.presentAlert(withTitle: "No main file!", message: "Please select a main file before export to binary.", style: .alert, actions: [AlertManager.shared.ok(handler: nil)], inside: delegate, animated: true, completion: nil)
            }
        }
    }
    
    override class var activityCategory:UIActivityCategory {
        return .share
    }
}
