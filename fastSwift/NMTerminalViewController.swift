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
    
    @IBAction func disconnect(_ sender: Any) {
        session.disconnect()
        self.dismiss(animated: true, completion: nil)
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
            
            
        }
        
    }
    
    
    func didReturnKeyPressed(withText str: String!) {
        print(str)
        if str == "clear" {
            self.terminal.text = ""
        }
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
}
