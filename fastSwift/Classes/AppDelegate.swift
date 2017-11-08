//
//  AppDelegate.swift
//  fastSwift
//
//  Created by Adrian on 10.06.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import StoreKit
import SwiftyStoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SKProductsRequestDelegate {
    
    var window: UIWindow?
    var prices = [String]()
    var currentPurchase: SKProduct?
    var menu: MenuViewController!
    var browser: DocumentBrowserViewController!
    var qrScanner: QRScanViewController!
    var theme = Theme.black
    var loadingStoreError = ""
    
    static var shared = AppDelegate()
    
    // -------------------------------------------------------------------------
    // MARK: Helpers
    // -------------------------------------------------------------------------
    
    enum autoCompilationState {
        case userActionNeed
        case ready
        case compiled
        case none
    }
    
    enum ScreenSize {
        case iPhoneSE
        case iPhone8
        case iPhone8Plus
        case iPhoneX
        case iPad
        case iPadPro129
        case iPadPro105
        
        case unknown
    }
    
    var screenSize: ScreenSize {
        switch UIScreen.main.nativeBounds.height {
        case 1136:
            return .iPhoneSE
        case 1334:
            return .iPhone8
        case 2208:
            return .iPhone8Plus
        case 2436:
            return .iPhoneX
        case 2224:
            return .iPadPro105
        case 2732:
            return .iPadPro129
        default:
            if UIDevice.current.userInterfaceIdiom == .pad {
                return .iPad
            }
            return .unknown
        }
    }
    
    func is_iPad() -> Bool {
        return (screenSize == .iPad || screenSize == .iPadPro105 || screenSize == .iPadPro129)
    }
    
    func clearCaches() {
        do {for file in try FileManager.default.contentsOfDirectory(at: FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask)[0], includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            do { try FileManager.default.removeItem(at: file) } catch _ {}
            }} catch _ {}
        
        do {for file in try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath:NSTemporaryDirectory()), includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            do { try FileManager.default.removeItem(at: file) } catch _ {}
            }} catch _ {}
        
    }
    
    func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
    
    // -------------------------------------------------------------------------
    // MARK: In App purchases
    // -------------------------------------------------------------------------
    
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Received products!")
        var prices_ = [Double]()
        var currency = ""
        AccountManager.shared.shop = response.products
        
        for product in response.products {
            prices_.append(product.price.doubleValue)
            currency = product.priceLocale.currencyCode!
        }
        prices_ = prices_.sorted(by: <)
        
        for price in prices_ {
            prices.append("\(price) \(currency)")
        }
        
        print(prices)
        
        menu.reloadStore()
        menu.loadedStore = true
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.loadingStoreError = error.localizedDescription
        (self.menu.vcs[3] as! ErrorLoadingStoreViewController).reloadError()
    }
    
    func completeTransactions() {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                if purchase.transaction.transactionState == .purchased || purchase.transaction.transactionState == .restored {
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    print("purchased: \(purchase)")
                }
            }
        }
    }
    
    
    // -------------------------------------------------------------------------
    // MARK: Delegate
    // -------------------------------------------------------------------------

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        AppDelegate.shared = self
                        
        GuideViewController.initPages()
                
        loadingStoreError = ""
        
        let request = SKProductsRequest(productIdentifiers: ["ch.marcela.ada.fastSwift.purchases.pendrive","ch.marcela.ada.fastSwift.purchases.sd","ch.marcela.ada.fastSwift.purchases.cd","ch.marcela.ada.fastSwift.purchases.hd"])
        request.delegate = self
        request.start()
        print("Start request!")
        
        clearCaches()
        
        UserDefaults.standard.addObserver(self, forKeyPath: "theme", options: .new, context: nil) // Call a function when the theme is changed
        
        if UserDefaults.standard.string(forKey: "oldTheme") == nil {
            UserDefaults.standard.set(Theme.black.name, forKey: "oldTheme")
        }
        
        theme = Theme(name: UserDefaults.standard.string(forKey: "oldTheme")!)
        
        let _ = Afte.r(4) { (timer) in
            self.changeTheme()
        }
        
        // Debug
        let arguments = CommandLine.arguments
        var index = 0
        for argument in arguments {
            if argument == "setCompilations" {
                if arguments.count >= index+1 {
                    if let num = Int(arguments[index+1]) {
                        AccountManager.shared.compilations = num
                    }
                }
            }
            
            index += 1
        }
        
        completeTransactions()
        
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    func application(_ app: UIApplication, open inputURL: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // Reveal / import the document at the URL
        let documentBrowserViewController = AppViewControllers().documentBrowser
        // Present the Document View Controller for the revealed URL
        documentBrowserViewController.dismissState = .ready
        
        self.topViewController()?.present(documentBrowserViewController, animated: true, completion: {
            documentBrowserViewController.revealDocument(at: inputURL, importIfNeeded: true, completion: { (revealedDocumentURL, error) in
                if error == nil {
                    documentBrowserViewController.presentDocument(at: [revealedDocumentURL!])
                } else {
                    print("Error revealing document: \(error!.localizedDescription)")
                }
            })
        })
        
        
        return true
    }

    // -------------------------------------------------------------------------
    // MARK: Theming
    // -------------------------------------------------------------------------

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print("The user has selected a theme")
        let _ = Afte.r(1) { (timer) in
            self.changeTheme()
            self.window!.rootViewController = AppViewControllers().launchScreen
            _ = Afte.r(1, seconds: { (timer) in
                self.applicationWillTerminate(UIApplication.shared)
                _ = self.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
            })
        }
    }
    
    func changeTheme() {
        if let theme = UserDefaults.standard.string(forKey: "theme") {
            if let _ = UserDefaults.standard.string(forKey: "oldTheme") {
                if !Theme(name: theme).isEqual(to: self.theme) {
                    print("Change theme!")
                    UserDefaults.standard.set(theme, forKey: "theme")
                    UserDefaults.standard.set(theme, forKey: "oldTheme")
                    self.theme = Theme(name: theme)
                    
                    if UIApplication.shared.supportsAlternateIcons {
                        UIApplication.shared.setAlternateIconName(self.theme.alternateIcon, completionHandler: { (error) in
                            if error != nil {
                                print(error!)
                            }
                        })
                    }
                    
                }
            }
        }
    }
}

