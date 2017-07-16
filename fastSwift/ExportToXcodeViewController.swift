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
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
                print(files)
                do {
                    let docs = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0]
                    let fileURL = docs.appendingPathComponent(delegate.delegate!.document!.fileURL.deletingPathExtension().lastPathComponent)
                    let projectHiercarchyURL = fileURL.appendingPathComponent("fastSwift App")
                    let sourceURL = projectHiercarchyURL.appendingPathComponent("Source")
                    let plist = projectHiercarchyURL.appendingPathComponent("Info.plist")
                    
                    try FileManager.default.copyItem(at: Bundle.main.url(forResource: "Samples/fastSwift App", withExtension: nil)!, to: fileURL)
                    
                    for file in files {
                        let fileName = file.lastPathComponent
                        if file != delegate.delegate!.document?.fileURL {
                            do {
                                try FileManager.default.copyItem(at: file, to: sourceURL.appendingPathComponent(fileName))
                            } catch let error {
                                print("Error copying to project! \(error.localizedDescription)")
                                self.dismiss(animated: true, completion: {
                                    AlertManager.shared.present(error: error, withTitle: "Error copying to project!", inside: self)
                                })
                            }
                        } else {
                            do {
                                try FileManager.default.copyItem(at: file, to: sourceURL.appendingPathComponent("main.swift"))
                            } catch let error {
                                print("Error copying to project! \(error.localizedDescription)")
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
                        print("Error writing to plist file! \(error.localizedDescription)")
                        self.dismiss(animated: true, completion: {
                            AlertManager.shared.present(error: error, withTitle: "Error writing to plist file!", inside: self)
                        })
                    }
                    
                    do {
                        let zipURL = try Zip.quickZipFiles([fileURL], fileName: fileURL.deletingPathExtension().lastPathComponent)
                        try FileManager.default.removeItem(at: fileURL)
                        let vc = UIActivityViewController(activityItems: [zipURL], applicationActivities: nil)
                        self.dismiss(animated: true, completion: {
                            self.present(vc, animated: true, completion: nil)
                        })
                    } catch let error {
                        print("Error zipping file! \(error.localizedDescription)")
                        self.dismiss(animated: true, completion: {
                            AlertManager.shared.present(error: error, withTitle: "Error zipping file!", inside: self)
                        })
                    }
                    
                } catch let error {
                    print("Error copying project! \(error.localizedDescription)")
                    self.dismiss(animated: true, completion: {
                        AlertManager.shared.present(error: error, withTitle: "Error copying project!", inside: self)
                    })
                }
            }
        }
    }
    
}
