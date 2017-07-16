//
//  NMTerminalViewController.swift
//  fastFiles
//
//  Created by Adrian on 16.04.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import NMSSH
import TZKeyboardPop


class NMTerminalViewController: UIViewController, NMSSHSessionDelegate, NMSSHChannelDelegate, TZKeyboardPopDelegate, UITextViewDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var terminal: UITextView!
    var session = NMSSHSession()
    
    var keyboard = TZKeyboardPop()
    
    var command = ""
    
    var host = UserDefaults.standard.string(forKey: "IP")
    var user = UserDefaults.standard.string(forKey: "USER")
    var password = UserDefaults.standard.string(forKey: "PASSWORD")
    
    var project = ""
    
    var needsUserInput = true
    
    @IBOutlet weak var navBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        terminal.layoutManager.allowsNonContiguousLayout = false
        terminal.isEditable = false
        terminal.isSelectable = false
        terminal.delegate = self
        
        if needsUserInput {
            keyboard = TZKeyboardPop(view: self.view)
            keyboard.delegate = self
            keyboard.showKeyboard()
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
    
    @IBAction func disconnect(_ sender: Any) {
        session.disconnect()
        quit(0)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        DispatchQueue.main.async {
            self.terminal.text = self.terminal.text+message
            
            if self.terminal.text.contains("Program output") {
                let newString = self.terminal.text.components(separatedBy: "Program output")
                
                self.terminal.text = newString[1]
            }
            
            if self.terminal.text.contains("DOWNLOADEXECUTABLEFILETOAPP") {
                let newString = self.terminal.text.components(separatedBy: "DOWNLOADEXECUTABLEFILETOAPP")
                
                self.terminal.text = newString[0]
                
                // Download output
                let alert = UIAlertController(title: "Downloading output...", message: nil, preferredStyle: .alert)
                
                self.present(alert, animated: true, completion: {
                    do {
                        
                        self.session.disconnect()
                        
                        let session = NMSSHSession.connect(toHost: self.host, withUsername: self.user)
                        if (session?.isConnected)! {
                            session?.authenticate(byPassword: self.password)
                            if (session?.isAuthorized)! {
                                
                                var fileToDownload = try session?.channel.execute("ls \((UIDevice.current.identifierForVendor!.uuidString))").replacingOccurrences(of: "\n", with: "")
                                fileToDownload = "/home/swiftexec/\((UIDevice.current.identifierForVendor!.uuidString))/"+fileToDownload!
                                print(fileToDownload!+" -> "+self.project+"/\(URL(fileURLWithPath:self.project).deletingPathExtension().lastPathComponent)")
                                
                                session?.channel.downloadFile(fileToDownload, to: self.project+"/\(URL(fileURLWithPath:self.project).deletingPathExtension().lastPathComponent)")
                                
                                self.dismiss(animated: true, completion: nil)
                                
                            }
                        }
                        
                    } catch let error {
                        self.dismiss(animated: true, completion: nil)
                        print(error.localizedDescription)
                    }
                })
            }
            
        }
        
    }
    
    
    func didReturnKeyPressed(withText str: String!) {
        print(str)
        session.channel.write(str+"\n", error: nil, timeout: 10)
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
            self.keyboard.hide()
        }
        
    }
    
    func quit(_ errno:Int32) {
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        sleep(3)
        exit(errno)
    }
}

