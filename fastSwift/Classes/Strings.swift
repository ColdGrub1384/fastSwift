//
//  Strings.swift
//  fastSwift
//
//  Created by Adrian on 27.11.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import Foundation

class Strings {
    
    private init() {}
    
    static let yes = NSLocalizedString("yes", comment: "")
    static let no = NSLocalizedString("no", comment: "")
    static let cancel = NSLocalizedString("cancel", comment: "")
    
    static let errorPurchasingUnlimited = NSLocalizedString("errorPurchasingUnlimited", comment: "Title for error purchasing unlimited compilations")
    
    class NoMoreCompilationsAlert {
        static let title = NSLocalizedString("noMoreCompilations.title", comment: "Error title saying: No enough 🐧")
        static let message = NSLocalizedString("noMoreCompilations.message", comment: "Error message saying: Buy 🐧 to compile scripts")
    }
    
    static let compressing = NSLocalizedString("compressing", comment: "Title for alert shown when compressing file")
    
    class AccountManager {
        private init() {}
        
        static func loggedAs(user: String) -> String {
            return String(format: NSLocalizedString("account.loggedAs", comment: "The string for alert saying You are logged as 'user'"), user)
        }
        
        static let viewAccount = NSLocalizedString("account.view", comment: "Button to view account")
        static let logout = NSLocalizedString("account.logout", comment: "Logout button")
        
        static let login = NSLocalizedString("account.login", comment: "Login")
        static let register = NSLocalizedString("account.register", comment: "Register")
        
        static let loginAlertMessage = NSLocalizedString("account.loginAlertMessage", comment: "The message for the login alert message")
        
        static let errorLogingIn = NSLocalizedString("account.errorLogingIn", comment: "Title for error loging in")
        static let errorCreatingAccount = NSLocalizedString("account.errorCreatingAccount", comment: "Title for error creating an account")
        static let emptyData = NSLocalizedString("account.emptyData", comment: "Empty data error at loging in")
    }
    
    class ExportToXcodeActivity {
        private init() { }
    }
    
    class Terminal {
        private init() {}
        
        static let title = NSLocalizedString("terminal.output", comment: "Title shown in Terminal")
    }
    
    class Store {
        private init() {}
        
        static let setupServer = NSLocalizedString("store.setupServer", comment: "Title for Setup a server button in the store")
        
        static let sale = NSLocalizedString("store.sale", comment: "Title for store in the sale section")
        static let unlimited = NSLocalizedString("store.unlimited", comment: "Unlimited product")
        static let watchVideo = NSLocalizedString("store.watchVideo", comment: "Title for button to watch a video")
        
        static let programs = NSLocalizedString("store.programs", comment: "Title for store in the programs section")
        static let run = NSLocalizedString("store.run", comment: "Title for button to run a program")
        static let source = NSLocalizedString("store.source", comment: "Title for button to view the source code of a project")
        
        static let challenges = NSLocalizedString("store.challenges", comment: "Title for store in the challenges section")
        static let `try` = NSLocalizedString("store.try", comment: "Title for button to try a challenge")
        
        static let leaderboard = NSLocalizedString("store.leaderboard", comment: "Title for store in the leaderboard section")
        
        static let account = NSLocalizedString("store.account", comment: "Title for button to view account in the store")
    }
    
    class Editor {
        private init() {}
        
        static let copy = NSLocalizedString("editor.copy", comment: "Copy button in editor")
        static let paste = NSLocalizedString("editor.paste", comment: "Paste button in editor")
        
        static let templates = NSLocalizedString("editor.templates", comment: "Templates button in editor")
        
        class SaveFileAlert {
            
            private init() {}
            
            static let title = NSLocalizedString("editor.saveFile.title", comment: "Alert title asking if the user wants to save the file")
            static let message = NSLocalizedString("editor.saveFile.message", comment: "Alert message asking if the user wants to save the file")
            
            static let save = NSLocalizedString("editor.saveFile.save", comment: "Button to save file")
            static let dontSave = NSLocalizedString("editor.saveFile.dontSave", comment: "Button to not save file")
        }
        
        class Organizer {
            private init() {}
            
            static let title = NSLocalizedString("editor.organizer.title", comment: "Title for the organizer inside the editor")
        }
    }
}
