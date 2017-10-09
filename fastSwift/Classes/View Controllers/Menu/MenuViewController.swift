//
//  MenuViewController.swift
//  fastSwift
//
//  Created by Adrian on 13.09.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import NMSSH

class MenuViewController: UIViewController {
    @IBOutlet weak var scroll: UIScrollView!
    
    var settingsFile = "Root"
    
    var vcs = [UIViewController]()
    
    var mainVCIndex = 2
    var loadedStore = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let fileBrowser:DocumentBrowserViewController = AppViewControllers().documentBrowser
        let settings: UINavigationController = AppViewControllers().settings
        let loadingStore: UIViewController = AppViewControllers().errorLoadingStore
        let qrScan:QRScanViewController = AppViewControllers().camera
        let news:WebViewController = AppViewControllers().web
        let setup:SetupServerViewController = AppViewControllers().setupServer
        
        
        let session = NMSSHSession.connect(toHost: Server.host, withUsername: Server.user)
        if (session?.isConnected)! {
            session?.authenticate(byPassword: Server.password)
            if (session?.isAuthorized)! {
                do {
                    let html = try session?.channel.execute("cat /home/fastswift/latest.html")
                    news.html = html
                    session?.disconnect()
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
        
        vcs = [news,qrScan, fileBrowser, loadingStore, settings, setup]
        
        if loadedStore {
            vcs[3] = AppViewControllers().store
        }
        
        scroll.backgroundColor = AppDelegate.shared.theme.color
        
        self.view.backgroundColor = AppDelegate.shared.theme.color
        
        let screenBounds = UIScreen.main.bounds
        
        var count:CGFloat = -1
        for vc in vcs {
            self.addChildViewController(vc)
            self.scroll.addSubview(vc.view)
            vc.didMove(toParentViewController: self)
            vc.view.bounds = screenBounds
            vc.view.frame = self.scroll.frame
            
            if vc != vcs.first {
                var vcframe:CGRect = vc.view.frame
                vcframe.origin.x = screenBounds.width+10+(screenBounds.width*count)
                vcframe.origin.y = vcframe.origin.y+20
                vc.view.frame = vcframe
                vc.view.frame.size.height = vc.view.frame.height-(20)
                if vc != vcs.last {
                    vc.view.frame.size.width = vc.view.frame.width-20
                }
            } else {
                vc.view.frame.size.width = vc.view.frame.width-20
                vc.view.frame.size.height = vc.view.frame.height-(20)
                vc.view.frame.origin.y = vc.view.frame.origin.y+20
            }
            
            count+=1
            
            vcs[Int(count)] = vc
        
        }
        
        if news.html != UserDefaults.standard.string(forKey: "html") {
            UserDefaults.standard.set(news.html, forKey: "html")
        }
        
        let mainVc = vcs[mainVCIndex]
        
        self.scroll.contentSize = CGSize(width: self.view.frame.width*CGFloat.init(vcs.count), height: self.view.frame.height)
        
        let origin = CGPoint(x: mainVc.view.frame.origin.x-10, y: mainVc.view.frame.origin.y-20)
        self.scroll.setContentOffset(origin, animated: false)
        
        news.doneBtn.isEnabled = false
        
                
    }

    
    func reloadStore() {
        let frame = vcs[3].view.frame
        vcs[3].view.removeFromSuperview()
        vcs[3] = AppViewControllers().store
        ((vcs[3] as! UINavigationController).viewControllers.first! as! StoreViewController).doneBtn.isEnabled = false
        addChildViewController(vcs[3])
        scroll.addSubview(vcs[3].view)
        vcs[3].view.frame = frame
    }
    
    func reload() {
        let vc = AppViewControllers().menu
        vc.mainVCIndex = mainVCIndex
        vc.loadedStore = loadedStore
        AppDelegate.shared.window?.rootViewController = vc
    }
    
    func showSettings() {
        let vc = AppViewControllers().menu
        vc.mainVCIndex = 4
        vc.loadedStore = loadedStore
        AppDelegate.shared.window?.rootViewController = vc
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppDelegate.shared.theme.statusBarStyle
    }

    
}
