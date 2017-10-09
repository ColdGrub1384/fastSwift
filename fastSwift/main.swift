//
//  main.swift
//  fastSwift
//
//  Created by Adrian on 07.10.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

func main() {
     UIApplicationMain(CommandLine.argc, UnsafeMutableRawPointer(CommandLine.unsafeArgv).bindMemory(to: UnsafeMutablePointer<Int8>.self,capacity: Int(CommandLine.argc)), nil, NSStringFromClass(AppDelegate.self))
}

main()

print("Hello World")
