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
    
    var redeemed: [String] {
        get {
            if let redeemed_ = UserDefaults.standard.string(forKey: "redeemed") {
                return redeemed_.components(separatedBy: ";")
            }
            return []
        }
        
        set(value) {
            let raw = value.joined(separator: ";")
            UserDefaults.standard.set(raw, forKey: "redeemed")
        }
    }
    
    class Compilations {
        
        var didSetHandler: ((_ value:Compilations) -> Void)?
        
        private func didSet(_ value: Compilations) {
            if didSetHandler != nil {
                didSetHandler!(value)
            }
        }
        
        enum CompilationsType {
            case amount
            case infinite
        }
        
        func substract(_ int: Int) {
            self.amount = self.amount-int
            self.didSet(self)
        }
        
        func add(_ int: Int) {
            self.amount = self.amount+int
            self.didSet(self)
        }
        
        static private var infinite_ = Compilations(withAmount: 0)
        
        var amount: Int
        var type: CompilationsType
        
        var description: String {
            if self.type == .amount {
                return "\(amount)"
            } else {
                return "∞"
            }
        }
        
        init(withAmount amount: Int) {
            self.amount = amount
            self.type = .amount
        }
        
        static func infinite() -> Compilations {
            infinite_.type = .infinite
            
            return infinite_
        }
    }
    
    var username: String? {
        get {
            return  UserDefaults.standard.string(forKey: "accountUser")
        }
        
        set(value) {
            UserDefaults.standard.set(value, forKey: "accountUser")
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
            let alert = AlertManager.shared.alert(withTitle: self.username!, message: Strings.AccountManager.loggedAs(user: self.username!), style: .alert, actions: [UIAlertAction.init(title: Strings.AccountManager.viewAccount, style: .default, handler: { (action) in
                AlertManager.shared.openWebView(withURL: URL(string:"http://\(Server.default.host)/fastSwiftAccount.php?user=\(self.username!.addingPercentEncodingForURLQueryValue()!)&password=\(self.password!.addingPercentEncodingForURLQueryValue()!)&server=\(Server.user)@\(Server.host)&action=uiLogin")!, inside: vc)
            }), UIAlertAction.init(title: Strings.AccountManager.logout, style: .default, handler: { (action) in
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
        
        let alert = AlertManager.shared.alert(withTitle: "\(Strings.AccountManager.login) / \(Strings.AccountManager.register)", message: Strings.AccountManager.loginAlertMessage, style: .alert, actions: [UIAlertAction.init(title: Strings.AccountManager.login, style: .default, handler: { (action) in
            // Login
            let params = "user=\(userTextField.text!.addingPercentEncodingForURLQueryValue()!)&password=\(passTextField.text!.addingPercentEncodingForURLQueryValue()!)&action=login"
            URLSession.shared.dataTask(with: URL(string:"http://\(Server.default.host)/fastSwiftAccount.php?\(params)")!, completionHandler: { (data, response, error) in
                
                print("URL: \(response!.url!)")
                
                if error == nil {
                    if data != nil {
                        let str = String.init(data: data!, encoding: String.Encoding.utf8)!
                        
                        if str == "Authenticated!" {
                            DispatchQueue.main.async {
                                self.username = userTextField.text!
                                self.password = passTextField.text!
                                
                                if completion != nil {
                                    completion!()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                AlertManager.shared.presentAlert(withTitle: Strings.AccountManager.errorLogingIn, message: str, style: .alert, actions: [AlertManager.shared.cancel], inside: vc, animated: true, completion: nil)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            AlertManager.shared.presentAlert(withTitle: Strings.AccountManager.errorLogingIn, message: Strings.emptyData, style: .alert, actions: [AlertManager.shared.cancel], inside: vc, animated: true, completion: nil)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        AlertManager.shared.present(error: error!, withTitle: Strings.AccountManager.errorLogingIn, inside: vc)
                    }
                }
            }).resume()
            
        }), UIAlertAction.init(title: Strings.AccountManager.register, style: .default, handler: { (action) in
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
                                DispatchQueue.main.async {
                                    completion!()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                AlertManager.shared.presentAlert(withTitle: Strings.AccountManager.errorCreatingAccount, message: str, style: .alert, actions: [AlertManager.shared.cancel], inside: vc, animated: true, completion: nil)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            AlertManager.shared.presentAlert(withTitle: Strings.AccountManager.errorCreatingAccount, message: Strings.emptyData, style: .alert, actions: [AlertManager.shared.cancel], inside: vc, animated: true, completion: nil)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        AlertManager.shared.present(error: error!, withTitle: Strings.AccountManager.errorCreatingAccount, inside: vc)
                    }
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
    
    var compilations: Compilations {
        
        get {
            
            if !UserDefaults.standard.bool(forKey: "firstReward") {
                UserDefaults.standard.set(true, forKey: "firstReward")
                UserDefaults.standard.set(1, forKey: "compilations")
                UserDefaults.standard.synchronize()
            }
            
            var value = Compilations(withAmount: UserDefaults.standard.integer(forKey: "compilations"))
            
            if UserDefaults.standard.bool(forKey: "infinite") {
                value = .infinite()
            }
            
            value.didSetHandler = { value in
                UserDefaults.standard.set((value.type == .infinite), forKey: "infinite")
                UserDefaults.standard.set(value.amount, forKey: "compilations")
                UserDefaults.standard.synchronize()
            }
            
            return value
        }
        
        set(value) {
            UserDefaults.standard.set((value.type == .infinite), forKey: "infinite")
            UserDefaults.standard.set(value.amount, forKey: "compilations")
            UserDefaults.standard.synchronize()
        }
        
    }
    
    
    func buy(product: Products) {
        compilations.add(product.rawValue)
        if let store = self.storeViewController {
            store.compilations.text = "\(AccountManager.shared.compilations.description) 🐧"
        }
    }
    
    
    public enum Products: Int {
        case pendrive = 32
        case sdCard = 64
        case cd = 128
        case hardDrive = 256
    }
    
    var productPrices: [String] {
        return AppDelegate.shared.prices
    }
    
    var shop: [SKProduct]!
    
    var storeViewController: StoreViewController?
    
    
}
