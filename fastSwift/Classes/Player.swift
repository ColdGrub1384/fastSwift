//
//  Player.swift
//  fastSwift
//
//  Created by Adrian on 30.10.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class Player {
    var name: String
    var points: Int
    var profile: URL {
        if name == AccountManager.shared.username { // Is current user, so login when click View Profile
            return URL(string:"http://coldg.ddns.net/fastswift/fastSwiftAccount.php?action=uiLogin&user=\(name.addingPercentEncodingForURLQueryValue()!)&password=\(AccountManager.shared.password!.addingPercentEncodingForURLQueryValue()!)")!
        }
        return URL(string:"http://coldg.ddns.net/fastswift/fastSwiftAccount.php?action=uiLogin&user=\(name.addingPercentEncodingForURLQueryValue()!)")!
    }
    
    init(name: String, points: Int) {
        self.name = name
        self.points = points
    }
}
