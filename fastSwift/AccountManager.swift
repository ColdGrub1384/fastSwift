//
//  AccountManager.swift
//  fastSwift
//
//  Created by Adrian on 24.06.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import StoreKit


class AccountManager {
    static let shared = AccountManager()
    private init() {
    }
    
    var username: String? {
        get {
            return  UserDefaults.standard.string(forKey: "username")
        }
        
        set(value) {
            UserDefaults.standard.set(value, forKey: "username")
        }
    }
    var password: String? {
        get {
            return  UserDefaults.standard.string(forKey: "userpass")
        }
        
        set(value) {
            UserDefaults.standard.set(value, forKey: "userpass")
        }
    }
    
    func presentAccountInfo(inside vc: UIViewController) {
        func info() {
            let alert = AlertManager.shared.alert(withTitle: self.username!, message: "You are logged as \(self.username!)", style: .alert, actions: [UIAlertAction.init(title: "View account", style: .default, handler: { (action) in
                AlertManager.shared.openWebView(withURL: URL(string:"http://\(Server.default.host)/fastSwiftAccount.php?user=\(self.username!.addingPercentEncodingForURLQueryValue()!)&password=\(self.password!.addingPercentEncodingForURLQueryValue()!)&server=\(Server.host)&action=uiLogin")!, inside: vc)
            }), UIAlertAction.init(title: "Logout", style: .default, handler: { (action) in
                self.username = nil
                self.password = nil
                
                self.login(inside: vc, completion: nil)
            }), AlertManager.shared.cancel])
            
            vc.present(alert, animated: true, completion: nil)
        }
        
        if username == nil {
            login(inside: vc, completion: {
                info()
            })
        } else {
            info()
        }
    }
    
    func login(inside vc: UIViewController, completion: (() -> Void)?) {
        
        var userTextField = UITextField()
        var passTextField = UITextField()
        
        let alert = AlertManager.shared.alert(withTitle: "Login / Register", message: "You need an account to publish projects to the store", style: .alert, actions: [UIAlertAction.init(title: "Login", style: .default, handler: { (action) in
            // Login
            let params = "user=\(userTextField.text!.addingPercentEncodingForURLQueryValue()!)&password=\(passTextField.text!.addingPercentEncodingForURLQueryValue()!)&action=login"
            URLSession.shared.dataTask(with: URL(string:"http://\(Server.default.host)/fastSwiftAccount.php?\(params)")!, completionHandler: { (data, response, error) in
                
                print("URL: \(response!.url!)")
                
                if error == nil {
                    if data != nil {
                        let str = String.init(data: data!, encoding: String.Encoding.utf8)!
                        
                        if str == "Authenticated!" {
                            self.username = userTextField.text!
                            self.password = passTextField.text!
                            
                            if completion != nil {
                                completion!()
                            }
                        } else {
                            AlertManager.shared.presentAlert(withTitle: "Error loging in!", message: str, style: .alert, actions: [AlertManager.shared.cancel], inside: vc, animated: true, completion: nil)
                        }
                    } else {
                        AlertManager.shared.presentAlert(withTitle: "Error loging in!", message: "Returned data is empty!", style: .alert, actions: [AlertManager.shared.cancel], inside: vc, animated: true, completion: nil)
                    }
                } else {
                    AlertManager.shared.present(error: error!, withTitle: "Error loging in!", inside: vc)
                }
            }).resume()
            
        }), UIAlertAction.init(title: "Register", style: .default, handler: { (action) in
            // Register
            let params = "user=\(userTextField.text!.addingPercentEncodingForURLQueryValue()!)&password=\(passTextField.text!.addingPercentEncodingForURLQueryValue()!)&action=register"
            URLSession.shared.dataTask(with: URL(string:"http://\(Server.default.host)/fastSwiftAccount.php?\(params)")!, completionHandler: { (data, response, error) in
                
                print("URL: \(response!.url!)")
                
                if error == nil {
                    if data != nil {
                        let str = String.init(data: data!, encoding: String.Encoding.utf8)!
                        
                        if str == "User created!" {
                            self.username = userTextField.text!
                            self.password = passTextField.text!
                            
                            if completion != nil {
                                completion!()
                            }
                        } else {
                            AlertManager.shared.presentAlert(withTitle: "Error creating account!", message: str, style: .alert, actions: [AlertManager.shared.cancel], inside: vc, animated: true, completion: nil)
                        }
                    } else {
                        AlertManager.shared.presentAlert(withTitle: "Error creating account!", message: "Returned data is empty!", style: .alert, actions: [AlertManager.shared.cancel], inside: vc, animated: true, completion: nil)
                    }
                } else {
                    AlertManager.shared.present(error: error!, withTitle: "Error creating account!", inside: vc)
                }
            }).resume()
            
        }), AlertManager.shared.cancel])
        
        alert.addTextField { (textfield) in
            textfield.placeholder = "Username"
            userTextField = textfield
        }
        
        alert.addTextField { (textfield) in
            textfield.placeholder = "Password"
            textfield.isSecureTextEntry = true
            passTextField = textfield
        }
        
        vc.present(alert, animated: true, completion: nil)
    }
    
    var customServerEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "custom_server")
    }
    
    var compilations: Int {
        get {
            #if DEBUG
                return 100
            #endif
            
            if !UserDefaults.standard.bool(forKey: "firstReward") {
                UserDefaults.standard.set(true, forKey: "firstReward")
                UserDefaults.standard.set(1, forKey: "compilations")
            }
            return UserDefaults.standard.integer(forKey: "compilations")
        }
        
        set(value) {
            UserDefaults.standard.set(value, forKey: "compilations")
        }
        
    }
    
    
    func buy(product: products) {
        compilations = compilations+product.rawValue
    }
    
    
    public enum products: Int {
        case pendrive = 32
        case sdCard = 64
        case cd = 128
        case hardDrive = 256
    }
    
    var productPrices: [String] {
        return (UIApplication.shared.delegate as! AppDelegate).prices
    }
    
    var shop: [SKProduct]!
    
    var storeViewController: UIViewController?
    
    
}
