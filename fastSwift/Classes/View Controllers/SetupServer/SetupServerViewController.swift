//
//  SetupServerViewController.swift
//  fastSwift
//
//  Created by Adrian on 19.09.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import NMSSH

class SetupServerViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var ip: UITextField!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var text: UITextView!
    @IBOutlet weak var setupBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        password.isSecureTextEntry = true
        ip.delegate = self
        username.delegate = self
        password.delegate = self
        
        activity.isHidden = true
        
        view.backgroundColor = AppDelegate.shared.theme.color
        titleLbl.textColor = AppDelegate.shared.theme.textColor
        text.textColor = AppDelegate.shared.theme.textColor
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func showStatus(_ text:String, with color:UIColor) {
        DispatchQueue.main.async {
            self.status.textColor = color
            self.status.text = text
        }
    }
        
    @IBAction func setup(sender: Any) {
        
        activity.startAnimating()
        activity.isHidden = false
        
        let _ = Afte.r(0.2) { (timer) in
            let session = NMSSHSession.connect(toHost: self.ip.text!, withUsername: self.username.text!)
            if session!.isConnected {
                
                self.showStatus("Connected!", with: .green)
                
                session?.authenticate(byPassword: self.password.text!)
                if session!.isAuthorized {
                    
                    self.showStatus("Logged in!", with: .green)
                    
                    do {
                        self.showStatus("Installing..", with: .yellow)
                        
                        let swift = try session?.channel.execute("swiftc --help")
                        
                        if swift!.contains("swiftc: command not found") {
                            // Swift is not installed
                            self.showStatus("Swift is not installed!", with: .red)
                        } else {
                            let _ = try session?.channel.execute("echo \(self.password.text!) | sudo -S wait; curl -s -L http://goo.gl/hPvdsn | sudo bash -s swiftexec swift; logout")
                            
                            self.showStatus("Installed!", with: .green)
                            var installed = true
                            
                            let newUserFolder = try session?.channel.execute("ls /home/swiftexec")
                            if newUserFolder!.contains("No such file or directory") {
                                self.showStatus("Failed to create /home/swiftexec", with: .red)
                                installed = false
                            }
                            
                            let userID = try session?.channel.execute("id -u swiftexec")
                            if userID!.contains("no such user") {
                                self.showStatus("Failed to create user swiftexec", with: .red)
                                installed = false
                            }
                            
                            if installed {
                                let alert = AlertManager.shared.alert(withTitle: "Created server", message: "'swiftexec@\(self.ip.text!)' with password 'swift'", style: .alert, actions: [AlertManager.shared.ok(handler: nil)])
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                        
                        
                    } catch let error {
                        self.showStatus("\(error)", with: .red)
                    }
                    
                } else {
                    self.showStatus("Can't login!", with: .red)
                    session?.disconnect()
                }
            } else {
                self.showStatus("Can't connect!", with: .red)
            }
        }
        
        self.activity.stopAnimating()
        self.activity.isHidden = true
        
    }
    
    
    
}
