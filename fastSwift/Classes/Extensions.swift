//
//  Extensions.swift
//  fastSwift
//
//  Created by Adrian on 20.10.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import NMSSH


extension AppDelegate {
    var isFirstLaunch: Bool {
        let value = UserDefaults.standard.bool(forKey: "launched")
        
        for argument in CommandLine.arguments {
            if argument == "firstLaunch" {
                return true
            }
        }
        
        return value.inverted
    }
}

extension Bool {
    var inverted: Bool {
        if self {
            return false
        } else {
            return true
        }
    }
}

extension String {
    
    var attributedStringFromHTML: NSAttributedString? {
        do {
            let atri = try NSAttributedString(data: self.data(using: .utf8)!, options: [NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
            return atri
        } catch _ {
            return nil
        }
    }
    
    func slice(from: String, to: String) -> String? { // "<>Something</>".slice(from: "<>", to: "</>") = "Something"
        
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
    
    func replacingFirstOccurrence(of target: String, with replaceString: String) -> String { // Replace only the first occurrence in a string
        if let range = self.range(of: target) {
            return self.replacingCharacters(in: range, with: replaceString)
        }
        return self
    }
    
    func occurrences(of text:String) -> Int { // Count of occurrences in a string
        let tok = self.components(separatedBy: text)
        return tok.count-1
    }
    
    func addingPercentEncodingForURLQueryValue() -> String? { // Add percent encoding for URL queries
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
            
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
    
    var values: String {
        var text = self
        var vars = ""
        
        text = text.replacingOccurrences(of: ";", with: "\n")
        let lines = text.components(separatedBy: "\n")
        
        for line in lines {
            
            let line_ = line.replacingOccurrences(of: " ", with: "")
            
            print("Code: \(line_)")
            
            if line_.hasPrefix("var") || line_.hasPrefix("let") { // Variables, constants
                var var_ = line.components(separatedBy: " ")
                if var_.count >= 2 {
                    if !vars.contains("\n\(var_[1])") {
                        vars.append("\n\(var_[1])")
                    }
                }
            }
            
            if line_.hasPrefix("func") || line_.hasPrefix("struct") { // Functions and structs
                var var_ = line.components(separatedBy: " ")
                if var_.count >= 2 {
                    if let rest = slice(from: var_[1], to: "{") {
                        if !vars.contains("\n\(var_[1])\(rest)".replacingOccurrences(of: ":", with: ": ")) {
                            vars.append("\n\(var_[1])\(rest)".replacingOccurrences(of: ":", with: ": "))
                        }
                        
                    }
                    
                }
            }
        }
        
        print("vars: \(vars)")
        
        //let ansiHelper = ANSIEscapeHelper()
        
        return vars
    }


}

extension UITextView {
    var afterCursor: String? { // Character after the cursor of a textview
        if let cursorRange = self.selectedTextRange {
            if let newPosition = self.position(from: cursorRange.start, offset: +1) {
                let range = self.textRange(from: newPosition, to: cursorRange.start)
                return self.text(in: range!)
            }
        }
        return nil
    }
    
    var currentWord : String {
        
        let beginning = beginningOfDocument
        
        if let start = position(from: beginning, offset: selectedRange.location),
            let end = position(from: start, offset: selectedRange.length) {
            
            let textRange = tokenizer.rangeEnclosingPosition(end, with: .word, inDirection: 1)
            
            if let textRange = textRange {
                return text(in: textRange)!
            }
        }
        return ""
    }
    
    var currentWordRange : UITextRange? {
        
        let beginning = beginningOfDocument
        
        if let start = position(from: beginning, offset: selectedRange.location),
            let end = position(from: start, offset: selectedRange.length) {
            
            let textRange = tokenizer.rangeEnclosingPosition(end, with: .word, inDirection: 1)
            
            if let textRange = textRange {
                return textRange
            }
        }
        return nil
    }

}

extension UITextInput {
    var selectedRange: NSRange? { // Get Range of selected text in a textview
        guard let range = self.selectedTextRange else { return nil }
        let location = offset(from: beginningOfDocument, to: range.start)
        let length = offset(from: range.start, to: range.end)
        return NSRange(location: location, length: length)
    }
}

extension UIColor {
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(
            format: "%02X%02X%02X",
            Int(r * 0xff),
            Int(g * 0xff),
            Int(b * 0xff)
        )
    }
}

