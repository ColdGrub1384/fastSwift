//
//  AppViewControllers().swift
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
    
    var launchScreen: LaunchScreenViewController = viewController(from: "Main") as! LaunchScreenViewController
    var documentBrowser: DocumentBrowserViewController = viewController(from: "DocumentBrowser") as! DocumentBrowserViewController
    var menu: MenuViewController = viewController(from: "Menu") as! MenuViewController
    var store: UINavigationController = viewController(from: "Store") as! UINavigationController
    var web: WebViewController = viewController(from: "Web") as! WebViewController
    var document: DocumentViewController = viewController(from: "Document") as! DocumentViewController
    var organizer: OrganizerTableViewController = viewController(from: "Organizer") as! OrganizerTableViewController
    var exportToXcode: ExportToXcodeViewController = viewController(from: "ExportToXcode") as! ExportToXcodeViewController
    var exportToXcodeHelp: ExportToXcodeHelpViewController = viewController(from: "ExportToXcodeHelp") as! ExportToXcodeHelpViewController
    var terminal: NMTerminalViewController = viewController(from: "Terminal") as! NMTerminalViewController
    var setupServer: SetupServerViewController = viewController(from: "SetupServer") as! SetupServerViewController
    var camera: QRScanViewController = viewController(from: "Camera") as! QRScanViewController
    var errorLoadingStore: ErrorLoadingStoreViewController = viewController(from: "ErrorLoadingStore") as! ErrorLoadingStoreViewController
    var settings: UINavigationController = viewController(from: "Settings") as! UINavigationController
    var connectionError: UINavigationController = viewController(from: "ConnectionError") as! UINavigationController
    var guide: GuideViewController = viewController(from: "Guide") as! GuideViewController
}
