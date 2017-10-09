//
//  Theme.swift
//  fastSwift
//
//  Created by Adrian on 07.10.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class Theme {
    static var black = Theme(name:"black")
    static var white = Theme(name:"white")
    static var null = Theme()
    
    var color: UIColor
    var tintColor: UIColor
    var name: String
    var textColor: UIColor
    var barStyle: UIBarStyle
    var codeEditorTheme: CodeEditorTheme
    var keyboardAppearance: UIKeyboardAppearance
    var statusBarStyle: UIStatusBarStyle
    var browserUserInterfaceStyle: UIDocumentBrowserViewController.BrowserUserInterfaceStyle
    
    init(name:String = "") {
        
        self.name = name
        
        switch name {
        case "black":
            color = #colorLiteral(red: 0.1489986479, green: 0.1490316391, blue: 0.1489965916, alpha: 1)
            tintColor = .orange
            textColor = .white
            barStyle = .black
            codeEditorTheme = CodeEditorTheme(themeName: "androidstudio", backgroundColor: color)
            keyboardAppearance = .dark
            statusBarStyle = .lightContent
            browserUserInterfaceStyle = .dark
        case "white":
            color = .white
            tintColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            textColor = .black
            barStyle = .default
            codeEditorTheme = CodeEditorTheme(themeName: "github-gist", backgroundColor: color)
            keyboardAppearance = .light
            statusBarStyle = .default
            browserUserInterfaceStyle = .white
        default:
            color = .clear
            tintColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            textColor = .black
            barStyle = .default
            codeEditorTheme = CodeEditorTheme(themeName: "github-gist", backgroundColor: color)
            keyboardAppearance = .default
            statusBarStyle = .default
            browserUserInterfaceStyle = .light
            
        }
    }
    
    var alternateIcon: String? {
        switch color {
        case #colorLiteral(red: 0.1489986479, green: 0.1490316391, blue: 0.1489965916, alpha: 1):
            return nil
        case .white:
            return "White"
        default:
            return nil
        }
    }
    
    func isEqual(to other: Theme) -> Bool {
        return (self.name == other.name && self.color == other.color && self.tintColor == other.tintColor && self.textColor == other.textColor && self.barStyle == other.barStyle && self.codeEditorTheme.isEqual(to: other.codeEditorTheme) && self.statusBarStyle == other.statusBarStyle && self.browserUserInterfaceStyle == other.browserUserInterfaceStyle)
    }
}

class CodeEditorTheme {
    var name: String
    var backgroundColor: UIColor
    
    init(themeName: String, backgroundColor: UIColor) {
        self.name = themeName
        self.backgroundColor = backgroundColor
    }
    
    func isEqual(to other: CodeEditorTheme) -> Bool {
        return (self.name == other.name && self.backgroundColor == other.backgroundColor)
    }
}
