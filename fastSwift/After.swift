//
//  Afer.swift
//  fastSwift
//
//  Created by Adrian on 18.07.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class Afte {
    private init() {}
    
    static func r(_ timeInterval:TimeInterval, seconds block: @escaping (Timer) -> Void) -> Timer {
        return .scheduledTimer(withTimeInterval: timeInterval, repeats: false, block: block)
    }
}
