//
//  AppDelegate.swift
//  fastSwift
//
//  Created by Adrian on 10.06.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import StoreKit


class AppDelegate: UIResponder, UIApplicationDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    var window: UIWindow?
    var prices = [String]()
    var currentPurchase: SKProduct?
    var menu: MenuViewController!
    var browser: DocumentBrowserViewController!
    var qrScanner: QRScanViewController!
    var theme = Theme.black
    
    static var shared = AppDelegate()
    
    enum autoCompilationState {
        case userActionNeed
        case ready
        case compiled
        case none
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
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        Debugger.shared.debug_("Remove transaction")
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        Debugger.shared.debug_("Received products!")
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
        
        Debugger.shared.debug_(prices)
        
        menu.reloadStore()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            let trans = transaction as SKPaymentTransaction
            var continuePurchase = false
            
            Debugger.shared.debug_("Buying "+trans.payment.productIdentifier)
            
            switch trans.transactionState {
            case .purchased:
                Debugger.shared.debug_("Purchased!")
                continuePurchase = true
                SKPaymentQueue.default().finishTransaction(trans)
            case .purchasing:
                Debugger.shared.debug_("Purchasing")
            case .failed:
                if let vc = AccountManager.shared.storeViewController {
                    AlertManager.shared.present(error: trans.error!, withTitle: "Error!", inside: vc)
                }
                Debugger.shared.debug_("Error! \(trans.error!)")
            case .restored:
                Debugger.shared.debug_("Restored")
            case .deferred:
                Debugger.shared.debug_("Deferred")
            }
            
            if continuePurchase {
                if currentPurchase != nil {
                    switch currentPurchase!.productIdentifier {
                    case "ch.marcela.ada.fastSwift.purchases.pendrive":
                        AccountManager.shared.buy(product: .pendrive)
                    case "ch.marcela.ada.fastSwift.purchases.sd":
                        AccountManager.shared.buy(product: .sdCard)
                    case "ch.marcela.ada.fastSwift.purchases.cd":
                        AccountManager.shared.buy(product: .cd)
                    case "ch.marcela.ada.fastSwift.purchases.hd":
                        AccountManager.shared.buy(product: .hardDrive)
                    default:
                        Debugger.shared.debug_("Unknown purchase!")
                    }
                }
            }
            
        }
    }
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        AppDelegate.shared = self
        
        let request = SKProductsRequest(productIdentifiers: ["ch.marcela.ada.fastSwift.purchases.pendrive","ch.marcela.ada.fastSwift.purchases.sd","ch.marcela.ada.fastSwift.purchases.cd","ch.marcela.ada.fastSwift.purchases.hd"])
        request.delegate = self
        request.start()
        Debugger.shared.debug_("Start request!")
        SKPaymentQueue.default().add(self)
        
        clearCaches()
        
        UserDefaults.standard.addObserver(self, forKeyPath: "theme", options: .new, context: nil) // Call a function when the theme is changed
        
        if UserDefaults.standard.string(forKey: "oldTheme") == nil {
            UserDefaults.standard.set(Theme.black.name, forKey: "oldTheme")
        }
        
        theme = Theme(name: UserDefaults.standard.string(forKey: "oldTheme")!)
        
        let _ = Afte.r(4) { (timer) in
            self.changeTheme()
        }
                
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
        Debugger.shared.close()
    }

    func application(_ app: UIApplication, open inputURL: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // Reveal / import the document at the URL
        let documentBrowserViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "browser") as! DocumentBrowserViewController
        // Present the Document View Controller for the revealed URL
        documentBrowserViewController.dismissState = .ready
        
        self.topViewController()?.present(documentBrowserViewController, animated: true, completion: {
            documentBrowserViewController.revealDocument(at: inputURL, importIfNeeded: true, completion: { (revealedDocumentURL, error) in
                if error == nil {
                    documentBrowserViewController.presentDocument(at: [revealedDocumentURL!])
                } else {
                    Debugger.shared.debug_("Error revealing document: \(error!.localizedDescription)")
                }
            })
        })
        
        
        return true
    }


    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        Debugger.shared.debug_("The user has selected a theme")
        let _ = Afte.r(1) { (timer) in
            self.changeTheme()
        }
    }
    
    func changeTheme() {
        if let theme = UserDefaults.standard.string(forKey: "theme") {
            if let _ = UserDefaults.standard.string(forKey: "oldTheme") {
                if !Theme(name: theme).isEqual(to: self.theme) {
                    Debugger.shared.debug_("Change theme!")
                    UserDefaults.standard.set(theme, forKey: "theme")
                    UserDefaults.standard.set(theme, forKey: "oldTheme")
                    self.theme = Theme(name: theme)
                    
                    if self.theme.isEqual(to: Theme(name:"black")) {
                        self.browser.view.tintColor = .orange
                        self.browser.browserUserInterfaceStyle = .dark
                    } else if self.theme.isEqual(to: Theme(name:"white")) {
                        self.browser.view.tintColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
                        self.browser.browserUserInterfaceStyle = .white
                    }
                    
                    if UIApplication.shared.supportsAlternateIcons {
                        UIApplication.shared.setAlternateIconName(self.theme.alternateIcon, completionHandler: { (error) in
                            if error != nil {
                                Debugger.shared.debug_(error!)
                            }
                        })
                    }
                    
                }
            }
        }
    }
}

