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
                return Server.default.host
            }
        } else {
            return Server.default.host
        }
    }
    
    static var user:String {
        if let user = UserDefaults.standard.string(forKey: "username") {
            if Server().enabled {
                return user
            } else {
                return Server.default.user
            }
        } else {
            return Server.default.user
        }
    }
    
    static var password:String {
        if let pass = UserDefaults.standard.string(forKey: "password") {
            if Server().enabled {
                return pass
            } else {
                return Server.default.password
            }
        } else {
            return Server.default.password
        }
    }
    
    static var `default` = Server()
    
    var host = "coldg.ddns.net"
    var user = "swiftexec"
    var password = "swift"
}
