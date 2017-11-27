//
//  LaunchScreen.swift
//  fastSwift
//
//  Created by Adrian on 07.10.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import AVFoundation

class LaunchScreenViewController: UIViewController {
    @IBOutlet weak var whiteLbl: UILabel!
    @IBOutlet weak var blackLbl: UILabel!

    var menu: MenuViewController!
    
    // -------------------------------------------------------------------------
    // MARK: UIViewController
    // -------------------------------------------------------------------------
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Theme.current.statusBarStyle
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if menu == nil {
            menu = AppViewControllers().menu
        }
        
        addChildViewController(menu)
        view.addSubview(menu.view)
        menu.view.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let _ = Afte.r(0.1) { (timer) in
            let _ = Repea.t(all: 0.001) { (timer) in
                if Theme.current.browserUserInterfaceStyle == .dark { // Animation for black theme
                    self.animBlack(timer: timer)
                } else { // Animation for white theme
                    self.animWhite(timer: timer)
                }
            }
        }
        
        let orientation = UIDevice.current.orientation
        
        if orientation == .landscapeLeft || orientation == .landscapeRight {
            menu.view.removeFromSuperview()
            menu.removeFromParentViewController()
            menu = AppViewControllers().menu
            addChildViewController(menu)
            view.addSubview(menu.view)
            menu.view.isHidden = true
        }
        
        if AppDelegate.shared.isFirstLaunch && AVCaptureDevice.authorizationStatus(for: AVMediaType.video) != .notDetermined {
            self.present(GuideViewController.pages.first!, animated: true, completion: nil)
        }
        
    }
    
    // -------------------------------------------------------------------------
    // MARK: Animations
    // -------------------------------------------------------------------------
    
    func animWhite(timer: Timer) {
        
        if self.whiteLbl.frame.width >= self.view.frame.width {
            self.whiteLbl.textColor = .white
            self.blackLbl.isHidden = true
            timer.invalidate()
            let _ = Afte.r(0.5, seconds: { (timer) in
                self.menu.view.isHidden = false
                self.view.bringSubview(toFront: self.menu.view)
            })
        } else {
            self.whiteLbl.frame.size.width += 1
            self.blackLbl.frame.origin.x += 1
        }
    }
    
    func animBlack(timer: Timer) {
        
        if self.blackLbl.frame.width >= self.view.frame.width {
            self.blackLbl.textColor = self.view.backgroundColor
            self.whiteLbl.isHidden = true
            timer.invalidate()
            let _ = Afte.r(0.5, seconds: { (timer) in
                self.menu.view.isHidden = false
                self.view.bringSubview(toFront: self.menu.view)
            })
        } else {
            self.blackLbl.frame.size.width += 1
            self.blackLbl.frame.origin.x -= 1
            
            self.whiteLbl.frame.origin.x -= 1
        }
    }
}
