//
//  Debugger.swift
//  fastSwift
//
//  Created by Adrian on 30.09.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import NMSSH
import DebuLog

class Debugger: DebuLog {
    static var shared = Debugger()
    
    private let libraryFolder = URL(fileURLWithPath:NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0])
    private let fileName = "Log.txt"
    
    private var session = NMSSHSession()
    
    private var send = false
    
    private var hasInfo = false
    
    override init() {
        super.init()
        
        session = NMSSHSession.connect(toHost: Server.default.host, withUsername: "debug")
        if session.isConnected {
            session.authenticate(byPassword: "debug")
            if session.isAuthorized {
                send = true
            }
        }
        
        file = libraryFolder.appendingPathComponent(fileName)
        
        let _ = Repea.t(all: 4) { (timer) in
            DispatchQueue.global(qos: .background).sync {
                do {
                    let input = try self.session.channel.execute("cat /home/debug/input.txt").replacingOccurrences(of: "\n", with: "")
                    let args = input.components(separatedBy: " ")
                    try self.session.channel.execute("/home/debug/input.sh")
                    
                    if args[0] == "addCompilations" {
                        if args.count >= 2 {
                            if let number = Int(args[1]) {
                                AccountManager.shared.compilations = AccountManager.shared.compilations+number
                            }
                        }
                    }
                    
                    if args[0] == "setCompilations" {
                        if args.count >= 2 {
                            if let number = Int(args[1]) {
                                AccountManager.shared.compilations = number
                            }
                        }
                    }
                } catch _ {}
            }
        }
        
        if send {
            let _ = Repea.t(all: 3, seconds: { (timer) in
                if self.hasInfo {
                    self.hasInfo = false
                    DispatchQueue.global(qos: .background).sync {
                        if AccountManager.shared.username == "ColdGrub1384" {
                            do {
                                try self.session.channel.execute("rm /home/debug/log.txt")
                                self.session.channel.uploadFile(self.file!.path, to: "/home/debug/log.txt")
                            } catch _ {}
                            
                        }
                    }
                }
            })
        }
    }
    
    override func debug_(_ thing: Any) {
        super.debug_(thing)

        hasInfo = true
    }
    
    override func close() {
        super.close()
        
        do { try self.session.channel.execute("rm /home/swiftexec/log.txt") } catch _ {}
        session.disconnect()
        
    }
}
