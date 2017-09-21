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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        password.isSecureTextEntry = true
        ip.delegate = self
        username.delegate = self
        password.delegate = self
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
        
        let session = NMSSHSession.connect(toHost: ip.text!, withUsername: username.text!)
        if session!.isConnected {
            
            showStatus("Connected!", with: .green)
            
            session?.authenticate(byPassword: password.text!)
            if session!.isAuthorized {
                
                showStatus("Logged in!", with: .green)
                
                do {
                    showStatus("Installing..", with: .yellow)
                    
                    let swift = try session?.channel.execute("swiftc --help")
                    
                    if swift!.contains("swiftc: command not found") {
                        // Swift is not installed
                        showStatus("Swift is not installed!", with: .red)
                    } else {
                        let _ = try session?.channel.execute("echo \(password.text!) | sudo -S wait; curl -s -L http://goo.gl/hPvdsn | sudo bash -s swiftexec swift; logout")
                        
                        showStatus("Installed!", with: .green)
                        var installed = true
                        
                        let newUserFolder = try session?.channel.execute("ls /home/swiftexec")
                        if newUserFolder!.contains("No such file or directory") {
                            showStatus("Failed to create /home/swiftexec", with: .red)
                            installed = false
                        }
                        
                        let userID = try session?.channel.execute("id -u swiftexec")
                        if userID!.contains("no such user") {
                            showStatus("Failed to create user swiftexec", with: .red)
                            installed = false
                        }
                        
                        if installed {
                            let alert = AlertManager.shared.alert(withTitle: "Created server", message: "'swiftexec@\(ip.text!)' with password 'swift'", style: .alert, actions: [AlertManager.shared.ok(handler: nil)])
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                    
                    
                } catch let error {
                    showStatus("\(error)", with: .red)
                }
                
            } else {
                showStatus("Can't login!", with: .red)
                session?.disconnect()
            }
        } else {
            showStatus("Can't connect!", with: .red)
        }
    }
    
    
    
}
