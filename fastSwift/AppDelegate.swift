//
//  AppDelegate.swift
//  fastSwift
//
//  Created by Adrian on 10.06.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import StoreKit



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver {

    var window: UIWindow?
    var prices = [String]()
    var currentPurchase: SKProduct?
    var menu: MenuViewController!
    var browser: DocumentBrowserViewController!
    var qrScanner: QRScanViewController!
    
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
        print("Remove transaction")
    }
    
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
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            let trans = transaction as SKPaymentTransaction
            var continuePurchase = false
            
            print("Buying "+trans.payment.productIdentifier)
            
            switch trans.transactionState {
            case .purchased:
                print("Purchased!")
                continuePurchase = true
                SKPaymentQueue.default().finishTransaction(trans)
            case .purchasing:
                print("Purchasing")
            case .failed:
                if let vc = AccountManager.shared.storeViewController {
                    AlertManager.shared.present(error: trans.error!, withTitle: "Error!", inside: vc)
                }
                print("Error! \(trans.error!)")
            case .restored:
                print("Restored")
            case .deferred:
                print("Deferred")
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
                        print("Unknown purchase!")
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
        print("Start request!")
        SKPaymentQueue.default().add(self)
        
        clearCaches()
                
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
        qrScanner.restartSession()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        qrScanner.restartSession()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
                    print("Error revealing document: \(error!.localizedDescription)")
                }
            })
        })
        
        
        return true
    }


}

