//
//  ExportToXcodeViewController.swift
//  fastSwift
//
//  Created by Adrian on 08.07.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import Zip

class ExportToXcodeViewController: UIViewController, UITextFieldDelegate {
    
    var delegate: OrganizerTableViewController?
    
    @IBOutlet weak var displayName: UITextField!
    @IBOutlet weak var bundleID: UITextField!
    @IBOutlet weak var version: UITextField!
    @IBOutlet weak var build: UITextField!
    
    @IBOutlet weak var doneBtn: UIBarButtonItem!
    @IBOutlet weak var info: UIBarButtonItem!
    
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var bundleIDLabel: UILabel!
    @IBOutlet weak var VersionLabel: UILabel!
    @IBOutlet weak var buildLabel: UILabel!
    @IBOutlet weak var note: UILabel!
    @IBOutlet weak var navBar: UINavigationBar!
    
    
    func text(forTextField textField:UITextField) -> String {
        let text = textField.text
        let placeholder = textField.placeholder
        
        if (text?.isEmpty)! {
            return placeholder!
        } else {
            return text!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayName.placeholder = delegate!.delegate!.document!.fileURL.deletingPathExtension().lastPathComponent
        view.backgroundColor = AppDelegate.shared.theme.color
        navBar.barTintColor = AppDelegate.shared.theme.color
        navBar.barStyle = AppDelegate.shared.theme.barStyle
        view.tintColor = AppDelegate.shared.theme.tintColor
        
        let labels = [displayNameLabel, bundleIDLabel, VersionLabel, buildLabel, note]
        for label in labels {
            label?.textColor = AppDelegate.shared.theme.textColor
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppDelegate.shared.theme.statusBarStyle
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func done(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func export(_ sender: Any) {
        let alert = ActivityViewController(message: "Generating project...")
        self.present(alert, animated: true, completion: nil)
        DispatchQueue.global(qos: .background).async {
            if let delegate = self.delegate {
                let files = delegate.delegate!.files
                Debugger.shared.debug_(files)
                do {
                    let docs = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0]
                    var fileURL = docs.appendingPathComponent(delegate.delegate!.document!.fileURL.deletingPathExtension().lastPathComponent).appendingPathExtension("xc")
                    Debugger.shared.debug_(fileURL.absoluteString)
                    try FileManager.default.copyItem(at: Bundle.main.url(forResource: "Samples/fastSwift App", withExtension: "zip")!, to: fileURL.deletingLastPathComponent().appendingPathComponent("\(fileURL.lastPathComponent).zip"))
                    
                    var projectHiercarchyURL = try Zip.quickUnzipFile(fileURL.deletingLastPathComponent().appendingPathComponent("\(fileURL.lastPathComponent)").appendingPathExtension("zip"))
                    projectHiercarchyURL = projectHiercarchyURL.appendingPathComponent("fastSwift App").appendingPathComponent("fastSwift App")
                    let sourceURL = projectHiercarchyURL.appendingPathComponent("Source")
                    let plist = projectHiercarchyURL.appendingPathComponent("Info.plist")
                    
                    for file in files {
                        let fileName = file.lastPathComponent
                        if file != delegate.delegate!.document?.fileURL {
                            do {
                                try FileManager.default.copyItem(at: file, to: sourceURL.appendingPathComponent(fileName))
                            } catch let error {
                                Debugger.shared.debug_("Error copying to project! \(error.localizedDescription)")
                                self.dismiss(animated: true, completion: {
                                    AlertManager.shared.present(error: error, withTitle: "Error copying to project!", inside: self)
                                })
                            }
                        } else {
                            do {
                                try FileManager.default.copyItem(at: file, to: sourceURL.appendingPathComponent("main.swift"))
                            } catch let error {
                                Debugger.shared.debug_("Error copying to project! \(error.localizedDescription)")
                                self.dismiss(animated: true, completion: {
                                    AlertManager.shared.present(error: error, withTitle: "Error copying to project!", inside: self)
                                })
                            }
                        }
                    }
                    
                    let plistFile = Document(fileURL: plist)
                    let plistContent = plistFile.code
                    var newPlistContent = plistContent
                    
                    newPlistContent = newPlistContent.replacingOccurrences(of: "DISPLAYNAME", with: self.text(forTextField: self.displayName))
                    newPlistContent = newPlistContent.replacingOccurrences(of: "BUNDLEID", with: self.text(forTextField: self.bundleID))
                    newPlistContent = newPlistContent.replacingOccurrences(of: "VERSION", with: self.text(forTextField: self.version))
                    newPlistContent = newPlistContent.replacingOccurrences(of: "BUILD", with: self.text(forTextField: self.build))
                    
                    do {
                        try newPlistContent.write(to: plist, atomically: true, encoding: .utf8)
                    } catch let error {
                        Debugger.shared.debug_("Error writing to plist file! \(error.localizedDescription)")
                        self.dismiss(animated: true, completion: {
                            AlertManager.shared.present(error: error, withTitle: "Error writing to plist file!", inside: self)
                        })
                    }
                    
                    do {
                        try FileManager.default.removeItem(at: fileURL.appendingPathExtension("zip"))
                        if !FileManager.default.fileExists(atPath: fileURL.deletingPathExtension().path) {
                            try FileManager.default.moveItem(at: fileURL, to: fileURL.deletingPathExtension())
                            fileURL = fileURL.deletingPathExtension()
                        }
                        let zipURL = try Zip.quickZipFiles([fileURL], fileName: fileURL.deletingPathExtension().lastPathComponent)
                        try FileManager.default.removeItem(at: fileURL)
                        let vc = UIActivityViewController(activityItems: [zipURL], applicationActivities: nil)
                        self.dismiss(animated: true, completion: {
                            self.present(vc, animated: true, completion: nil)
                        })
                    } catch let error {
                        Debugger.shared.debug_("Error zipping file! \(error.localizedDescription)")
                        self.dismiss(animated: true, completion: {
                            AlertManager.shared.present(error: error, withTitle: "Error zipping file!", inside: self)
                        })
                    }
                    
                } catch let error {
                    Debugger.shared.debug_("Error copying project! \(error.localizedDescription)")
                    self.dismiss(animated: true, completion: {
                        AlertManager.shared.present(error: error, withTitle: "Error copying project!", inside: self)
                    })
                }
            }
        }
    }
    
}
