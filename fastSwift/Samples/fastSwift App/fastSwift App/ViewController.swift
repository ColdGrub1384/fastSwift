//
//  ViewController.swift
//  fastSwift App
//
//  Created by Adrian on 07.07.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import NMSSH

class ViewController: UIViewController {
    
    var files = [URL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        files = try! FileManager.default.contentsOfDirectory(at: Bundle.main.url(forResource: "Source", withExtension: nil)!, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print(files)
        let session = NMSSHSession.connect(toHost: "190.46.99.168", withUsername: "swiftexec")
        
        if (session?.isConnected)! {
            session?.authenticate(byPassword: "swift")
            
            if (session?.isAuthorized)! {
                
                do {
                    // Create unique folder
                    try session?.channel.execute("rm -rf \((UIDevice.current.identifierForVendor!.uuidString))")
                    try session?.channel.execute("mkdir '\((UIDevice.current.identifierForVendor!.uuidString))'")
                    try session?.channel.execute("cp /home/fastswift/FFKit.swift '\((UIDevice.current.identifierForVendor!.uuidString))'")
                    
                    // Upload files
                    for file in self.files {
                        session?.channel.uploadFile(file.path, to: "\((UIDevice.current.identifierForVendor!.uuidString))/\(file.lastPathComponent)")
                        
                    }
                    
                    self.performSegue(withIdentifier: "swift", sender: nil)
                    
                } catch let error {
                    // Quit
                    print("Error uploading file: \(error.localizedDescription)")
                    self.quit(1)
                }
            } else {
                // Quit
                self.quit(2)
            }
        } else {
            // Quit
            self.quit(3)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func quit(_ errno:Int32) {
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        sleep(3)
        exit(errno)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        print("Prepare for segue")
        
        if segue.identifier == "swift" {
            if let nextVC = segue.destination as? NMTerminalViewController {
                nextVC.command = "cd '\((UIDevice.current.identifierForVendor!.uuidString))'; swiftc *; ./main; cd ~; rm -rf \((UIDevice.current.identifierForVendor!.uuidString)); logout"
                print(nextVC.command)
                nextVC.host = "190.46.99.168"
                nextVC.user = "swiftexec"
                nextVC.password = "swift"
            }
        }
    }
}

