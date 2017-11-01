//
//  NMTerminalViewController.swift
//  fastFiles
//
//  Created by Adrian on 16.04.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import NMSSH
import Zip


class NMTerminalViewController: UIViewController, NMSSHSessionDelegate, NMSSHChannelDelegate, UITextViewDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var terminal: TerminalTextView!
    var session = NMSSHSession()
    var command = ""
    var host = UserDefaults.standard.string(forKey: "IP")
    var user = UserDefaults.standard.string(forKey: "USER")
    var password = UserDefaults.standard.string(forKey: "PASSWORD")
    var project = ""
    var needsUserInput = true
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var navBar: UINavigationBar!
    var mainFile = ""
    var delegate: DocumentViewController?
    var browserVC: DocumentBrowserViewController?
    var console = ""
    var reopen = false
    var consoleHTML = ""
    var plainTerminal = TerminalTextView()
    
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let delegate = browserVC {
            delegate.viewDidAppear(true)
        }
        
    }
    
    var terminalHTML: String {
        return try! String(contentsOfFile: Bundle.main.path(forResource: "terminal", ofType: "html")!).replacingOccurrences(of: "$BACKGROUNDCOLOR", with:"#"+AppDelegate.shared.theme.color.hexString).replacingOccurrences(of: "$TEXTCOLOR", with: "#"+AppDelegate.shared.theme.textColor.hexString)
        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        plainTerminal.isHidden = true
        view.addSubview(plainTerminal)
        terminal.layoutManager.allowsNonContiguousLayout = false
        terminal.isSelectable = false
        terminal.delegate = self
        terminal.isEditable = true
        terminal.keyboardAppearance = AppDelegate.shared.theme.keyboardAppearance
        terminal.tintColor = AppDelegate.shared.theme.textColor
        terminal.text = "\n"
        if needsUserInput {
            terminal.becomeFirstResponder()
        }
        terminal.backgroundColor = AppDelegate.shared.theme.color
        terminal.textColor = terminal.tintColor
        navBar.barStyle = AppDelegate.shared.theme.barStyle
        navBar.barTintColor = AppDelegate.shared.theme.color
        view.backgroundColor = AppDelegate.shared.theme.color
        view.tintColor = AppDelegate.shared.theme.tintColor
        
        plainTerminal.frame = terminal.frame
        plainTerminal.textColor = terminal.textColor
        plainTerminal.backgroundColor = terminal.backgroundColor
        plainTerminal.font = terminal.font
        
        // Update text view size
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
                
        session = NMSSHSession.connect(toHost: host, withUsername: user)
        if (session.isConnected) {
            session.authenticate(byPassword: password)
            if (session.isAuthorized) {
                session.channel.delegate = self
                session.delegate = self
                session.channel.requestSizeWidth(UInt(self.view.frame.size.width), height: UInt(self.view.frame.size.height))
                session.channel.requestPty = true
                
                do {
                    try session.channel.startShell()
                    try session.channel.write("echo Progr\\am output;"+command+"\n")
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
        
        if let item = navBar.items?.first {
            item.title = "Output"
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        terminal.becomeFirstResponder()
    }
    
    @IBAction func disconnect(_ sender: Any) {
        session.disconnect()
        self.dismiss(animated: true, completion: {
            
            if self.reopen {
                AppDelegate.shared.window?.rootViewController = AppViewControllers().launchScreen
                _ = Afte.r(1, seconds: { (timer) in
                    AppDelegate.shared.applicationWillTerminate(UIApplication.shared)
                    _ = AppDelegate.shared.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                })
            }
            
        })
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppDelegate.shared.theme.statusBarStyle
    }
    
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        DispatchQueue.main.async {
                        
            self.consoleHTML = ((self.consoleHTML+message).replacingOccurrences(of: self.terminalHTML, with: "").replacingOccurrences(of: "\n", with: "</br>"))+self.terminalHTML // terminal works with HTML, so replace \n by </br>
            

            self.plainTerminal.isHidden = false
            
            self.terminal.text = self.consoleHTML
            self.plainTerminal.text = self.console
            
            if let html = self.terminal.text.attributedStringFromHTML {
                self.terminal.attributedText = html
            }
            
            self.plainTerminal.isHidden = true
            
            
            print(self.terminal.text)
            
            
            if self.terminal.text.contains("Program output") { // Clear shell
                let newString = self.terminal.text.components(separatedBy: "Program output")
                self.activity.stopAnimating()
                self.terminal.text = newString[1]+self.terminalHTML
                self.consoleHTML = newString[1]+self.terminalHTML
                self.console = self.terminal.text
            }
            
            if self.terminal.text.contains("<showAlert>") { // Show an alert
                if let text = self.terminal.text.slice(from: "<showAlert>", to: "</showAlert>") {
                    if let buttonsStr = text.slice(from: "<buttons>", to: "</buttons>") {
                        let buttons = buttonsStr.components(separatedBy: "<bt>")
                        var actions = [UIAlertAction]()
                        for button in buttons {
                            actions.append(UIAlertAction(title: button, style: .default, handler: { (action) in
                                if self.terminal.isFirstResponder {
                                    do {
                                        try self.session.channel.write(button+"\n")
                                    } catch _ {
                                        self.present(AppViewControllers().connectionError, animated: true, completion: nil)
                                    }
                                }
                            }))
                        }
                        
                        var title = ""
                        
                        if let title_ = text.slice(from: "<title>", to: "</title>") {
                            title = title_
                        }
                        
                        var msg = ""
                        
                        if let msg_ = text.slice(from: "<message>", to: "</message>") {
                            msg = msg_
                        }
                        
                        self.present(AlertManager.shared.alert(withTitle: title, message: msg, style: .alert, actions: actions), animated: true, completion: nil)
                    }
                }
                
                self.terminal.text = self.terminal.text.replacingFirstOccurrence(of: self.terminal.text.slice(from: "<showAlert>", to: "</showAlert>")!, with: "")
                self.terminal.text = self.terminal.text.replacingFirstOccurrence(of: "<showAlert>", with: "")
                self.terminal.text = self.terminal.text.replacingFirstOccurrence(of: "</showAlert>", with: "")
            }
            
            if self.terminal.text.contains("<theme>") {
                if let theme = self.terminal.text.slice(from: "<theme>", to: "</theme>") {
                    let color = theme.slice(from: "<color>", to: "</color>")
                    let tint = theme.slice(from: "<tintColor>", to: "</tintColor>")
                    let textColor = theme.slice(from: "<textColor>", to: "</textColor>")
                    let barStyle = theme.slice(from: "<barStyle>", to: "</barStyle>")
                    let keyboard = theme.slice(from: "<keyboard>", to: "</keyboard>")
                    let statusBar = theme.slice(from: "<statusBarStyle>", to: "</statusBarStyle>")
                    let browserStyle = theme.slice(from: "<browserStyle>", to: "</browserStyle>")
                    let codeEditorBackground = theme.slice(from: "<codeEditorBackground>", to: "</codeEditorBackground>")
                    let codeEditorTheme = theme.slice(from: "<codeEditorTheme>", to: "</codeEditorTheme>")
                    let alternateIcon = theme.slice(from: "<alternateIcon>", to: "</alternateIcon>")
                    
                    self.present(AlertManager.shared.alert(withTitle: "Available theme!", message: "This program want to install a theme", style: .alert, actions: [UIAlertAction.init(title: "Install", style: .default, handler: { (action) in
                        
                        if color != nil {
                            if tint != nil {
                                if textColor != nil {
                                    if barStyle != nil {
                                        if keyboard != nil {
                                            if statusBar != nil {
                                                if browserStyle != nil {
                                                    if codeEditorBackground != nil {
                                                        if codeEditorTheme != nil {
                                                            if alternateIcon != nil {
                                                                UserDefaults.standard.set("custom", forKey: "theme")
                                                                UserDefaults.standard.set(color, forKey: "ct_color")
                                                                UserDefaults.standard.set(tint, forKey: "ct_tint")
                                                                UserDefaults.standard.set(textColor, forKey: "ct_text")
                                                                UserDefaults.standard.set(barStyle, forKey: "ct_bar")
                                                                UserDefaults.standard.set(keyboard, forKey: "ct_keyboard")
                                                                UserDefaults.standard.set(statusBar, forKey: "ct_sbar")
                                                                UserDefaults.standard.set(browserStyle, forKey: "ct_browser")
                                                                UserDefaults.standard.set(codeEditorBackground, forKey: "ct_eback")
                                                                UserDefaults.standard.set(codeEditorTheme, forKey: "ct_etheme")
                                                                UserDefaults.standard.set(alternateIcon, forKey: "ct_icon")
                                                                
                                                                self.reopen = true
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                    }), AlertManager.shared.cancel]), animated: true, completion: nil)
                    
                    self.terminal.text = self.terminal.text.replacingFirstOccurrence(of: self.terminal.text.slice(from: "<theme>", to: "</theme>")!, with: "")
                    self.terminal.text = self.terminal.text.replacingFirstOccurrence(of: "<theme>", with: "")
                    self.terminal.text = self.terminal.text.replacingFirstOccurrence(of: "</theme>", with: "")
                }
                
            }
            
            if self.terminal.text.contains("Show activity") {
                self.activity.startAnimating()
                self.terminal.text = self.terminal.text.replacingOccurrences(of: "Show activity", with: "")
                self.console = self.terminal.text
            }
            
            if self.terminal.text.contains("Hide activity") {
                self.activity.stopAnimating()
                self.terminal.text = self.terminal.text.replacingOccurrences(of: "Hide activity", with: "")
                self.console = self.terminal.text
            }
            
            if self.terminal.text.contains("DownloadBinaryFileNow") {
                let inCurrentVC = self.terminal.text.contains("DownloadBinaryFileNowInCurrentVC")
                self.terminal.text = self.terminal.text.replacingOccurrences(of: "DownloadBinaryFileNow", with: "")
                
                
                self.session.sftp.connect()
                if self.session.sftp.fileExists(atPath: "/home/\(Server.user)/\(UIDevice.current.identifierForVendor!.uuidString)/main") {
                    self.terminal.text = "Downloading executable file..."
                    try! self.session.channel.execute("zip \(UIDevice.current.identifierForVendor!.uuidString)/main.zip \(UIDevice.current.identifierForVendor!.uuidString)/main")
                    let zipFile = self.session.sftp.contents(atPath: "/home/\(Server.user)/\(UIDevice.current.identifierForVendor!.uuidString)/main.zip")
                    
                    let defaultSession = NMSSHSession.connect(toHost: Server.default.host, withUsername: Server.default.user)
                    if defaultSession!.isConnected {
                        defaultSession?.authenticate(byPassword: Server.default.password)
                        if defaultSession!.isAuthorized {
                            defaultSession?.sftp.connect()
                            defaultSession?.sftp.createDirectory(atPath: "/home/\(Server.default.user)/\(UIDevice.current.identifierForVendor!.uuidString)")
                            try! defaultSession?.channel.execute("touch /home/\(Server.default.user)/\(UIDevice.current.identifierForVendor!.uuidString)/main.zip")
                            defaultSession?.sftp.writeContents(zipFile, toFileAtPath: "/home/\(Server.default.user)/\(UIDevice.current.identifierForVendor!.uuidString)/main.zip")
                        }
                    }
                    
                    let fileURL = URL(string:"http://\(Server.default.host)/dl.php?f=/home/\(Server.user)/\(UIDevice.current.identifierForVendor!.uuidString)/main.zip")!
                    print(fileURL)
                    URLSession.shared.downloadTask(with: fileURL, completionHandler: { (url, response, error) in
                        do {try self.session.channel.write("\n")} catch _ {}
                        if error == nil {
                            if url != nil {
                                do {
                                    let destURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!.appendingPathComponent(self.mainFile+".swiftc")
                                    
                                    print("DEST URL: \(destURL.absoluteString)")
                                    
                                    if FileManager.default.fileExists(atPath: destURL.path) {
                                        try FileManager.default.removeItem(at: destURL)
                                    }
                                    
                                    print("ZIP URL: \(destURL.deletingLastPathComponent().appendingPathComponent(self.mainFile+".tmp"+".zip"))")
                                    
                                    try FileManager.default.copyItem(at: url!, to: destURL.deletingLastPathComponent().appendingPathComponent(self.mainFile+".tmp"+".zip"))
                                    
                                    let unziped = try Zip.quickUnzipFile(destURL.deletingLastPathComponent().appendingPathComponent(self.mainFile+".tmp"+".zip"))
                                    
                                    try FileManager.default.moveItem(at: unziped.appendingPathComponent(UIDevice.current.identifierForVendor!.uuidString).appendingPathComponent("main"), to: destURL)
                                    try FileManager.default.removeItem(at: unziped)
                                    try FileManager.default.removeItem(at:
                                        destURL.deletingLastPathComponent().appendingPathComponent(self.mainFile+".tmp"+".zip"))
                                    
                                    
                                    let publish = PublishToStoreActivity()
                                    publish.fileURL = destURL
                                    publish.delegate = self.delegate
                                    
                                    let activityVC = UIActivityViewController(activityItems: [destURL], applicationActivities: [publish])
                                    
                                    try! defaultSession?.channel.execute("rm -rf /home/\(Server.default.user)/\(UIDevice.current.identifierForVendor!.uuidString)")
                                    try! self.session.channel.execute("rm -rf /home/\(Server.user)/\(UIDevice.current.identifierForVendor!.uuidString)")
                                    self.session.disconnect()
                                    defaultSession?.disconnect()
                                    
                                    if !inCurrentVC {
                                        self.dismiss(animated: true, completion: {
                                            self.delegate?.present(activityVC, animated: true, completion: nil)
                                        })
                                    } else {
                                        self.present(activityVC, animated: true, completion: nil)
                                    }
                                    
                                } catch let error {
                                    AlertManager.shared.present(error: error, withTitle: "Error saving file!", inside: self)
                                }
                            }
                        } else {
                            self.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                        }
                    }).resume()
                    
                } else {
                    self.session.disconnect()
                }
            }
            
            self.terminal.scrollToBotom()
            self.console = self.terminal.text
        }
        
        
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        let d = notification.userInfo!
        var r = d[UIKeyboardFrameEndUserInfoKey] as! CGRect
        
        r = self.terminal.convert(r, from:nil)
        self.terminal.contentInset.bottom = r.size.height+50
        self.terminal.scrollIndicatorInsets.bottom = r.size.height+50
        
        r = self.plainTerminal.convert(r, from:nil)
        self.plainTerminal.contentInset.bottom = r.size.height+50
        self.plainTerminal.scrollIndicatorInsets.bottom = r.size.height+50
        
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        self.terminal.contentInset = .zero
        self.terminal.scrollIndicatorInsets = .zero
        
        self.plainTerminal.contentInset = .zero
        self.plainTerminal.scrollIndicatorInsets = .zero
    }
    
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    func channelShellDidClose(_ channel: NMSSHChannel!) {
        DispatchQueue.main.async {
            print("Shell closed!")
            self.terminal.resignFirstResponder()
            self.terminal.isEditable = false
            self.activity.stopAnimating()
            self.terminal.isSelectable = true
            self.terminal.tintColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        }
    }
    
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if (textView.text as NSString).replacingCharacters(in: range, with: text).characters.count >= console.characters.count {
            if text.contains("\n") {
                let newConsole = textView.text+text
                let console = self.console
                print("newConsole: \(newConsole)")
                let cmd = newConsole.replacingOccurrences(of: console, with: "")
                print("Command: { \(cmd) }")
                do {
                    let range = newConsole.range(of: cmd)
                    textView.text = newConsole.replacingCharacters(in: range!, with: "")
                    
                    try session.channel.write(cmd)
                    return false
                } catch _ {
                    self.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                }
            }
            
            
            return true
        }
        
        return false
    }

    func textExceedBoundsOf(_ textView: UITextView) -> Bool {
        let textHeight = textView.contentSize.height
        return textHeight > textView.bounds.height
    }

}
