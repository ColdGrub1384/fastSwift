//
//  PublishToStoreActivity.swift
//  fastSwift
//
//  Created by Adrian on 25.07.17.
//  Copyright © 2017 Adrian. All rights reserved.
//


import UIKit
import NMSSH

class PublishToStoreActivity: UIActivity {
    var delegate: DocumentViewController?
    var fileURL: URL?
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "fastSwift.store")
    }
    
    override var activityTitle: String? {
        return "Publish to store"
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        NSLog("%@", #function)
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        NSLog("%@", #function)
    }
    
    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "terminal")
    }
    
    override func perform() {
        
        let delegate = self.delegate!
        
        func publish() {
            let vc = ActivityViewController(message: "Uploading...")
            delegate.present(vc, animated: true, completion: nil)
            
            URLSession.shared.dataTask(with: URL(string:"http://\(Server.default.host)/createDirAtShop.php/?server=\("\(Server.user)@\(Server.host)".addingPercentEncodingForURLQueryValue()!)")!, completionHandler: { (data, response, error) in
                if error == nil {
                    let session = NMSSHSession.connect(toHost: Server.default.host, withUsername: Server.default.user)
                    if session!.isConnected {
                        session?.authenticate(byPassword: Server.default.password)
                        if session!.isAuthorized {
                            do {
                                try session?.channel.execute("mkdir /home/swiftexec/store/; mkdir /home/swiftexec/store/\(Server.user)@\(Server.host); mkdir /home/swiftexec/store/\(Server.user)@\(Server.host)/files; mkdir /home/swiftexec/store/\(Server.user)@\(Server.host)/source; mkdir '/home/swiftexec/store/\(Server.user)@\(Server.host)/source/\(self.fileURL!.lastPathComponent)'; mkdir /home/swiftexec/store/\(Server.user)@\(Server.host)/meta; mkdir '/home/swiftexec/store/\(Server.user)@\(Server.host)/meta/\(self.fileURL!.lastPathComponent)'; mkdir '/home/swiftexec/store/\(Server.user)@\(Server.host)/meta/\(self.fileURL!.lastPathComponent)/user'; touch '/home/swiftexec/store/\(Server.user)@\(Server.host)/meta/\(self.fileURL!.lastPathComponent)/user/\(AccountManager.shared.username!)'")
                            } catch _ {
                                delegate.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                            }
                            session?.channel.uploadFile(self.fileURL!.path, to: "/home/swiftexec/store/\(Server.user)@\(Server.host)/files/\(self.fileURL!.lastPathComponent)")
                            let source = delegate.files
                            
                            for file in source {
                                session?.channel.uploadFile(file.path, to: "/home/swiftexec/store/\(Server.user)@\(Server.host)/source/\(self.fileURL!.lastPathComponent)/\(file.lastPathComponent)")
                            }
                            
                            let url = URL(string:"http://\(Server.default.host)/moveScriptsToShop.php/?atServer=\("\(Server.user)@\(Server.host)")&script=\(self.fileURL!.lastPathComponent.addingPercentEncodingForURLQueryValue()!)&user=\(AccountManager.shared.username!.addingPercentEncodingForURLQueryValue()!)&password=\(AccountManager.shared.password!.addingPercentEncodingForURLQueryValue()!)")!
                            print(url.absoluteString)
                            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                                
                                
                                do {try session?.channel.execute("rm -rf '/home/swiftexec/store/\(Server.user)@\(Server.host)/source/\(self.fileURL!.lastPathComponent)'; rm '/home/swiftexec/store/\(Server.user)@\(Server.host)/files/\(self.fileURL!.lastPathComponent)'; rm -rf '/home/swiftexec/store/\(Server.user)@\(Server.host)/meta/\(self.fileURL!.lastPathComponent)'")} catch _ {}
                                session?.disconnect()
                                
                                if error == nil {
                                    if data != nil {
                                        if let error = String(data:data!, encoding: String.Encoding.utf8) {
                                            if error != "" {
                                                delegate.dismiss(animated: true, completion: {
                                                     AlertManager.shared.presentAlert(withTitle: "Error publishing project!", message: error, style: .alert, actions: [AlertManager.shared.cancel], inside: delegate, animated: true, completion: nil)
                                                })
                                            } else {
                                                URLSession.shared.dataTask(with: URL(string:"http://\(Server.default.host)/fastSwiftAccount.php/?action=registerScript&user=\(AccountManager.shared.username!.addingPercentEncodingForURLQueryValue()!)&password=\(AccountManager.shared.password!.addingPercentEncodingForURLQueryValue()!)&script=\(self.fileURL!.lastPathComponent.addingPercentEncodingForURLQueryValue()!)")!, completionHandler: { (data, response, error) in
                                                    
                                                    if error == nil {
                                                        if data != nil {
                                                            delegate.dismiss(animated: true, completion: {
                                                                AlertManager.shared.presentAlert(withTitle: "Published!", message: "People connected to \(Server.host) can now download your project via the store!\nIf you want to update the project, simplely publish it another time and if you want to delete the project go to Store > Account > View Account.", style: .alert, actions: [AlertManager.shared.ok(handler: nil)], inside: delegate, animated: true, completion: nil)
                                                            })
                                                        } else {
                                                            AlertManager.shared.presentAlert(withTitle: "Error adding script to the database!", message: "Returned data is empty.", style: .alert, actions: [AlertManager.shared.cancel], inside: delegate, animated: true, completion: nil)
                                                        }
                                                    } else {
                                                        delegate.dismiss(animated: true, completion: {
                                                            AlertManager.shared.present(error: error!, withTitle: "Error adding script to the database!", inside: delegate)
                                                        })
                                                    }
                                                    
                                                }).resume()
                                            }
                                        }
                                    } else {
                                        delegate.dismiss(animated: true, completion: {
                                            delegate.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                                        })
                                    }
                                } else {
                                    delegate.dismiss(animated: true, completion: {
                                        delegate.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                                    })
                                }
                                
                                
                            }).resume()
                            
                        } else {
                            delegate.dismiss(animated: true, completion: {
                                delegate.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                            })
                        }
                    } else {
                        delegate.dismiss(animated: true, completion: {
                            delegate.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                        })
                    }
                } else {
                    delegate.dismiss(animated: true, completion: {
                        AlertManager.shared.present(error: error!, withTitle: "Error creating database for server!", inside: delegate)
                    })
                }
            }).resume()
            
        }
        
        if AccountManager.shared.username != nil && AccountManager.shared.username != "" {
            publish()
        } else {
            AccountManager.shared.login(inside: delegate, completion: {
                publish()
                print("No account!")
            })
        }
    }
    
    override class var activityCategory:UIActivityCategory {
        return .share
    }
}

