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
    var alternateIcon: String?
    
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
            alternateIcon = nil
        case "white":
            color = .white
            tintColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            textColor = .black
            barStyle = .default
            codeEditorTheme = CodeEditorTheme(themeName: "xcode", backgroundColor: color)
            keyboardAppearance = .light
            statusBarStyle = .default
            browserUserInterfaceStyle = .white
            alternateIcon = "White"
        case "custom": // Setup custom theme from settings
            var str_color = UserDefaults.standard.string(forKey: "ct_color")
            var str_tint = UserDefaults.standard.string(forKey: "ct_tint")
            var str_text = UserDefaults.standard.string(forKey: "ct_text")
            var str_bar = UserDefaults.standard.string(forKey: "ct_bar")
            var str_editorTheme = UserDefaults.standard.string(forKey: "ct_etheme")
            var str_editorBack = UserDefaults.standard.string(forKey: "ct_eback")
            var str_keyboard = UserDefaults.standard.string(forKey: "ct_keyboard")
            var str_statusBar = UserDefaults.standard.string(forKey: "ct_sbar")
            var str_browser = UserDefaults.standard.string(forKey: "ct_browser")
            var str_icon = UserDefaults.standard.string(forKey: "ct_icon")
            
            if str_color == nil {
                str_color = "dark"
            }
            
            if str_tint == nil {
                str_tint = "orange"
            }
            
            if str_text == nil {
                str_text = "white"
            }
            
            if str_bar == nil {
                str_bar = "default"
            }
            
            if str_editorTheme == nil {
                str_editorTheme = "androidstudio"
            }
            
            if str_editorBack == nil {
                str_editorBack = "dark"
            }
            
            if str_keyboard == nil {
                str_keyboard = "dark"
            }
            
            if str_statusBar == nil {
                str_statusBar = "light"
            }
            
            if str_browser == nil {
                str_browser = "dark"
            }
            
            switch str_color {
            case "dark"?:
                color = #colorLiteral(red: 0.1489986479, green: 0.1490316391, blue: 0.1489965916, alpha: 1)
            case "black"?:
                color = .black
            case "white"?:
                color = .white
            case "red"?:
                color = .red
            case "green"?:
                color = .green
            case "blue"?:
                color = .blue
            case "cyan"?:
                color = .cyan
            case "brown"?:
                color = .brown
            case "yellow"?:
                color = .yellow
            case "gray"?:
                color = .gray
            case "orange"?:
                color = .orange
            default:
                color = .white
            }
            
            switch str_tint {
            case "default"?:
                tintColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            case "black"?:
                tintColor = .black
            case "white"?:
                tintColor = .white
            case "red"?:
                tintColor = .red
            case "green"?:
                tintColor = .green
            case "blue"?:
                tintColor = .blue
            case "cyan"?:
                tintColor = .cyan
            case "brown"?:
                tintColor = .brown
            case "yellow"?:
                tintColor = .yellow
            case "gray"?:
                tintColor = .gray
            case "orange"?:
                tintColor = .orange
            default:
                tintColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            }
            
            switch str_text {
            case "black"?:
                textColor = .black
            case "white"?:
                textColor = .white
            case "red"?:
                textColor = .red
            case "green"?:
                textColor = .green
            case "blue"?:
                textColor = .blue
            case "cyan"?:
                textColor = .cyan
            case "brown"?:
                textColor = .brown
            case "yellow"?:
                textColor = .yellow
            case "gray"?:
                textColor = .gray
            case "orange"?:
                textColor = .orange
            default:
                textColor = .black
            }
            
            switch str_bar {
            case "black"?:
                barStyle = .black
            case "black Opaque"?:
                barStyle = .blackOpaque
            case "black Translucent"?:
                barStyle = .blackTranslucent
            case "default"?:
                barStyle = .default
            default:
                barStyle = .default
            }
            
            var editorBack = UIColor.black
            
            switch str_editorBack {
            case "dark"?:
                editorBack = #colorLiteral(red: 0.1489986479, green: 0.1490316391, blue: 0.1489965916, alpha: 1)
            case "black"?:
                editorBack = .black
            case "white"?:
                editorBack = .white
            case "red"?:
                editorBack = .red
            case "green"?:
                editorBack = .green
            case "blue"?:
                editorBack = .blue
            case "cyan"?:
                editorBack = .cyan
            case "brown"?:
                editorBack = .brown
            case "yellow"?:
                editorBack = .yellow
            case "gray"?:
                editorBack = .gray
            case "orange"?:
                editorBack = .orange
            default:
                editorBack = .white
            }
            
            codeEditorTheme = CodeEditorTheme(themeName: str_editorTheme!, backgroundColor: editorBack)
            
            if str_keyboard == "light" {
                keyboardAppearance = .light
            } else {
                keyboardAppearance = .dark
            }
            
            if str_statusBar == "light" {
                statusBarStyle = .lightContent
            } else {
                statusBarStyle = .default
            }
            
            if str_browser == "dark" {
                browserUserInterfaceStyle = .dark
            } else if str_browser == "white" {
                browserUserInterfaceStyle = .white
            } else {
                browserUserInterfaceStyle = .light
            }
            
            if str_icon == "dark" {
                str_icon = nil
            }
            
            alternateIcon = str_icon
            
        default:
            color = .clear
            tintColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            textColor = .black
            barStyle = .default
            codeEditorTheme = CodeEditorTheme(themeName: "github-gist", backgroundColor: color)
            keyboardAppearance = .default
            statusBarStyle = .default
            browserUserInterfaceStyle = .light
            alternateIcon = nil
            
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
