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
