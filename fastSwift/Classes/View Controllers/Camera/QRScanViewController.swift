//
//  QRScanViewController.swift
//  fastSwift
//
//  Created by Adrian on 16.09.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

class QRScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var video = AVCaptureVideoPreviewLayer()
    var session = AVCaptureSession()
    @IBOutlet weak var denied: UILabel!
    
    static var relaunched = false
    
    // -------------------------------------------------------------------------
    // MARK: UIViewController
    // -------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppDelegate.shared.qrScanner = self
        
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        
        if device != nil {
            do {
                let input = try AVCaptureDeviceInput(device: device!)
                session.addInput(input)
            } catch let error {
                print("Error: \(error)")
            }
            
            var cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            
            switch cameraAuthorizationStatus {
            case .denied:
                view.viewWithTag(1)!.isHidden = true
            case .authorized:
                showCam() // Show cam only if user has authorized it
            case .restricted: break
            case .notDetermined: // If the user hasn't putted anything, wait for it
                print("Not determined!")
                let _ = Repea.t(all: 0.2, seconds: { (timer) in
                    if cameraAuthorizationStatus == .notDetermined {
                        cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
                    } else if !QRScanViewController.relaunched {
                        
                        let launchScreen = AppViewControllers().launchScreen
                        launchScreen.menu = AppViewControllers().menu
                        launchScreen.menu.loadedStore = AppDelegate.shared.menu.loadedStore
                        launchScreen.menu.mainVCIndex = AppDelegate.shared.menu.mainVCIndex
                        
                        QRScanViewController.relaunched = true
                        
                        AppDelegate.shared.window?.rootViewController = launchScreen
                    }
                })
            }
        }
        
        view.backgroundColor = Theme.current.color
        denied.textColor = Theme.current.textColor
    }
    
    // -------------------------------------------------------------------------
    // MARK: Camera
    // -------------------------------------------------------------------------
    
    func showCam() {
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.init(label: "qr"))
        output.metadataObjectTypes = [AVMetadataMachineReadableCodeObject.ObjectType.qr]
        
        video = AVCaptureVideoPreviewLayer(session: session)
        video.frame = view.layer.frame
        view.layer.addSublayer(video)
        
        session.startRunning()
        
        view.bringSubview(toFront: view.viewWithTag(1)!)
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if metadataObjects.isEmpty {
            return
        }
        
        if let _ = presentedViewController as? UIAlertController {
            return
        }
        
        if let terminal = AppDelegate.shared.topViewController() as? NMTerminalViewController { // Send text to terminal
            if let object = metadataObjects[0] as? AVMetadataMachineReadableCodeObject {
                if object.type == .qr {
                    if let str = object.stringValue?.replacingOccurrences(of: "\n", with: "") {
                        if terminal.session.isConnected {
                            if terminal.session.isAuthorized {
                                if !terminal.terminal.text.hasSuffix(str) {
                                    DispatchQueue.main.async {
                                        if terminal.terminal.isEditable {
                                            AudioServicesPlaySystemSound(1307)
                                            terminal.terminal.text = terminal.terminal.text+str
                                            return
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if let object = metadataObjects[0] as? AVMetadataMachineReadableCodeObject {
            if object.type == .qr {
                if let str = object.stringValue {
                    if str.hasPrefix("$SERVER=") { // is  server
                        AudioServicesPlaySystemSound(1307)
                        let server = str.replacingOccurrences(of: "$SERVER=", with: "")
                        if let userName = server.components(separatedBy: "@").first {
                            if let address = server.components(separatedBy: "@").last?.components(separatedBy: ";").first {
                                if let password = server.components(separatedBy: ";").last {
                                    DispatchQueue.main.async {
                                        AlertManager.shared.presentAlert(withTitle: Strings.Camera.DetectedServerAlert.title, message: Strings.Camera.DetectedServerAlert.message(withUsername: userName, host: address, password: password), style: .alert, actions: [UIAlertAction.init(title: Strings.cancel, style: .cancel, handler: { (action) in
                                            self.session.startRunning()
                                        }), AlertManager.shared.ok(handler: { (action) in
                                            UserDefaults.standard.set(address, forKey: "hostname")
                                            UserDefaults.standard.set(userName, forKey: "username")
                                            UserDefaults.standard.set(password, forKey: "password")
                                            UserDefaults.standard.set(true, forKey: "custom_server")
                                            self.session.startRunning()
                                            AppDelegate.shared.menu.showSettings()
                                        })], inside: self, animated: true, completion: nil)
                                    }
                                }
                            }
                        }
                    } else if str.hasPrefix("$CODE=") { // is a script
                        AudioServicesPlaySystemSound(1307)
                        let script = str.replacingOccurrences(of: "$CODE=", with: "")
                        if let url = URL(string:script) {
                            DispatchQueue.main.async {
                                AlertManager.shared.presentAlert(withTitle: Strings.Camera.DetectedScriptAlert.title, message: Strings.Camera.DetectedScriptAlert.message, style: .alert, actions: [UIAlertAction.init(title: Strings.cancel, style: .cancel, handler: { (action) in
                                }), UIAlertAction.init(title: "Ok", style: .default, handler: { (alert) in
                                    let activity = ActivityViewController(message: Strings.downloading)
                                    self.present(activity, animated: true, completion: nil)
                                    URLSession.shared.downloadTask(with: url, completionHandler: { (url, response, error) in
                                        if error == nil {
                                            if url != nil {
                                                let finalURL = url!.deletingLastPathComponent().appendingPathComponent(response!.suggestedFilename!)
                                                do {
                                                    try FileManager.default.moveItem(at: url!, to: finalURL)
                                                    self.dismiss(animated: true, completion: {
                                                        let _ = AppDelegate.shared.application(UIApplication.shared, open: finalURL)
                                                    })
                                                } catch let error {
                                                    self.dismiss(animated: true, completion: {
                                                        AlertManager.shared.presentAlert(withTitle: Strings.Camera.DetectedScriptAlert.Errors.errorMovingFile, message: error.localizedDescription, style: .alert, actions: [AlertManager.shared.cancel], inside: self, animated: true, completion: nil)
                                                    })
                                                }
                                            } else {
                                                self.dismiss(animated: true, completion: {
                                                    AlertManager.shared.presentAlert(withTitle: Strings.Camera.DetectedScriptAlert.Errors.errorDownloadingFile, message: Strings.emptyData, style: .alert, actions: [AlertManager.shared.cancel], inside: self, animated: true, completion: nil)
                                                })
                                            }
                                        } else {
                                            self.dismiss(animated: true, completion: {
                                                AlertManager.shared.present(error: error!, withTitle: Strings.Camera.DetectedScriptAlert.Errors.errorDownloadingFile, inside: self)
                                            })
                                        }
                                    }).resume()
                                })], inside: self, animated: true, completion: nil)
                            }
                        }
                    } else {
                        AudioServicesPlaySystemSound(1102)
                    }
                }
            }
        }
    }
}
