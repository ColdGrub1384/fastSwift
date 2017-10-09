//
//  AppViewControllers.swift
//  fastSwift
//
//  Created by Adrian on 09.10.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class AppViewControllers {
    static private func viewController(from storyboardName:String) -> UIViewController {
        return UIStoryboard(name: storyboardName, bundle: nil).instantiateInitialViewController()!
    }
    
    private init() {
        
    }
    
    static var launchScreen: LaunchScreenViewController = viewController(from: "Main") as! LaunchScreenViewController
    static var documentBrowser: DocumentBrowserViewController = viewController(from: "DocumentBrowser") as! DocumentBrowserViewController
    static var menu: MenuViewController = viewController(from: "Menu") as! MenuViewController
    static var store: UINavigationController = viewController(from: "Store") as! UINavigationController
    static var web: WebViewController = viewController(from: "Web") as! WebViewController
    static var document: DocumentViewController = viewController(from: "Document") as! DocumentViewController
    static var organizer: OrganizerTableViewController = viewController(from: "Organizer") as! OrganizerTableViewController
    static var exportToXcode: ExportToXcodeViewController = viewController(from: "ExportToXcode") as! ExportToXcodeViewController
    static var exportToXcodeHelp: ExportToXcodeHelpViewController = viewController(from: "ExportToXcodeHelp") as! ExportToXcodeHelpViewController
    static var terminal: NMTerminalViewController = viewController(from: "Terminal") as! NMTerminalViewController
    static var setupServer: SetupServerViewController = viewController(from: "SetupServer") as! SetupServerViewController
    static var camera: QRScanViewController = viewController(from: "Camera") as! QRScanViewController
    static var errorLoadingStore: ErrorLoadingStoreViewController = viewController(from: "ErrorLoadingStore") as! ErrorLoadingStoreViewController
    static var settings: UINavigationController = viewController(from: "Settings") as! UINavigationController
    static var connectionError: UINavigationController = viewController(from: "ConnectionError") as! UINavigationController
}
