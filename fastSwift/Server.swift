//
//  Server.swift
//  fastSwift
//
//  Created by Adrian on 16.07.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class Server {
    private init() {}
    
    private var enabled: Bool {
        return UserDefaults.standard.bool(forKey: "custom_server")
    }
    
    static var host:String {
        if let ip_ = UserDefaults.standard.string(forKey: "hostname") {
            if Server().enabled {
                return ip_
            } else {
                return "190.46.99.168"
            }
        } else {
            return "190.46.99.168"
        }
    }
    
    static var user:String {
        if let user = UserDefaults.standard.string(forKey: "username") {
            if Server().enabled {
                return user
            } else {
                return "swiftexec"
            }
        } else {
            return "swiftexec"
        }
    }
    
    static var password:String {
        if let pass = UserDefaults.standard.string(forKey: "password") {
            if Server().enabled {
                return pass
            } else {
                return "swift"
            }
        } else {
            return "swift"
        }
    }
}
