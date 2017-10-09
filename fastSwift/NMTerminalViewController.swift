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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let delegate = browserVC {
            delegate.viewDidAppear(true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                //session.channel.ptyTerminalType = NMSSHChannelPtyTerminal.xterm
                session.channel.requestPty = true
                
                do {
                    try session.channel.startShell()
                    try session.channel.write("echo Progr\\am output;"+command+"\n")
                } catch let error {
                    Debugger.shared.debug_(error.localizedDescription)
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
        self.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppDelegate.shared.theme.statusBarStyle
    }
    
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        DispatchQueue.main.async {
            self.console = self.console+message
            self.terminal.text = self.terminal.text+message
            
            if self.terminal.text.contains("Program output") {
                let newString = self.terminal.text.components(separatedBy: "Program output")
                self.activity.stopAnimating()
                self.terminal.text = newString[1]
                self.console = self.terminal.text
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
                    
                    let fileURL = URL(string:"http://\(Server.default.host)/dl.php?f=/home/\(Server.user)/\(UIDevice.current.identifierForVendor!.uuidString)/main.zip")!
                    Debugger.shared.debug_(fileURL)
                    URLSession.shared.downloadTask(with: fileURL, completionHandler: { (url, response, error) in
                        do {try self.session.channel.write("\n")} catch _ {}
                        if error == nil {
                            if url != nil {
                                do {
                                    let destURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!.appendingPathComponent(self.mainFile+".swiftc")
                                    
                                    Debugger.shared.debug_("DEST URL: \(destURL.absoluteString)")
                                    
                                    if FileManager.default.fileExists(atPath: destURL.path) {
                                        try FileManager.default.removeItem(at: destURL)
                                    }
                                    
                                    Debugger.shared.debug_("ZIP URL: \(destURL.deletingLastPathComponent().appendingPathComponent(self.mainFile+".tmp"+".zip"))")
                                    
                                    try FileManager.default.copyItem(at: url!, to: destURL.deletingLastPathComponent().appendingPathComponent(self.mainFile+".tmp"+".zip"))
                                    
                                    let unziped = try Zip.quickUnzipFile(destURL.deletingLastPathComponent().appendingPathComponent(self.mainFile+".tmp"+".zip"))
                                    
                                    try FileManager.default.moveItem(at: unziped.appendingPathComponent(UIDevice.current.identifierForVendor!.uuidString).appendingPathComponent("main"), to: destURL)
                                    try FileManager.default.removeItem(at: unziped)
                                    try FileManager.default.removeItem(at:
                                        destURL.deletingLastPathComponent().appendingPathComponent(self.mainFile+".tmp"+".zip"))
                                    
                                    
                                    let publish = PublishToStoreViewController()
                                    publish.fileURL = destURL
                                    publish.delegate = self.delegate
                                    
                                    let activityVC = UIActivityViewController(activityItems: [destURL], applicationActivities: [publish])
                                    
                                    if !inCurrentVC {
                                        self.dismiss(animated: true, completion: {
                                            self.session.disconnect()
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
            
        }
        
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        let d = notification.userInfo!
        var r = d[UIKeyboardFrameEndUserInfoKey] as! CGRect
        
        r = self.terminal.convert(r, from:nil)
        self.terminal.contentInset.bottom = r.size.height+50
        self.terminal.scrollIndicatorInsets.bottom = r.size.height+50
        
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        self.terminal.contentInset = .zero
        self.terminal.scrollIndicatorInsets = .zero
    }
    
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    func channelShellDidClose(_ channel: NMSSHChannel!) {
        DispatchQueue.main.async {
            Debugger.shared.debug_("Shell closed!")
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
                let cmd = newConsole.replacingOccurrences(of: console, with: "")
                Debugger.shared.debug_("Command: { \(cmd) }")
                do {
                    let range = newConsole.range(of: cmd)
                    textView.text = newConsole.replacingCharacters(in: range!, with: "")
                    
                    try session.channel.write(cmd)
                    return false
                } catch _ {
                    self.present(AlertManager.shared.serverErrorViewController, animated: true, completion: nil)
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
