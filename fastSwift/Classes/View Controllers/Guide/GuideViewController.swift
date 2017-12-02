//
//  Guide.swift
//  fastSwift
//
//  Created by Adrian on 31.10.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class GuideViewController: UIViewController {
    
    @IBOutlet weak var pageTitle: UILabel!
    @IBOutlet weak var screenshotView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var nextbtn: UIButton!
    @IBOutlet weak var loading: UILabel!
    
    var image: UIImage?
    var gif: String?
    var titlePage = ""
    var text = ""
    var willBePresented = false
    
    
    // -------------------------------------------------------------------------
    // MARK: Static values
    // -------------------------------------------------------------------------
    
    private static var sharedVC = UIViewController()

    static func initPages() {
        if pages != nil {
            return
        }
        
        let sections = AppViewControllers().guide(withPage: Strings.Guides.sections)
        sections.gif = "menu"
        
        let browser = AppViewControllers().guide(withPage: Strings.Guides.browser)
        browser.image = #imageLiteral(resourceName: "file browser.jpeg")
        
        let editor = AppViewControllers().guide(withPage: Strings.Guides.editor)
        editor.gif = "editor"
        
        let editorFeatures = AppViewControllers().guide(withPage: Strings.Guides.editorFeatures)
        editorFeatures.gif = "editor features"
        
        let shop = AppViewControllers().guide(withPage: Strings.Guides.shop)
        shop.gif = "shop"
        
        let challenges = AppViewControllers().guide(withPage: Strings.Guides.challlenges)
        challenges.gif = "challenges"
        
        let guides = [sections, browser, editor, editorFeatures, shop, challenges]
        
        for guide in guides {
            guide.modalPresentationStyle = .overCurrentContext
            guide.willBePresented = false
            
            sharedVC.addChildViewController(guide)
            sharedVC.view.addSubview(guide.view)
        }
        
        pages = guides
    }
    
    static var pages: [GuideViewController]!
    
    static var index = 0
    
    
    // -------------------------------------------------------------------------
    // MARK: Guide loading
    // -------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !willBePresented {
            
            pageTitle.textColor = Theme.current.textColor
            textView.textColor = Theme.current.textColor
            loading.textColor = Theme.current.textColor
            view.tintColor = Theme.current.tintColor
            nextbtn.layer.cornerRadius = 8
            nextbtn.layer.borderWidth = 1
            nextbtn.backgroundColor = Theme.current.color
            nextbtn.layer.borderColor = nextbtn.backgroundColor?.cgColor
            
            
            if let image = image { // Load image
                screenshotView.image = image
            }
            
            if let gif = gif { // Load gif
                screenshotView.loadGif(name: gif)
            }
            
            
            pageTitle.text = titlePage
            textView.text = text
            view.isOpaque = false
            
            willBePresented = true
            view.removeFromSuperview()
            removeFromParentViewController()
        }
        
        
    }
    
    @IBAction func next(_ sender: Any) {
        GuideViewController.index += 1
        print("Clicked button")
        print(GuideViewController.pages)
        view = nil
        self.dismiss(animated: true) {
            print("Dismissed")
            if let vc = AppDelegate.shared.window?.rootViewController {
                print("vc is not nil")
                if GuideViewController.pages.count > GuideViewController.index {
                    print("There is another page to show")
                    
                    let guide = GuideViewController.pages[GuideViewController.index]
                    guide.removeFromParentViewController()
                    guide.view.removeFromSuperview()
                    vc.present(guide, animated: false, completion: nil)
                } else {
                    UserDefaults.standard.set(true, forKey: "launched")
                }
            }
        }
    }
    
}
