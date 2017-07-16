//
//  DocumentViewController.swift
//  fastSwift
//
//  Created by Adrian on 10.06.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import Highlightr
import NMSSH

class DocumentViewController: UIViewController, UIDocumentPickerDelegate, UIPopoverPresentationControllerDelegate, DocumentDelegate {
    
    func document(didClose document: Document) {
        print("\(document.fileURL.deletingPathExtension().lastPathComponent) closed!")
        for file in files {
            if file != document.fileURL {
                let document = Document(fileURL: file)
                document.close(completionHandler: nil)
            }
        }
    }
    
    func document(_ document: Document, didLoadContents contents: String) {
        print("Returned content for \(document.fileURL.deletingPathExtension().lastPathComponent): \(contents)")
    }
    
    func document(willOpen document: Document) {
        print("\(document.fileURL.deletingPathExtension().lastPathComponent) will be opened!")
    }
    
    func document(_ document: Document, didLoadContentsWithError error: Error) {
        print("Error returning content for \(document.fileURL.deletingPathExtension().lastPathComponent): \(error.localizedDescription)")
    }
    
    
    var document: Document?
    
    @IBOutlet weak var titleBar: UINavigationBar!
    @IBOutlet weak var code: UITextView!
    
    @IBOutlet weak var dismissKeyboard: UIBarButtonItem!
    
    var files = [URL]()
    
    @IBOutlet weak var compilations: UIBarButtonItem!
    
    
    @IBOutlet weak var organizeBTN: UIBarButtonItem!
    
    @IBOutlet weak var compileBTN: UIBarButtonItem!
    
    var firstLaunch = false
    
    var autoCompilationState = AppDelegate.autoCompilationState.none
    
    
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            if url != files.first {
                if url.pathExtension == "swift" {
                    files.append(url)
                }
            }
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        if firstLaunch {
            return .fullScreen
        } else {
            return .none
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        print("State: \(autoCompilationState)")
        
        if firstLaunch {
            if files.count >= 2 {
                browser(self)
            } else {
                firstLaunch = false
            }
        }
        
        if AccountManager.shared.compilations != 0 {
            compileBTN.isEnabled = true
        } else {
            compileBTN.isEnabled = false
        }
        
        compilations.title = "\(AccountManager.shared.compilations) 🐧"
        
        if autoCompilationState == .ready {
            autoCompilationState = .compiled
            Compile(self)
        } else if autoCompilationState == .compiled {
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        self.view.tintColor = .orange
        
        CodeToolBar()
        dismissKeyboard.isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        document?.delegate = self
        
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                // Display the content of the document, e.g.:
                self.code.text = self.document?.code
                self.titleBar.topItem?.title = self.document?.fileURL.deletingPathExtension().lastPathComponent
                
                self.code.attributedText = self.highlight("swift", code: self.code.text)
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
        
        
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { (timer) in
            let cursorPos = self.code.selectedTextRange
            self.code.attributedText = self.highlight("swift", code: self.code.text)
            self.code.selectedTextRange = cursorPos
        }
        
    }
    
    @IBAction func dismissDocumentViewController() {
        
        code.resignFirstResponder()
        
        if code.text.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "") != document?.code.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "") {
            AlertManager.shared.presentAlert(withTitle: "Do you want to save the file", message: "If you select \"Don't save\", all changes will be erased!", style: .alert, actions:
                [
                    UIAlertAction.init(title: "Don't save", style: .destructive, handler: { (action) in
                        self.dismiss(animated: true, completion: {
                            self.document?.close(completionHandler: nil)
                        })
                    }),
                    UIAlertAction.init(title: "Save", style: .default, handler: { (action) in
                        self.dismiss(animated: true, completion: {
                            do {
                                try self.code.text.write(to: (self.document?.fileURL)!, atomically: true, encoding: String.Encoding.utf8)
                            } catch let error {
                                AlertManager.shared.present(error: error, withTitle: "Error saving file!", inside: self)
                            }
                            self.document?.close(completionHandler: nil)
                        })
                    }),
                    AlertManager.shared.cancel
                ]
                , inside: self, animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: {
                self.document?.close(completionHandler: nil)
            })
        }
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func highlight(_ language:String, code:String) -> NSAttributedString? {
        
        let lang = language.lowercased()
        
        let highlightr = Highlightr()
        highlightr?.setTheme(to: "androidstudio")
        
        self.code.autocorrectionType = .no
        self.code.autocapitalizationType = .none
        
        return highlightr?.highlight(code, as: lang.lowercased(), fastRender: true)
    }
    
    
    func CodeToolBar() {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        let toolbar2 = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        
        var items = [UIBarButtonItem]()
        items.append(UIBarButtonItem(title: "( ", style: .done, target: self, action: #selector(insertText(sender:)))) // (
        items.append(UIBarButtonItem(title: ") ", style: .done, target: self, action: #selector(insertText(sender:)))) // )
        
        items.append(UIBarButtonItem(title: "  ", style: .done, target: self, action: nil))
        
        items.append(UIBarButtonItem(title: "{ ", style: .done, target: self, action: #selector(insertText(sender:)))) // {
        items.append(UIBarButtonItem(title: "} ", style: .done, target: self, action: #selector(insertText(sender:)))) // }
        
        items.append(UIBarButtonItem(title: "  ", style: .done, target: self, action: nil))
        
        items.append(UIBarButtonItem(title: "\\ ", style: .done, target: self, action: #selector(insertText(sender:)))) // \
        items.append(UIBarButtonItem(title: "/ ", style: .done, target: self, action: #selector(insertText(sender:)))) // /
        
        items.append(UIBarButtonItem(title: "  ", style: .done, target: self, action: nil))
        
        items.append(UIBarButtonItem(title: "\" ", style: .done, target: self, action: #selector(insertText(sender:)))) // "
        
        items.append(UIBarButtonItem(title: "  ", style: .done, target: self, action: nil))
        
        items.append(UIBarButtonItem(title: "[ ", style: .done, target: self, action: #selector(insertText(sender:)))) // [
        items.append(UIBarButtonItem(title: "] ", style: .done, target: self, action: #selector(insertText(sender:)))) // ]
        
        items.append(UIBarButtonItem(title: "  ", style: .done, target: self, action: nil))
        
        items.append(UIBarButtonItem(title: "! ", style: .done, target: self, action: #selector(insertText(sender:)))) // !
        items.append(UIBarButtonItem(title: "? ", style: .done, target: self, action: #selector(insertText(sender:)))) // ?
        
        items.append(UIBarButtonItem(title: "  ", style: .done, target: self, action: nil))
        
        items.append(UIBarButtonItem(title: "& ", style: .done, target: self, action: #selector(insertText(sender:)))) // &
        items.append(UIBarButtonItem(title: "| ", style: .done, target: self, action: #selector(insertText(sender:)))) // |
        
        items.append(UIBarButtonItem(title: "  ", style: .done, target: self, action: nil))
        
        items.append(UIBarButtonItem(title: "↹", style: .done, target: self, action: #selector(insertText(sender:)))) // TAB
        
        for item in items {
            let font = UIFont(name: "Helvetica", size: 20)
            
            item.setTitleTextAttributes([NSAttributedStringKey.font.rawValue:font], for: UIControlState.normal)
        }
        
        toolbar.sizeToFit()
        toolbar.items = items
        toolbar.barTintColor = self.view.backgroundColor
        toolbar.tintColor = self.view.tintColor
        
        self.code.inputAccessoryView = toolbar
    }
    
    @objc func insertText(sender: UIBarButtonItem) {
        var text = sender.title!.replacingOccurrences(of: " ", with: "")
        if text == "↹" {
            text = "    "
        }
        self.code.replace(self.code.selectedTextRange!, withText: text)
    }
    
    @IBAction func dismissKeyboard(_ sender: Any) {
        self.code.resignFirstResponder()
        dismissKeyboard.isEnabled = false
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        let d = notification.userInfo!
        var r = d[UIKeyboardFrameEndUserInfoKey] as! CGRect
        
        r = self.code.convert(r, from:nil)
        self.code.contentInset.bottom = r.size.height
        self.code.scrollIndicatorInsets.bottom = r.size.height
        
        dismissKeyboard.isEnabled = true
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        self.code.contentInset = .zero
        self.code.scrollIndicatorInsets = .zero
        
        dismissKeyboard.isEnabled = false
    }
    
    @IBAction func Compile(_ sender: Any) {
        
        do {
            try self.code.text.write(to: (self.document?.fileURL)!, atomically: true, encoding: String.Encoding.utf8)
        } catch let error {
            AlertManager.shared.present(error: error, withTitle: "Error saving file!", inside: self)
        }
        
        print(files)
        
        let alert = ActivityViewController(message: "Uploading...")
        DispatchQueue.global(qos: .background).async {
            self.present(alert, animated: true, completion: nil)
            
            let session = NMSSHSession.connect(toHost: "190.46.99.168", withUsername: "swiftexec")
            
            if (session?.isConnected)! {
                session?.authenticate(byPassword: "swift")
                
                if (session?.isAuthorized)! {
                    
                    AccountManager.shared.compilations = AccountManager.shared.compilations-1
                    self.compilations.title = "\(AccountManager.shared.compilations) 🐧"
                    
                    print("Authorized session!")
                    
                    do {
                        // Create unique folder
                        try session?.channel.execute("rm -rf \((UIDevice.current.identifierForVendor!.uuidString))")
                        try session?.channel.execute("mkdir '\((UIDevice.current.identifierForVendor!.uuidString))'")
                        
                        // Upload files
                        for file in self.files {
                            
                            print("Send: "+file.lastPathComponent)
                            if file != self.document!.fileURL {
                                let document = Document(fileURL: file)
                                
                                document.open(completionHandler: { (success) in
                                    print("File opened!")
                                    if success {
                                        session?.channel.uploadFile(file.path, to: "\((UIDevice.current.identifierForVendor!.uuidString))/\(file.lastPathComponent)")
                                        document.close(completionHandler: nil)
                                    }
                                    
                                })
                                
                            } else {
                                session?.channel.uploadFile(file.path, to: "\((UIDevice.current.identifierForVendor!.uuidString))/\(file.lastPathComponent)")
                            }
                        }
                                                
                        DispatchQueue.main.sync {
                            self.dismiss(animated: true, completion: {
                                self.performSegue(withIdentifier: "swift", sender: nil)
                            })
                        }
                        
                    } catch let error {
                        self.dismiss(animated: true, completion: {
                            AlertManager.shared.present(error: error, withTitle: "Error uploading file!", inside: self)
                        })
                        print("Error uploading file: \(error.localizedDescription)")
                    }
                } else {
                    self.dismiss(animated: true, completion: {
                        self.present(AlertManager.shared.serverErrorViewController, animated: true, completion: nil)
                    })
                    
                }
            } else {
                self.dismiss(animated: true, completion: {
                    self.present(AlertManager.shared.serverErrorViewController, animated: true, completion: nil)
                })
            }
        }
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        print("Prepare for segue")
        
        
        if segue.identifier == "swift" {
            if let nextVC = segue.destination as? NMTerminalViewController {
                nextVC.command = "cd '\((UIDevice.current.identifierForVendor!.uuidString))'; mv '\(self.document!.fileURL.lastPathComponent)' main.swift; swiftc *; ./main; cd ~; rm -rf \((UIDevice.current.identifierForVendor!.uuidString)); logout"
                print(nextVC.command)
                nextVC.host = "190.46.99.168"
                nextVC.user = "swiftexec"
                nextVC.password = "swift"
            }
        }
    }
    
    @IBAction func Templates(_ sender: UIBarButtonItem) {
        
        func setTemplate(_ template: String) {
            self.code.text = template
            let cursorPos = self.code.selectedTextRange
            self.code.attributedText = self.highlight("swift", code: self.code.text)
            self.code.selectedTextRange = cursorPos
            
        }
        
        let alert = AlertManager.shared.alert(withTitle: "Choose a template", message: "", style: .actionSheet, actions: [UIAlertAction.init(title: "Hello World", style: .default, handler: { (alert) in
            setTemplate("""
            //
            //  Swift script
            //  Created by fastSwift
            //


            import Foundation


            // Write code here

            print("Hello World!")

            """)
        }),
                                                                                                                          
          UIAlertAction.init(title: "User input", style: .default, handler: { (alert) in
            setTemplate("""
            //
            //  Swift script
            //  Created by fastSwift
            //


            import Foundation


            // Write code here

            let mainText = ""
            print(mainText)

            var response = readLine()!
            switch response {
            case "1":
                print("User typed 1!")
            default:
                print("Other text")
            }

            """)
      }),
          
          UIAlertAction.init(title: "While loop", style: .default, handler: { (alert) in
            setTemplate("""
            //
            //  Swift script
            //  Created by fastSwift
            //


            import Foundation


            // Write code here

            let mainText = ""
            print(mainText)
            
            main: while true {
                var response = readLine()!
                switch response {
                case "1":
                    print("User typed 1!")
                default:
                    break main
                }
            }

            """)
          }),
          
          UIAlertAction.init(title: "Class", style: .default, handler: { (alert) in
            setTemplate("""
            //
            //  Swift script
            //  Created by fastSwift
            //


            import Foundation

            
            class ClassName {
                // Write code here

            }

            """)
          }),
          
          UIAlertAction.init(title: "Class with superclass", style: .default, handler: { (alert) in
            setTemplate("""
            //
            //  Swift script
            //  Created by fastSwift
            //


            import Foundation

            
            class ClassName: SuperClass {
                // Write code here

            }

            """)
          }),
          
          UIAlertAction.init(title: "Extension", style: .default, handler: { (alert) in
            setTemplate("""
            //
            //  Swift script
            //  Created by fastSwift
            //


            import Foundation

            
            extension ClassName {
                // Write code here

            }

            """)
          })
      ])
        
        alert.popoverPresentationController?.barButtonItem = sender
        alert.addAction(AlertManager.shared.cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func addFile(_ sender: Any) {
        let browser = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .open)
        browser.delegate = self
        browser.allowsMultipleSelection = true
        
        self.present(browser, animated: true, completion: nil)
    }
    
    
    @IBAction func browser(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "manage") as! OrganizerTableViewController
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .popover
        nav.navigationBar.prefersLargeTitles = true
        nav.navigationBar.barTintColor = self.titleBar.barTintColor
        nav.navigationBar.barStyle = .black
        vc.delegate = self
        
        
        let popover = nav.popoverPresentationController
        vc.preferredContentSize = CGSize(width: 300, height: 300)
        popover?.delegate = self
        popover?.barButtonItem = organizeBTN
        popover?.sourceRect = CGRect(x: 100, y: 100, width: 0, height: 0)
        
        self.present(nav, animated: true, completion: nil)
    }
    
    @IBAction func buyCompilations(_ sender: Any) { print("Buy compilation")
    }
    
    

}

