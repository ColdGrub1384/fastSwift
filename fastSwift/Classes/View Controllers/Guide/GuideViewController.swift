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
        
        let sections = AppViewControllers().guide
        sections.titlePage = "Sections"
        sections.text = "Scroll to the left or to the right to switch section"
        sections.gif = "menu"
        
        let browser = AppViewControllers().guide
        browser.titlePage = "File Browser"
        browser.text = "The file browser is the first section in fastSwift.\nYou can create and open Swift files."
        browser.image = #imageLiteral(resourceName: "file browser.jpeg")
        
        let editor = AppViewControllers().guide
        editor.titlePage = "Code editor"
        editor.text = "When you open a file from the file browser, a code editor is opened. You can write code. You can also work with multiple files clicking the \"+\" button and adding a file. Switch file clicking in the organizer button. You can compile code clicking the hammer. The current opened file will be compiled as main file and other files can only declare variables, functions, classes etc. When you compile, a 🐧 is spended and a terminal is opened with the output code."
        editor.gif = "editor"
        
        let editorFeatures = AppViewControllers().guide
        editorFeatures.titlePage = "Editor features"
        editorFeatures.text = ""
        editorFeatures.gif = "editor features"
        editorFeatures.text = "In the code editor, there are two tool bars, buttons are shortcuts. Scroll tool bars to see more shortcuts.\nAlso, when you put: '{', '\"', '(' or '[', the editor auto complete it and puts the cursor the middle."
        
        let shop = AppViewControllers().guide
        shop.titlePage = "Shop"
        shop.text = "If you scroll to the right, in the shop you can buy 🐧, download programs coded with fastSwift by other persons and play challenges."
        shop.gif = "shop"
        
        let challenges = AppViewControllers().guide
        challenges.titlePage = "Challenges"
        challenges.text = "In the shop, if you scroll down, you can play challenges.\nYou need a fastSwift account.\nWhen you play a challenge you have to write the program that the challenge says. When you complete a challenge at first attempt, you earn points (not 🐧)."
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
