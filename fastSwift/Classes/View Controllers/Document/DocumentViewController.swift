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

class DocumentViewController: UIViewController, UIDocumentPickerDelegate, UIPopoverPresentationControllerDelegate, DocumentDelegate, UITextViewDelegate {
    
    var document: Document?
    
    @IBOutlet weak var titleBar: UINavigationBar!
    @IBOutlet weak var code: UITextView!
    @IBOutlet weak var dismissKeyboard: UIBarButtonItem!
    
    var files = [URL]()
    
    @IBOutlet weak var compilations: UIBarButtonItem!
    @IBOutlet weak var organizeBTN: UIBarButtonItem!
    @IBOutlet weak var compileBTN: UIBarButtonItem!
    
    @IBOutlet weak var toolbar: UIToolbar!
    
    
    var firstLaunch = false
    
    var autoCompilationState = AppDelegate.autoCompilationState.none
    
    var range: NSRange?
    var cursorPos: UITextRange?
    
    var pause = false
    
    var timer = Timer()
    
    var closedKeys = true
    
    var challenge: Challenge?
    
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            if url != files.first {
                if url.pathExtension == "swift" {
                    files.append(url)
                }
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: UIViewController
    // -------------------------------------------------------------------------
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        if firstLaunch {
            return .fullScreen
        } else {
            return .none
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.code.delegate = self
        
        print("State: \(autoCompilationState)")
        
        if firstLaunch {
            if files.count >= 2 {
                browser(self)
            } else {
                firstLaunch = false
            }
        }
        
        compileBTN.isEnabled = (AccountManager.shared.compilations.amount != 0 || AccountManager.shared.compilations.type == .infinite)
        
        compilations.title = "\(AccountManager.shared.compilations.description) 🐧"
        
        if autoCompilationState == .ready {
            autoCompilationState = .compiled
            Compile(self)
        } else if autoCompilationState == .compiled {
            self.dismiss(animated: true, completion: nil)
        }
        
        DispatchQueue.main.async {
            let _ = Repea.t(all: 0.2) { (timer) in
                self.timer = timer
                if self.code.isFirstResponder {
                    if self.pause {
                        // Syntax highlighting
                        self.range = self.code.selectedRange
                        self.cursorPos = self.code.selectedTextRange
                        
                        self.code.attributedText = self.highlight("swift", code: self.code.text)
                        self.code.selectedTextRange = self.cursorPos
                        self.code.scrollRangeToVisible(self.range!)
                    }
                    
                    self.pause = true
                }
            }
        }

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.timer.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        view.tintColor = AppDelegate.shared.theme.tintColor
        titleBar.barStyle = AppDelegate.shared.theme.barStyle
        titleBar.barTintColor = AppDelegate.shared.theme.color
        view.backgroundColor = AppDelegate.shared.theme.color
        toolbar.barTintColor = AppDelegate.shared.theme.color
        
        CodeToolBar()
        dismissKeyboard.isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        document?.delegate = self
        
        code.backgroundColor = AppDelegate.shared.theme.codeEditorTheme.backgroundColor
        code.keyboardAppearance = AppDelegate.shared.theme.keyboardAppearance
        
        // Access the document
        if document != nil {
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
        } else if challenge != nil { // Init from challenge
            titleBar.topItem?.title = challenge?.name
            code.text = challenge!.code+"\n\n"
            code.attributedText = self.highlight("swift", code: self.code.text)
            
            compilations.isEnabled = false
            
            let compile = toolbar.items?.first
            toolbar.setItems([compile!], animated: true)
        }
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppDelegate.shared.theme.statusBarStyle
    }
    
    func highlight(_ language:String, code:String) -> NSAttributedString? {
        
        let lang = language.lowercased()
        
        let highlightr = Highlightr()
        highlightr?.setTheme(to: AppDelegate.shared.theme.codeEditorTheme.name)
        
        self.code.autocorrectionType = .no
        self.code.autocapitalizationType = .none
        
        return highlightr?.highlight(code, as: lang.lowercased(), fastRender: true)
    }
    
    // -------------------------------------------------------------------------
    // MARK: TextView insertions
    // -------------------------------------------------------------------------
    
    func CodeToolBar() {
        
        func items(from strings: [String], separator: String) -> [UIBarButtonItem] {
            var items = [UIBarButtonItem]()
            for string in strings {
                let button = UIButton()
                button.setTitle("\(string)", for: .normal)
                button.addTarget(self, action: #selector(insertText(sender:)), for: UIControlEvents.touchUpInside)
                button.setTitleColor(self.view.tintColor, for: .normal)
                if AppDelegate.shared.theme.keyboardAppearance == .dark {
                    button.backgroundColor = .black
                } else {
                    button.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
                }
                
                button.layer.cornerRadius = 5
                button.layer.borderWidth = 1
                button.layer.borderColor = button.backgroundColor?.cgColor
                button.backgroundColor = .clear
                
                let item = UIBarButtonItem(customView: button)
                items.append(item)
                
                if separator != "" {
                    items.append(UIBarButtonItem.init(title: separator, style: .plain, target: nil, action: nil))
                }
            }
            
            return items
        }
        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width*2, height: 50))
        toolbar.items = items(from: ["(",")","{","}","\\", "/","\"","[","]","!","?","!","&","|","="], separator: "  ")
        toolbar.barTintColor = self.view.backgroundColor
        
        let toolbar2 = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width*2, height: 50))
        toolbar2.items = items(from: ["↹","print","var","let","func","if","else", "else if","readLine","readPass","formatted text"], separator: " ")
        toolbar2.barTintColor = self.view.backgroundColor
        
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        scrollView.addSubview(toolbar)
        scrollView.contentSize = toolbar.frame.size
        
        let scrollView2 = UIScrollView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        scrollView2.addSubview(toolbar2)
        scrollView2.contentSize = toolbar.frame.size
        
        let inputAccessoryView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 100))
        inputAccessoryView.backgroundColor = self.view.backgroundColor
        inputAccessoryView.addSubview(scrollView)
        inputAccessoryView.addSubview(scrollView2)
        scrollView.frame.origin.y = scrollView.frame.origin.y+50
        
        self.code.inputAccessoryView = inputAccessoryView
    }
    
    
    @objc func insertText(sender: UIButton) {
        
        var continue_ = true
        
        var text = sender.title(for: .normal)!.replacingOccurrences(of: " ", with: "")
        if text.contains("↹") { // Tab
            text = text.replacingOccurrences(of: "↹", with: "    ")
        } else if text == "print" { // print
            text = "print("
            let _ = self.textView(self.code, shouldChangeTextIn: self.code.selectedRange, replacementText: text)
        } else if text == "\"." {
            text = "\""
        } else if text == "func" { // Function
            continue_ = false
            
            let alert = UIAlertController(title: "Declare a function", message: "Type the function's name and paramaters (separated by \",\")", preferredStyle: .alert)
            alert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "Function's name"
            })
            
            alert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "Parameters (Optional)"
            })
            
            alert.addAction(UIAlertAction.init(title: "Create", style: .default, handler: { (action) in
                let name = alert.textFields![0].text!
                let params = alert.textFields![1].text!
                self.code.replace(self.code.selectedTextRange!, withText: "func \(name)(\(params)) ")
                self.code.replace(self.code.selectedTextRange!, withText: "{")
                let range = self.code.selectedTextRange!
                self.code.replace(self.code.selectedTextRange!, withText: "}")
                self.code.selectedTextRange = range
            }))
            alert.addAction(AlertManager.shared.cancel)
            
            alert.view.tintColor = AppDelegate.shared.theme.tintColor
            
            self.present(alert, animated: true, completion: nil)
        } else if text == "else" { // else
            continue_ = false
            
            self.code.replace(self.code.selectedTextRange!, withText: "else ")
            self.code.replace(self.code.selectedTextRange!, withText: "{")
            let range = self.code.selectedTextRange!
            self.code.replace(self.code.selectedTextRange!, withText: "}")
            self.code.selectedTextRange = range
        } else if text == "if" { // if
            
            continue_ = false
            
            let alert = UIAlertController(title: "If", message: "Type the condition", preferredStyle: .alert)
            alert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "Condition"
            })
            
            alert.addAction(UIAlertAction.init(title: "Add", style: .default, handler: { (action) in
                let condition = alert.textFields![0].text!
                self.code.replace(self.code.selectedTextRange!, withText: "if \(condition) ")
                self.code.replace(self.code.selectedTextRange!, withText: "{")
                let range = self.code.selectedTextRange!
                self.code.replace(self.code.selectedTextRange!, withText: "}")
                self.code.selectedTextRange = range
            }))
            alert.addAction(AlertManager.shared.cancel)
            
            alert.view.tintColor = AppDelegate.shared.theme.tintColor
            
            self.present(alert, animated: true, completion: nil)
        } else if text == "elseif" { // else if
            
            continue_ = false
            
            let alert = UIAlertController(title: "Else if", message: "Type the condition", preferredStyle: .alert)
            alert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "Condition"
            })
            
            alert.addAction(UIAlertAction.init(title: "Add", style: .default, handler: { (action) in
                let condition = alert.textFields![0].text!
                self.code.replace(self.code.selectedTextRange!, withText: "else if \(condition) ")
                self.code.replace(self.code.selectedTextRange!, withText: "{")
                let range = self.code.selectedTextRange!
                self.code.replace(self.code.selectedTextRange!, withText: "}")
                self.code.selectedTextRange = range
            }))
            alert.addAction(AlertManager.shared.cancel)
            
            alert.view.tintColor = AppDelegate.shared.theme.tintColor
            
            self.present(alert, animated: true, completion: nil)
        } else if text == "readLine" { // readLine
            text = "readLine()!"
        } else if text == "readPass" {
            text = "FFKit.readPass()!"
        } else if text == "formattedtext" {
            continue_ = false
            
            let alert = UIAlertController(title: "Formatted Text", message: "Type text and attributes, a variable will be created with typed text and attributes that can be printed", preferredStyle: .alert)
            alert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "Text to be formatted"
            })
            
            alert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "Attributes"
                textField.isEnabled = false
            })
            
            alert.addAction(UIAlertAction.init(title: "Add attribute", style: .default, handler: { (action) in
                let formatting = ["bold", "dim", "underlined", "inverted", "hidden"]
                let foregroundColors = ["red", "green", "yellow", "blue", "magenta", "cyan", "lightGray", "darkGray"]
                let backgroundColors = ["default", "red", "green", "yellow", "blue", "magenta", "cyan", "lightGray", "darkGray", "white"]
                
                let add = UIAlertController(title: "Add attribute", message: nil, preferredStyle: .alert)
                
                
                add.addAction(UIAlertAction(title: "Formatting", style: .default, handler: { (action) in
                    let alert_ = UIAlertController(title: "Formatting", message: nil, preferredStyle: .alert)
                    alert_.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                        self.present(alert, animated: true, completion: nil)
                    }))
                    
                    alert_.view.tintColor = AppDelegate.shared.theme.tintColor
                    
                    for formatting_ in formatting {
                        alert_.addAction(UIAlertAction(title: formatting_, style: .default, handler: { (action) in
                            alert.textFields![1].text = alert.textFields![1].text!+"\(formatting_) "
                            
                            self.present(alert, animated: true, completion: nil)
                        }))
                    }
                    
                    self.present(alert_, animated: true, completion: nil)
                }))
                
                add.addAction(UIAlertAction(title: "Font color", style: .default, handler: { (action) in
                    let alert_ = UIAlertController(title: "Font color", message: nil, preferredStyle: .alert)
                    alert_.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                        self.present(alert, animated: true, completion: nil)
                    }))
                    
                    alert_.view.tintColor = AppDelegate.shared.theme.tintColor
                    
                    for color in foregroundColors {
                        alert_.addAction(UIAlertAction(title: color, style: .default, handler: { (action) in
                            alert.textFields![1].text = alert.textFields![1].text!+"\(color) "
                            
                            self.present(alert, animated: true, completion: nil)
                        }))
                    }
                    
                    self.present(alert_, animated: true, completion: nil)
                }))
                
                add.addAction(UIAlertAction(title: "Background color", style: .default, handler: { (action) in
                    let alert_ = UIAlertController(title: "Background color", message: nil, preferredStyle: .alert)
                    alert_.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                        self.present(alert, animated: true, completion: nil)
                    }))
                    
                    alert_.view.tintColor = AppDelegate.shared.theme.tintColor
                    
                    for color in backgroundColors {
                        alert_.addAction(UIAlertAction(title: color, style: .default, handler: { (action) in
                            alert.textFields![1].text = alert.textFields![1].text!+"\(color)Bak "
                            
                            self.present(alert, animated: true, completion: nil)
                        }))
                    }
                    
                    self.present(alert_, animated: true, completion: nil)
                }))
                
                add.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                    self.present(alert, animated: true, completion: nil)
                }))
                
                add.view.tintColor = alert.view.tintColor
                
                self.present(add, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Remove attribute", style: .default, handler: { (action) in
                let alert_ = UIAlertController(title: "Remove attribute", message: nil, preferredStyle: .alert)
                let attrs = alert.textFields![1].text!
                let attrs_ = attrs.components(separatedBy: " ")
                
                for attr in attrs_ {
                    if attr != "" {
                        alert_.addAction(UIAlertAction(title: attr, style: .default, handler: { (action) in
                            let textfield = alert.textFields![1]
                            textfield.text = textfield.text?.replacingOccurrences(of: attr+" ", with: "")
                            
                            self.present(alert, animated: true, completion: nil)
                        }))
                    }
                }
                
                alert_.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                    self.present(alert, animated: true, completion: nil)
                }))
                
                alert_.view.tintColor = alert.view.tintColor
                
                self.present(alert_, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { (action) in
                let attrs = alert.textFields![1].text!
                let text = alert.textFields![0].text!
                let attributes_ = attrs.components(separatedBy: " ")
                var attributes = [String]()
                
                for attribute in attributes_{
                    if attribute.replacingOccurrences(of: " ", with: "") != "" {
                        let newAttr = ".\(attribute)"
                        attributes.append(newAttr)
                    }
                    
                }
                
                let code = "FFKit.text(\"\(text)\", withAttributes:[\(attributes.joined(separator: ","))])"
                self.code.replace(self.code.selectedTextRange!, withText: code)
            }))
            alert.addAction(AlertManager.shared.cancel)
            
            alert.view.tintColor = AppDelegate.shared.theme.tintColor
            
            self.present(alert, animated: true, completion: nil)
        } else if text == "var" || text == "let" {
            text = text+" "
        } else {
            let _ = self.textView(self.code, shouldChangeTextIn: self.code.selectedRange, replacementText: text)
        }
        
        if continue_ {
             self.code.replace(self.code.selectedTextRange!, withText: text)
        }
    }
    
    func insert(text: String, withSpaces spaces: Bool = false) {
        let button = UIButton()
        button.setTitle(text, for: .normal)
        
        if spaces {
            self.code.replace(self.code.selectedTextRange!, withText: text)
            return
        }
        
        insertText(sender: button)
    }

    // -------------------------------------------------------------------------
    // MARK: Keyboard
    // -------------------------------------------------------------------------
    
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
    
    // -------------------------------------------------------------------------
    // MARK: Compile
    // -------------------------------------------------------------------------
    
    func checkCode() { // Check if code is correct for challenge
        if let codeForParams = self.code.text.addingPercentEncodingForURLQueryValue() {
            let url = URL(string:"http://\(Server.default.host)/challenges.php?username=\(AccountManager.shared.username!.addingPercentEncodingForURLQueryValue()!)&code=\(codeForParams)&challenge=\(self.challenge!.name.addingPercentEncodingForURLQueryValue()!)&password=\(AccountManager.shared.password!.addingPercentEncodingForURLQueryValue()!)")! // URL to check code
            
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                if let error = error {
                    AlertManager.shared.present(error: error, withTitle: "Error sending request", inside: self)
                } else {
                    if let data = data {
                        if let str = String(data: data, encoding: .utf8) {
                            let win = (str.slice(from: "Result(", to: ")")! == "1")
                            if let output = str.slice(from: "Output(", to: ")") {
                                var textToShow = ""
                                if win { // User won the challenge
                                    textToShow = "You completed the challenge!\nThe output was:\n \(output)"
                                } else {
                                    textToShow = "You code is incorrect, retry\nThe output was:\n \(output)"
                                }
                                
                                let alert = UIAlertController(title: "Results", message: textToShow, preferredStyle: .alert)

                                if win {
                                    alert.addAction(AlertManager.shared.ok(handler: { (action) in
                                        self.dismiss(animated: true, completion: {
                                            if let points = str.slice(from: "EarnPoints(", to: ")") {
                                                if let vc = AppDelegate.shared.window?.rootViewController {
                                                    AlertManager.shared.presentAlert(withTitle: "You earned \(points) points!", message: "Congrulations! You completed the challenge the first time!", style: .alert, actions: [AlertManager.shared.ok(handler: nil)], inside: vc, animated: true, completion: nil)
                                                }
                                            }
                                        })
                                    }))
                                } else {
                                    alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: nil))
                                }
                                
                                alert.view.tintColor = AppDelegate.shared.theme.tintColor
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }).resume()
        }
    }
    
    @IBAction func Compile(_ sender: Any) { // Send code
        
        if challenge != nil {
            // Send challenge
            checkCode()
            return
        }
        
        var additionalCommand = ""
        
        do {
            try self.code.text.write(to: (self.document?.fileURL)!, atomically: true, encoding: String.Encoding.utf8)
        } catch let error {
            AlertManager.shared.present(error: error, withTitle: "Error saving file!", inside: self)
        }
        print(files)
        
        if let _ = sender as? Bool {
            additionalCommand = "downloadExecutable"
        }
        
        let alert = ActivityViewController(message: "Uploading...")
        self.present(alert, animated: true, completion: nil)
        
        DispatchQueue.global(qos: .background).async {
            let session = NMSSHSession.connect(toHost: Server.host, withUsername: Server.user)
            
            if (session?.isConnected)! {
                session?.authenticate(byPassword: Server.password)
                
                if (session?.isAuthorized)! {
                    
                    // Spend compilation
                    if let _ = sender as? Bool {} else {
                        AccountManager.shared.compilations.substract(1)
                        self.compilations.title = "\(AccountManager.shared.compilations.description) 🐧"
                    }
                    
                    print("Authorized session!")
                    
                    do {
                        // Create unique folder
                        try session?.channel.execute("rm -rf \((UIDevice.current.identifierForVendor!.uuidString))")
                        try session?.channel.execute("mkdir '\((UIDevice.current.identifierForVendor!.uuidString))'")
                        try session?.channel.execute("cp /home/fastswift/FFKit.swift '\((UIDevice.current.identifierForVendor!.uuidString))'")
                        
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
                                                
                        DispatchQueue.main.sync { // Compile code and run it
                            self.dismiss(animated: true, completion: {
                                
                                if additionalCommand != "" {
                                    additionalCommand += ";"
                                }
                                
                                let terminal = AppViewControllers().terminal
                                let secondPart = "./main; cd ~; rm -rf \((UIDevice.current.identifierForVendor!.uuidString)); logout"
                                terminal.command = "cd '\((UIDevice.current.identifierForVendor!.uuidString))'; mv '\(self.document!.fileURL.lastPathComponent)' main.swift; swiftc *; touch screenSize; echo \"\(UIScreen.main.bounds.width)\" >> screenSize; echo \"\(UIScreen.main.bounds.height)\" >> screenSize; \(additionalCommand)"
                                print(terminal.command)
                                terminal.host = Server.host
                                terminal.user = Server.user
                                terminal.password = Server.password
                                terminal.mainFile = self.document!.fileURL.deletingPathExtension().lastPathComponent
                                terminal.delegate = self
                                
                                if additionalCommand == "" {
                                    terminal.command = terminal.command+secondPart
                                }
                                
                                if let _ = sender as? Bool {
                                    terminal.downloadExec = true
                                }
                                
                                self.present(terminal, animated:true, completion: nil)
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
                        self.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                    })
                    
                }
            } else {
                self.dismiss(animated: true, completion: {
                    self.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                })
            }
        }
        
        
    }
    
    // -------------------------------------------------------------------------
    // MARK: Buttons
    // -------------------------------------------------------------------------
    
    @IBAction func copyText(_ sender: Any) {
        guard let selected = self.code.selectedTextRange else { return }
        guard let text = self.code.text(in: selected) else { return }
        
        UIPasteboard.general.string = text
    }
    
    @IBAction func pasteText(_ sender: Any) {
        if let text = UIPasteboard.general.string {
            self.insert(text: text, withSpaces: true)
        }
    }
    
    @IBAction func dismissDocumentViewController() {
        
        if challenge != nil { // Is a challenge
            self.dismiss(animated: true, completion: nil)
        }
        
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
        let vc = AppViewControllers().organizer
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .popover
        nav.navigationBar.prefersLargeTitles = true
        nav.navigationBar.barTintColor = self.titleBar.barTintColor
        nav.navigationBar.barStyle = AppDelegate.shared.theme.barStyle
        vc.delegate = self
        
        
        let popover = nav.popoverPresentationController
        vc.preferredContentSize = CGSize(width: 300, height: 300)
        popover?.delegate = self
        popover?.barButtonItem = organizeBTN
        popover?.sourceRect = CGRect(x: 100, y: 100, width: 0, height: 0)
        
        self.present(nav, animated: true, completion: nil)
    }
    
    @IBAction func buyCompilations(_ sender: Any) {
        if AppDelegate.shared.menu.loadedStore {
            let store = AppViewControllers().store
            self.present(store, animated: true, completion: nil)
        } else {
            let errorVc = AppViewControllers().errorLoadingStore
            if code.text.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "") != document?.code.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "") {
                errorVc.isSaved = false
            }
            
            errorVc.delegate = self
            self.present(errorVc, animated: true, completion: nil)
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: UITextViewDelegate
    // -------------------------------------------------------------------------
    
    func textViewDidChange(_ textView: UITextView) {
        self.pause = false
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let position = textView.selectedTextRange!.start
        
        
        print("Autocompletion: \(text)")
        
        if textView.text.occurrences(of: "{") == self.code.text.occurrences(of: "}") { // Check if there are the same count of { and }
            self.closedKeys = true
        } else {
            self.closedKeys = false
        }
        
        
        if text == "\"" {
            print("Quotes detected!")
            self.insert(text: "\".")
            textView.selectedRange = range
        }
    
        if text == "{" {
            print("Key detected!")
            if self.closedKeys {
                self.insert(text: "}")
                textView.selectedRange = range
            }
        }
        
        
        if text == "[" {
            print("Bracket detected!")
            self.insert(text: "]")
            textView.selectedRange = range
        }
        
        if text == "(" {
            print("Parenthesis detected!")
            self.insert(text: ")")
            textView.selectedRange = range
        }
        
        if text == "print(" {
            self.insert(text: ")")
            textView.selectedRange = range
        }
        
        if text == "\n" {
            let line = textView.tokenizer.position(from: position, toBoundary: .line, inDirection: UITextStorageDirection.backward.rawValue)
            let lineRange = textView.tokenizer.rangeEnclosingPosition(line!, with: .line, inDirection: UITextStorageDirection.backward.rawValue)
            let lineText = textView.text(in: lineRange!)
            
            var afterCursor = ""
            if let afterCursor_ = self.code.afterCursor {
                afterCursor = afterCursor_
                print("After cursor: \(afterCursor_)")
            }
            
            if let _ = lineText {
                print(lineText!)
                if lineText!.hasSuffix("}") && afterCursor == "}" { // Indent
                    
                    var lineText_ = lineText!
                    // Detect tabs (4 spaces)
                    var spacesNumbers = 0
                    while lineText_.hasPrefix(" ") {
                        spacesNumbers += 1
                        lineText_ = String(lineText_.dropFirst())
                    }
                    
                    print(spacesNumbers)
                    
                    let tabsNumbers = spacesNumbers/4
                    
                    
                    var count = 0
                    var tabs = "↹"
                    
                    while count < tabsNumbers {
                        tabs = tabs+"↹"
                        count += 1
                    }
                    
                    let cursor = textView.selectedTextRange!
                    self.insert(text: "\(tabs.replacingFirstOccurrence(of: "↹", with: ""))")
                    textView.selectedTextRange = cursor
                    self.insert(text: "\n\(tabs)")
                    let range = textView.selectedTextRange
                    _ = Afte.r(0.1, seconds: { (timer) in
                        textView.selectedTextRange = range
                    })
                    
                }
            }
            
        }
        
        
        
        return true
    }
    
    // -------------------------------------------------------------------------
    // MARK: DocumentDelegate
    // -------------------------------------------------------------------------
    
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
}

