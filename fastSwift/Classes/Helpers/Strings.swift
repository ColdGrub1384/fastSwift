//
//  Strings.swift
//  fastSwift
//
//  Created by Adrian on 27.11.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class LocalizedGuide {
    var title: String
    var message: String
    
    init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}

class Strings {
    
    private init() {}
    
    static let language = NSLocalizedString("language", comment: "")
    
    static let yes = NSLocalizedString("yes", comment: "")
    static let no = NSLocalizedString("no", comment: "")
    static let cancel = NSLocalizedString("cancel", comment: "")
    
    static let retry = NSLocalizedString("retry", comment: "")
    
    static let uploading = NSLocalizedString("uploading", comment: "")
    
    static let errorSavingFile = NSLocalizedString("errorSavingFile", comment: "")
    
    static let errorPurchasingUnlimited = NSLocalizedString("errorPurchasingUnlimited", comment: "Title for error purchasing unlimited compilations")
    
    static let save = NSLocalizedString("save", comment: "")
    static let dontSave = NSLocalizedString("dontSave", comment: "")
    
    static let downloading = NSLocalizedString("downloading", comment: "Downloading file")
    
    static let error = NSLocalizedString("error", comment: "Error")
    
    class NoMoreCompilationsAlert {
        static let title = NSLocalizedString("noMoreCompilations.title", comment: "No more compilations alert title")
        static let message = NSLocalizedString("noMoreCompilations.message", comment: "No more compilations alert message")
    }
    
    static let compressing = NSLocalizedString("compressing", comment: "Title for alert shown when compressing file")
    
    static let emptyData = NSLocalizedString("emptyData", comment: "Empty data error")
    
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
    }
    
    class noMainFileAlert {
        private init() {}
        
        static let title = NSLocalizedString("noMainFile.title", comment: "Title for alert saying that is not main file selected in the organizer")
        static let message = NSLocalizedString("noMainFile.message", comment: "Message for alert saying that is not main file selected in the organizer")
    }
    
    class ExportToBinaryActivity {
        private init() {}
        
        static let title = NSLocalizedString("exportToBinary.title", comment: "Title for export to binary activity")
        
        class CantDownloadBinaryAlert {
            private init () {}
            
            static let title = NSLocalizedString("binaryDownloadError.title", comment: "Title for alert shown when trying to download a binary from custom server")
            static let message = NSLocalizedString("binaryDownloadError.message", comment: "Message for alert shown when trying to download a binary from custom server")
        }
    }
    
    class ExportToXcodeActivity {
        private init() {}
        
        static let title = NSLocalizedString("exportToXcode.title", comment: "Title for Export to Xcode activity")
    }
    
    class PublishToStoreActivity {
        private init() {}
        
        static let title = NSLocalizedString("publishToStore.title", comment: "Title for Publish to Store activity")
        
        class Errors {
            private init() {}
            
            static let errorPublishing = NSLocalizedString("publishToStore.error", comment: "Error publishing project")
            static let errorAddingToDatabase = NSLocalizedString("publishToStore.errorAddingToDatabase", comment: "Error adding script to database")
        }
        
        class PublishedAlert {
            private init() {}
            
            static let title = NSLocalizedString("publishToStore.published.title", comment: "Title for alert shown when a script was published")
            static func message(withHost host: String) -> String {
                return String(format: NSLocalizedString("publishToStore.published.message", comment: "Message for alert shown when a script was published"), host)
            }
        }
    }
    
    class ExportToXcode {
        private init() {}
        
        static let title = NSLocalizedString("exportToXcodeVC.title", comment: "Title for ExportToXcodeViewController")
        
        static let displayName = NSLocalizedString("exportToXcodeVC.displayName", comment: "Display name field")
        static let bundleID = NSLocalizedString("exportToXcodeVC.bundleID", comment: "Bundle ID field")
        static let version = NSLocalizedString("exportToXcodeVC.version", comment: "Version field")
        static let build = NSLocalizedString("exportToXcodeVC.build", comment: "Build field")
        
        static let note = NSLocalizedString("exportToXcodeVC.note", comment: "Note saying what file open")
        
        static let export = NSLocalizedString("exportToXcodeVC.export", comment: "Export button")
    }
    
    class ExportToXcodeHelp {
        private init() {}
        
        static func textView(`for` viewController: ExportToXcodeHelpViewController) -> UITextView {
            
            switch Strings.language {
            default:
                return viewController.textView
            }
        }
        
        static let title = NSLocalizedString("exportToXcodeHelp.title", comment: "Title for Export to Xcode Help")
    }
    
    class ConnectionError {
        private init() {}
        
        static let title = NSLocalizedString("connectionError.title", comment: "Connection error title")
        
        static let serverSettings = NSLocalizedString("connectionError.settings", comment: "Open server settings")
        
        class Errors {
            private init() {}
            
            static var errorForCustomServer: String {
                return String(format: NSLocalizedString("connectionError.errorCustomServer", comment: "Error connecting to the custom server"), Server.host)
            }
            
            static var errorForDefaultServer: String {
                return String(format: NSLocalizedString("connectionError.defaultServer", comment: "Error connecting to the default server"), Server.host)
            }
        }
    }
    
    class Camera {
        private init() {}
        
        class DetectedServerAlert {
            private init() {}
            
            static let title = NSLocalizedString("camera.detectedServerAlert.title", comment: "Title for alert shown when a server is detected")
            static func message(withUsername username: String, host: String, password: String) -> String {
                return String(format: NSLocalizedString("camera.detectedServerAlert.message", comment: "Message for alert shown when a server is detected"), username, host, password)
            }
        }
        
        class DetectedScriptAlert {
            private init() {}
            
            static let title = NSLocalizedString("camera.detectedScriptAlert.title", comment: "Title for alert shown when a script is detected")
            static let message = NSLocalizedString("camera.detectedScriptAlert.message", comment: "Message for alert shown when a script is detected")
            
            class Errors {
                static let errorMovingFile = NSLocalizedString("camera.detectedScriptAlert.errors.errorMovingFile", comment: "Error moving file")
                static let errorDownloadingFile = NSLocalizedString("camera.detectedScriptAlert.errors.errorDownloadingFile", comment: "Error downloading file")
            }
        }
    }
    
    class Guides {
        private init() {}
        
        static let sections = LocalizedGuide(title: NSLocalizedString("guides.sections.title", comment: "Title for Sections guide"), message: NSLocalizedString("guides.sections.text", comment: "Text for Sections guide"))
        
        static let browser = LocalizedGuide(title: NSLocalizedString("guides.browser.title", comment: "Title for Browser guide"), message: NSLocalizedString("guides.browser.text", comment: "Text for Browser guide"))
        
        static let editor = LocalizedGuide(title: NSLocalizedString("guides.editor.title", comment: "Title for Editor guide"), message: NSLocalizedString("guides.editor.text", comment: "Text for Editor guide"))
        
        static let editorFeatures = LocalizedGuide(title: NSLocalizedString("guides.editorFeatures.title", comment: "Title for Editor Features guide"), message: NSLocalizedString("guides.editorFeatures.text", comment: "Text for Editor Features guide"))
        
        static let shop = LocalizedGuide(title: NSLocalizedString("guides.shop.title", comment: "Title for Shop guide"), message: NSLocalizedString("guides.shop.text", comment: "Text for Shop guide"))
        
        
        static let challlenges = LocalizedGuide(title: NSLocalizedString("guides.challenges.title", comment: "Title for Challenges guide"), message: NSLocalizedString("guides.challenges.text", comment: "Text for Challenges guide")
    }
    
    class SetupServer {
        private init() {}
        
        static let title = NSLocalizedString("setupServer.title", comment: "Title for SetupServerViewController")
        
        static let ip = NSLocalizedString("setupServer.ip", comment: "IP field")
        static let username = NSLocalizedString("setupServer.username", comment: "Username field")
        static let password = NSLocalizedString("setupServer.password", comment: "Password field")
        
        static let setup = NSLocalizedString("setupServer.setup", comment: "Setup button")
        
        static let requisites = NSLocalizedString("setupServer.requisites", comment: "Requisites to setup server")
        
        class States {
            private init() {}
            
            static let readyToInstall = NSLocalizedString("setuptServer.states.ready", comment: "Ready to install")
            static let connected = NSLocalizedString("setuptServer.states.connected", comment: "Connected")
            static let loggedIn = NSLocalizedString("setupServer.states.loggedIn", comment: "Logged in")
            static let installing = NSLocalizedString("setuptServer.states.installing", comment: "Installing")
            static let swiftNotInstalled = NSLocalizedString("setuptServer.states.swiftNotFound", comment: "Swift is not installed")
            static let installed = NSLocalizedString("setuptServer.states.installed", comment: "Installed")
            static let cantLogin = NSLocalizedString("setuptServer.states.cantLogin", comment: "Cant Login")
            static let cantConnect = NSLocalizedString("setuptServer.states.cantConnect", comment: "Cant connect")
            static let failedToCreateHomeSwiftexec = NSLocalizedString("setupServer.states.failedToCreateHomeSwiftexec", comment: "Failed to create /home/swiftexec")
            static let failedToCreateSwiftexec = NSLocalizedString("setuptServer.states.failedToCreateSwiftexec", comment: "Failed to create user swiftexec")
        }
        
        class CreatedServerAlert {
            private init() {}
            
            static let title = NSLocalizedString("setupServer.createServerAlert.title", comment: "Title for alert shown when the server was created")
            static func message(forHost host: String) -> String {
                return String(format: NSLocalizedString("setupServer.createServerAlert.message", comment: "Message for alert shown when the server was created"), host)
            }
        }
    }
    
    class ErrorLoadingStore {
        private init() {}
        
        static let title = NSLocalizedString("errorLoadingStore.title", comment: "Title for ErrorLoadingStoreViewController")
        
        class SaveFileAlert {
            static let title = NSLocalizedString("errorLoadingStore.saveFileAlert.title", comment: "Title for alert shown when a file was changed and need to be saved before reload the app")
            static let message = NSLocalizedString("errorLoadingStore.saveFileAlert.message", comment: "Message for alert shown when a file was changed and need to be saved before reload the app")
        }
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
        
        static let chooseTemplate = NSLocalizedString("editor.chooseTemplate", comment: "Choose template title alert")
        
        class SaveFileAlert {
            
            private init() {}
            
            static let title = NSLocalizedString("editor.saveFile.title", comment: "Alert title asking if the user wants to save the file")
            static let message = NSLocalizedString("editor.saveFile.message", comment: "Alert message asking if the user wants to save the file")
        }
        
        class Organizer {
            private init() {}
            
            static let title = NSLocalizedString("editor.organizer.title", comment: "Title for the organizer inside the editor")
        }
    }
}
