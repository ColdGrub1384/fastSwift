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

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate, QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return selectedFiles.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return selectedFiles[index] as QLPreviewItem
    }
    
    
    var open = true
    
    var selectedFiles = [URL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
                
        allowsDocumentCreation = true
        allowsPickingMultipleItems = true
        
        // Update the style of the UIDocumentBrowserViewController
        browserUserInterfaceStyle = .dark
        view.tintColor = .orange
        
        // Specify the allowed content types of your application via the Info.plist.
        
        // Do any additional setup after loading the view, typically from a nib.
        
        self.customActions = [UIDocumentBrowserAction.init(identifier: "compile", localizedTitle: "🔨", availability: .navigationBar, handler: { (urls) in
            
            if AccountManager.shared.compilations <= 0 {
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
    
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        let newDocumentURL: URL? = Bundle.main.url(forResource: "Samples", withExtension: "")?.appendingPathComponent("Untitled.swift")
        
        // Set the URL for the new document here. Optionally, you can present a template chooser before calling the importHandler.
        // Make sure the importHandler is always called, even if the user cancels the creation request.
        if newDocumentURL != nil {
            importHandler(newDocumentURL, .copy)
        } else {
            importHandler(nil, .none)
        }
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
    
    // MARK: Document Presentation
    
    func compile(urls: [URL], withState state:AppDelegate.autoCompilationState) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let documentViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentViewController") as! DocumentViewController
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
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let documentViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentViewController") as! DocumentViewController
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
                        let files = try FileManager.default.contentsOfDirectory(at: newUnzipedFile, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                        self.presentDocument(at: files)
                    } catch let error {
                        print("Error getting content of folder: \(error)")
                    }
                } catch let error {
                    print("Error unziping files! \(error.localizedDescription)")
                }
            } else {
                present(vc, animated: true, completion: nil)
            }
        } else {
            present(documentViewController, animated: true, completion: nil)
        }
        
        
    }
}

