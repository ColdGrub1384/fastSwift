//
//  Strings.swift
//  fastSwift
//
//  Created by Adrian on 27.11.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import Foundation

class Strings {
    static let yes = NSLocalizedString("yes", comment: "")
    static let no = NSLocalizedString("no", comment: "")
    
    class Terminal {
        static let title = NSLocalizedString("terminal.output", comment: "Title shown in Terminal")
    }
    
    class Store {
        
        static let setupServer = NSLocalizedString("store.setupServer", comment: "Title for Setup a server button in the store")
        
        static let sale = NSLocalizedString("store.sale", comment: "Title for store in the sale section")
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
        static let copy = NSLocalizedString("editor.copy", comment: "Copy button in editor")
        static let paste = NSLocalizedString("editor.paste", comment: "Paste button in editor")
        
        static let templates = NSLocalizedString("editor.templates", comment: "Templates button in editor")
        
        class Organizer {
            static let title = NSLocalizedString("editor.organizer.title", comment: "Title for the organizer inside the editor")
        }
    }
}
