//
//  OrganizerTableViewController.swift
//  fastSwift
//
//  Created by Adrian on 23.06.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import Zip
import NMSSH

class OrganizerTableViewController: UITableViewController {
    var delegate: DocumentViewController?
    
    func downloadBinary() {
        self.dismiss(animated: true) {
            if AccountManager.shared.compilations <= 0 {
                AlertManager.shared.presentAlert(withTitle: "No enough 🐧", message: "Buy 🐧 to compile scripts", style: .alert, actions: [AlertManager.shared.ok(handler: nil)], inside: self.delegate!, animated: true, completion: nil)
            } else {
                self.delegate?.Compile(true)
            }
        }
    }
    
    @objc func share() {
        DispatchQueue.main.async {
            self.present(ActivityViewController.init(message: "Compressing.."), animated: true, completion: nil)
            do {
                let newFilePath = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!.appendingPathComponent(self.delegate!.document!.fileURL.deletingPathExtension().lastPathComponent).path
                if FileManager.default.fileExists(atPath: newFilePath) {
                    try FileManager.default.removeItem(at: URL(fileURLWithPath:newFilePath))
                }
                
                for file in self.delegate!.files {
                    if file != self.delegate!.document?.fileURL {
                        let newDocument = Document(fileURL:file)
                        newDocument.open(completionHandler: nil)
                    }
                }
                
                let file = try Zip.quickZipFiles(self.delegate!.files, fileName: self.delegate!.document!.fileURL.deletingPathExtension().lastPathComponent)
                
                self.dismiss(animated: true, completion: {
                    for file in self.delegate!.files {
                        if file != self.delegate!.document?.fileURL {
                            let newDocument = Document(fileURL:file)
                            newDocument.close(completionHandler: nil)
                        }
                    }
                    let xcode = ExportToXcodeActivty()
                    if let _ = self.delegate {
                        xcode.delegate = self
                    }
                    
                    let bin = ExportToBinaryActivity()
                    if let _ = self.delegate {
                        bin.delegate = self
                    }
                    
                    let vc = UIActivityViewController(activityItems: [file], applicationActivities: [xcode, bin])
                    self.present(vc, animated: true, completion: nil)
                })
            } catch let error {
                Debugger.shared.debug_("Error! \(error.localizedDescription)")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .action, target: self, action: #selector(share))
        self.navigationItem.rightBarButtonItem?.tintColor = .orange
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (delegate?.files.count)!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        for cell in tableView.visibleCells {
            cell.accessoryType = .none
        }
        
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        tableView.deselectRow(at: indexPath, animated: true)
        
        
        
        func change() {
            
            let selected = delegate?.files[indexPath.row]
            delegate?.files.remove(at: indexPath.row)
            delegate?.files.insert(selected!, at: 0)
            delegate?.document = Document(fileURL: selected!)
            
            if self.delegate?.autoCompilationState == .userActionNeed {
                self.delegate?.autoCompilationState = .ready
            }
            
            delegate?.viewDidLoad()
        }
        
        
        if delegate?.code.text.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "") != delegate?.document?.code.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "") {
            AlertManager.shared.presentAlert(withTitle: "Do you want to save the file", message: "If you select \"Don't save\", all changes will be erased!", style: .alert, actions:
                [
                    UIAlertAction.init(title: "Don't save", style: .destructive, handler: { (action) in
                        self.delegate?.document?.close(completionHandler: nil)
                        if (self.delegate?.firstLaunch)! {
                            self.delegate?.firstLaunch = false
                            self.dismiss(animated: true, completion: nil)
                        }
                        
                        change()
                    }),
                    UIAlertAction.init(title: "Save", style: .default, handler: { (action) in
                        do {
                            try self.delegate?.code.text.write(to: (self.delegate?.document?.fileURL)!, atomically: true, encoding: String.Encoding.utf8)
                        } catch let error {
                            AlertManager.shared.present(error: error, withTitle: "Error saving file!", inside: self)
                        }
                        self.delegate?.document?.close(completionHandler: nil)
                        
                        if (self.delegate?.firstLaunch)! {
                            self.delegate?.firstLaunch = false
                            self.dismiss(animated: true, completion: nil)
                        }
                        
                        change()
                    }),
                    AlertManager.shared.cancel
                ]
                , inside: self, animated: true, completion: nil)
        } else {
            self.delegate?.document?.close(completionHandler: nil)
            if (self.delegate?.firstLaunch)! {
                self.delegate?.firstLaunch = false
                self.dismiss(animated: true, completion: nil)
            }
            change()
        }
        
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "file")
        (cell?.viewWithTag(1) as! UILabel).text = delegate?.files[indexPath.row].deletingPathExtension().lastPathComponent
        
        if delegate?.files[indexPath.row] == delegate?.files.first! {
            if !(delegate?.firstLaunch)! {
                cell?.accessoryType = .checkmark
            }
        } else {
            cell?.accessoryType = .none
        }
        
        return cell!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "xcode" {
            let vc = segue.destination as! ExportToXcodeViewController
            vc.delegate = self
        }
    }
}
