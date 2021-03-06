//
//  DocumentBrowserViewController.swift
//  fastSwift
//
//  Created by Adrian on 10.06.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import MobileCoreServices
import QuickLook
import Zip
import NMSSH

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate, QLPreviewControllerDataSource {
    
    enum dismissStates: Int {
        case none = 0
        case ready = 1
        case done = 2
    }
        
    var open = true
    var selectedFiles = [URL]()
    var dismissState = dismissStates.none
    
    // -------------------------------------------------------------------------
    // MARK: UIViewController
    // -------------------------------------------------------------------------
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if dismissState == .done {
            print("Dismiss")
            do {
                try FileManager.default.removeItem(at: FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask)[0].appendingPathComponent("TMPEXECFILETOSEND.swiftc"))
            } catch let error {
                print("Error removing tmp file: \(error)")
            }
            self.dismiss(animated: true, completion: {
                if let menu = AppDelegate.shared.topViewController() as? MenuViewController {
                    if menu.loadedStore {
                        menu.reloadStore()
                    }
                }
            })
        }
        
        if dismissState == .ready {
            print("Dismiss state is ready")
            dismissState = .done
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        AppDelegate.shared.browser = self
                
        allowsDocumentCreation = true
        allowsPickingMultipleItems = true
        
        // Update the style of the UIDocumentBrowserViewController
        browserUserInterfaceStyle = AppDelegate.shared.theme.browserUserInterfaceStyle
        view.tintColor = AppDelegate.shared.theme.tintColor
        
        // Specify the allowed content types of your application via the Info.plist.
        
        // Do any additional setup after loading the view, typically from a nib.
        
        self.customActions = [UIDocumentBrowserAction.init(identifier: "compile", localizedTitle: "🔨", availability: .navigationBar, handler: { (urls) in
            
            if AccountManager.shared.compilations.amount <= 0 {
                AlertManager.shared.presentAlert(withTitle: "No enough 🐧", message: "You need more 🐧", style: .alert, actions: [AlertManager.shared.ok(handler: nil)], inside: self, animated: true, completion: nil)
                return
            }
            
            if urls.count == 1 {
                self.compile(urls: urls, withState: .ready)
            } else {
                print("User action need!")
                self.compile(urls: urls, withState: .userActionNeed)
            }
        })]
    }
    
    // -------------------------------------------------------------------------
    // MARK: QLPreviewControllerDelegate & QLPreviewControllerDataSource
    // -------------------------------------------------------------------------
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return selectedFiles.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return selectedFiles[index] as QLPreviewItem
    }
    
    // -------------------------------------------------------------------------
    // MARK: UIDocumentBrowserViewController
    // -------------------------------------------------------------------------
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        let docURL: URL? = Bundle.main.url(forResource: "Samples", withExtension: "")?.appendingPathComponent("Untitled.swift")
        var newDocumentURL: URL?
        
        // Set the URL for the new document here. Optionally, you can present a template chooser before calling the importHandler.
        // Make sure the importHandler is always called, even if the user cancels the creation request.
        
        let alert = AlertManager.shared.alert(withTitle: "Create a Swift file", message: "Type file's name", style: .alert, actions: [])
        alert.addAction(AlertManager.shared.ok(handler: { (action) in
            let fileName = alert.textFields![0].text!
            let tmp = URL(fileURLWithPath:NSTemporaryDirectory())
            newDocumentURL = tmp.appendingPathComponent(fileName+".swift")
            do {
                try FileManager.default.copyItem(at: docURL!, to: newDocumentURL!)
            } catch let error {
                AlertManager.shared.present(error: error, withTitle: "Error creating file!", inside: self)
                importHandler(nil, .none)
            }
            
            importHandler(newDocumentURL, .copy)
        }))
        
        alert.addTextField { (textfield) in
            textfield.placeholder = "File's name"
        }
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (action) in
            importHandler(nil, .none)
        }))
        alert.view.tintColor = AppDelegate.shared.theme.tintColor
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentURLs documentURLs: [URL]) {
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        presentDocument(at: documentURLs)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: [destinationURL])
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // -------------------------------------------------------------------------
    // MARK: Document Presentation
    // -------------------------------------------------------------------------
    
    func compile(urls: [URL], withState state:AppDelegate.autoCompilationState) {
        let documentViewController = AppViewControllers().document
        documentViewController.document = Document(fileURL: urls.first!)
        documentViewController.modalTransitionStyle = .flipHorizontal
        documentViewController.firstLaunch = true
        documentViewController.autoCompilationState = state
        
        selectedFiles = urls
        
        for url in urls {
            documentViewController.files.append(url)
        }
        
        if urls.first!.pathExtension != "swift" {
            let vc = QLPreviewController()
            vc.dataSource = self
            
            present(vc, animated: true, completion: nil)
        } else {
            present(documentViewController, animated: true, completion: nil)
        }
    }
    
    func presentDocument(at documentsURL: [URL]) {
        
        let urls = documentsURL
        
        let documentViewController = AppViewControllers().document
        documentViewController.document = Document(fileURL: urls.first!)
        documentViewController.modalTransitionStyle = .flipHorizontal
        documentViewController.firstLaunch = true
        
        selectedFiles = urls
            
        for url in urls {
            documentViewController.files.append(url)
            print("URLS: \(documentViewController.files)")
        }
            
        if urls.first!.pathExtension != "swift" {
            let vc = QLPreviewController()
            vc.dataSource = self
            
            if urls.first!.pathExtension.lowercased() == "zip" {
                do {
                    let newUnzipedFile = try Zip.quickUnzipFile(urls.first!)
                    
                    do {
                        var files = try FileManager.default.contentsOfDirectory(at: newUnzipedFile, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                        
                        for file in files {
                            if file.lastPathComponent == "__MACOSX" {
                                do {
                                    try FileManager.default.removeItem(at: file)
                                } catch let error {
                                    print("Error removing __MACOSX file: \(error.localizedDescription)")
                                }
                                
                                break
                            }
                        }
                            
                        files = try FileManager.default.contentsOfDirectory(at: newUnzipedFile, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                            
                        self.presentDocument(at: files)
                            
                    } catch let error {
                        print("Error getting content of folder: \(error)")
                    }
                } catch let error {
                    print("Error unziping files! \(error.localizedDescription)")
                }
            } else if urls.first!.pathExtension == "swiftc" {
                let alert = ActivityViewController(message: "Uploading...")
                self.present(alert, animated: true, completion: nil)
                
                let file = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first!.appendingPathComponent(urls.first!.lastPathComponent)
                
                let _ = Afte.r(1, seconds: { (timer) in
                    let session = NMSSHSession.connect(toHost: Server.host, withUsername: Server.user)
                    if (session?.isConnected)! {
                        session?.authenticate(byPassword: Server.password)
                        if (session?.isAuthorized)! {
                            Document(fileURL: urls.first!).open(completionHandler: { (success) in
                                if success {
                                    do {
                                        try FileManager.default.copyItem(at: urls.first!, to: file)
                                        try session?.channel.execute("mkdir bin; rm -rf bin/\(UIDevice.current.identifierForVendor!.uuidString); mkdir bin/\(UIDevice.current.identifierForVendor!.uuidString)")
                                    } catch _ {}
                                    
                                    let filePath = "/home/\(Server.user)/bin/\(UIDevice.current.identifierForVendor!.uuidString)/\(file.lastPathComponent)"
                                    
                                    let screenSizePath = "/home/\(Server.user)/bin/\(UIDevice.current.identifierForVendor!.uuidString)/screenSize"
                                    
                                    
                                    session?.channel.uploadFile(file.path, to: filePath)
                                    
                                    do {
                                        try session?.channel.execute("chmod +x '\(filePath)'")
                                        try FileManager.default.removeItem(at: file)
                                    } catch _ {}
                                    
                                    session?.disconnect()
                                    
                                    alert.dismiss(animated: true, completion: {
                                        let terminalViewController = AppViewControllers().terminal
                                        terminalViewController.command = "touch \(screenSizePath); echo \"\(UIScreen.main.bounds.width)\" >> \(screenSizePath); echo \"\(UIScreen.main.bounds.height)\" >> \(screenSizePath); '\(filePath)'; rm '\(filePath)'; logout"
                                        terminalViewController.user = Server.user
                                        terminalViewController.host = Server.host
                                        terminalViewController.password = Server.password
                                        terminalViewController.browserVC = self
                                        self.present(terminalViewController, animated: true, completion: nil)
                                    })
                                } else {
                                    self.dismiss(animated: true, completion: nil)
                                }
                            })
                            
                        } else {
                            self.dismiss(animated: true, completion: {
                                self.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                            })
                        }
                    } else {
                        self.dismiss(animated: true, completion: {
                            self.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                        })
                    }
                })
                
            } else {
                present(vc, animated: true, completion: nil)
            }
        } else {
            present(documentViewController, animated: true, completion: nil)
        }
        
    }
    
}

