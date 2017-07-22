//
//  NMTerminalViewController.swift
//  fastFiles
//
//  Created by Adrian on 16.04.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import NMSSH


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
    
    var console = ""
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        terminal.layoutManager.allowsNonContiguousLayout = false
        terminal.isSelectable = false
        terminal.delegate = self
        terminal.isEditable = true
        terminal.keyboardAppearance = .dark
        terminal.tintColor = .white
        if needsUserInput {
            terminal.becomeFirstResponder()
        }
        
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
                    print(error.localizedDescription)
                }
            }
        }
        
        self.title = "Program output"
        
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
        return UIStatusBarStyle.lightContent
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
                if true {
                    self.terminal.text = "Downloading executable file..."
                    try! self.session.channel.execute("zip \(UIDevice.current.identifierForVendor!.uuidString)/main.zip \(UIDevice.current.identifierForVendor!.uuidString)/main")
                    
                    URLSession.shared.downloadTask(with: URL(string:"http://coldg.ddns.net/dl.php?f=/home/swiftexec/\(UIDevice.current.identifierForVendor!.uuidString)/main.zip")!, completionHandler: { (url, response, error) in
                        do {try self.session.channel.write("\n")} catch _ {}
                        if error == nil {
                            if url != nil {
                                do {
                                    let destURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!.appendingPathComponent(self.mainFile+".swiftc")
                                    
                                    if FileManager.default.fileExists(atPath: destURL.path) {
                                        try FileManager.default.removeItem(at: destURL)
                                    }
                                    
                                    try FileManager.default.copyItem(at: url!, to: destURL)
                                    
                                    let activityVC = UIActivityViewController(activityItems: [destURL], applicationActivities: nil)
                                    
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
                    
                }
            }
            
            if self.textExceedBoundsOf(self.terminal) {
                self.terminal.scrollToBotom()
            }
            
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
            print("Shell closed!")
            self.terminal.resignFirstResponder()
            self.terminal.isEditable = false
            self.activity.stopAnimating()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if (textView.text as NSString).replacingCharacters(in: range, with: text).characters.count >= console.characters.count {
            if text.contains("\n") {
                let newConsole = textView.text+text
                let cmd = newConsole.replacingOccurrences(of: console, with: "")
                print("Command: { \(cmd) }")
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

