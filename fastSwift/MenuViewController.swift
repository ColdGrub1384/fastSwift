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
    
    var loadedStore = false
    var settingsFile = "Root"
    
    var vcs = [UIViewController]()
    
    var mainVCIndex = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppDelegate.shared.menu = self
        
        let fileBrowser:DocumentBrowserViewController = self.storyboard!.instantiateViewController(withIdentifier: "browser") as! DocumentBrowserViewController
        let store:UINavigationController = self.storyboard!.instantiateViewController(withIdentifier: "store") as! UINavigationController
        let settings: UINavigationController = self.storyboard!.instantiateViewController(withIdentifier: "settingsNav") as! UINavigationController
        let loadingStore: UIViewController = self.storyboard!.instantiateViewController(withIdentifier: "loadingStore")
        let qrScan:QRScanViewController = self.storyboard!.instantiateViewController(withIdentifier: "qrScan") as! QRScanViewController
        let news:WebViewController = self.storyboard!.instantiateViewController(withIdentifier: "webview") as! WebViewController
        let setup:SetupServerViewController = self.storyboard!.instantiateViewController(withIdentifier: "setup") as! SetupServerViewController
        
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
        
        if loadedStore {
            vcs = [news ,qrScan, fileBrowser, store, settings, setup]
        } else {
            vcs = [news,qrScan, fileBrowser, loadingStore, settings, setup]
        }
        
        scroll.backgroundColor = #colorLiteral(red: 0.1490048468, green: 0.1490279436, blue: 0.1489969492, alpha: 1)
        
        self.view.backgroundColor = fileBrowser.view.backgroundColor
        
        var count:CGFloat = -1
        for vc in vcs {
            self.addChildViewController(vc)
            self.scroll.addSubview(vc.view)
            vc.didMove(toParentViewController: self)
            
            if vc != vcs.first {
                var vcframe:CGRect = vc.view.frame
                vcframe.origin.x = self.view.frame.width+10+(self.view.frame.width*count)
                vcframe.origin.y = vcframe.origin.y+20
                vc.view.frame = vcframe
                vc.view.frame.size.height = vc.view.frame.height-20
                if vc != vcs.last {
                    vc.view.frame.size.width = vc.view.frame.width-20
                }
            } else {
                vc.view.frame.size.width = vc.view.frame.width-20
                vc.view.frame.size.height = vc.view.frame.height-20
                vc.view.frame.origin.y = vc.view.frame.origin.y+20
            }
            
            count+=1
            
            vcs[Int(count)] = vc
        
        }
        
        if news.html != UserDefaults.standard.string(forKey: "html") {
            mainVCIndex = 0
            UserDefaults.standard.set(news.html, forKey: "html")
        }
        
        let mainVc = vcs[mainVCIndex]
        
        (store.viewControllers.first! as! StoreViewController).doneBtn.isEnabled = false
        
        self.scroll.contentSize = CGSize(width: self.view.frame.width*CGFloat.init(vcs.count), height: self.view.frame.height)
        
        let origin = CGPoint(x: mainVc.view.frame.origin.x-10, y: mainVc.view.frame.origin.y-20)
        self.scroll.setContentOffset(origin, animated: false)
        
        news.doneBtn.isEnabled = false
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func reloadStore() {
        let vc = self.storyboard!.instantiateInitialViewController()! as! MenuViewController
        vc.loadedStore = true
        vc.mainVCIndex = mainVCIndex
        self.present(vc, animated: false, completion: nil)
    }
    
    func reload() {
        let vc = self.storyboard!.instantiateInitialViewController()! as! MenuViewController
        vc.loadedStore = self.loadedStore
        vc.mainVCIndex = mainVCIndex
        self.present(vc, animated: false, completion: nil)
    }
    
    func showSettings() {
        let vc = self.storyboard!.instantiateInitialViewController()! as! MenuViewController
        vc.mainVCIndex = 4
        vc.loadedStore = loadedStore
        self.present(vc, animated: false, completion: nil)
    }
    
}
