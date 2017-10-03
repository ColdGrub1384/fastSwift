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
        
        AppDelegate.shared.menu = self
        
        let fileBrowser:DocumentBrowserViewController = self.storyboard!.instantiateViewController(withIdentifier: "browser") as! DocumentBrowserViewController
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
                    Debugger.shared.debug_(error.localizedDescription)
                }
            }
        }
        
        vcs = [news,qrScan, fileBrowser, loadingStore, settings, setup]
        
        if loadedStore {
            vcs[3] = self.storyboard!.instantiateViewController(withIdentifier: "store") as! UINavigationController
        }
        
        scroll.backgroundColor = #colorLiteral(red: 0.1490048468, green: 0.1490279436, blue: 0.1489969492, alpha: 1)
        
        self.view.backgroundColor = fileBrowser.view.backgroundColor
        
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
        
        self.scroll.contentSize = CGSize(width: self.view.frame.width*CGFloat.init(vcs.count), height: self.view.frame.height)
        
        let origin = CGPoint(x: mainVc.view.frame.origin.x-10, y: mainVc.view.frame.origin.y-20)
        self.scroll.setContentOffset(origin, animated: false)
        
        news.doneBtn.isEnabled = false
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func reloadStore() {
        let frame = vcs[3].view.frame
        vcs[3].view.removeFromSuperview()
        vcs[3] = self.storyboard!.instantiateViewController(withIdentifier: "store") as! UINavigationController
        ((vcs[3] as! UINavigationController).viewControllers.first! as! StoreViewController).doneBtn.isEnabled = false
        addChildViewController(vcs[3])
        scroll.addSubview(vcs[3].view)
        vcs[3].view.frame = frame
    }
    
    func reload() {
        let vc = self.storyboard!.instantiateInitialViewController()! as! MenuViewController
        vc.mainVCIndex = mainVCIndex
        vc.loadedStore = loadedStore
        self.present(vc, animated: false, completion: nil)
    }
    
    func showSettings() {
        let vc = self.storyboard!.instantiateInitialViewController()! as! MenuViewController
        vc.mainVCIndex = 4
        vc.loadedStore = loadedStore
        self.present(vc, animated: false, completion: nil)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
}
