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
    
    func restartSession() {
        viewDidLoad()
    }
    
    func showCam() {
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [AVMetadataMachineReadableCodeObject.ObjectType.qr]
        
        video = AVCaptureVideoPreviewLayer(session: session)
        video.frame = view.layer.frame
        view.layer.addSublayer(video)
        
        session.startRunning()
        
        view.bringSubview(toFront: view.viewWithTag(1)!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppDelegate.shared.qrScanner = self
        
        video = AVCaptureVideoPreviewLayer()
        session = AVCaptureSession()
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        
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
                showCam()
            case .restricted: break
            case .notDetermined:
                print("Not determined!")
                let _ = Repea.t(all: 0.2, seconds: { (timer) in
                    if cameraAuthorizationStatus == .notDetermined {
                        cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
                    } else {
                        if cameraAuthorizationStatus == .denied  || cameraAuthorizationStatus == .restricted {
                            timer.invalidate()
                        } else {
                            AppDelegate.shared.menu.reload()
                            timer.invalidate()
                        }
                    }
                })
        }
        
        
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if metadataObjects.isEmpty {
            return
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
                                    AlertManager.shared.presentAlert(withTitle: "Detected Server!", message: "Do you want to use server '\(userName)@\(address)' with password '\(password)'?", style: .alert, actions: [UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (action) in
                                        self.session.startRunning()
                                    }), AlertManager.shared.ok(handler: { (action) in
                                        UserDefaults.standard.set(address, forKey: "hostname")
                                        UserDefaults.standard.set(userName, forKey: "username")
                                        UserDefaults.standard.set(password, forKey: "password")
                                        UserDefaults.standard.set(true, forKey: "custom_server")
                                        self.session.startRunning()
                                        AppDelegate.shared.menu.showSettings()
                                    })], inside: self, animated: true, completion: nil)
                                    self.session.stopRunning()
                                }
                            }
                        }
                    } else if str.hasPrefix("$CODE=") { // is a script
                        AudioServicesPlaySystemSound(1307)
                        let script = str.replacingOccurrences(of: "$CODE=", with: "")
                        if let url = URL(string:script) {
                            AlertManager.shared.presentAlert(withTitle: "Detected script!", message: "Do you want to run this script?", style: .alert, actions: [UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (action) in
                                self.session.startRunning()
                            }), UIAlertAction.init(title: "Ok", style: .default, handler: { (alert) in
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
                                                    AlertManager.shared.presentAlert(withTitle: "Error moving file!", message: error.localizedDescription, style: .alert, actions: [AlertManager.shared.cancel], inside: self, animated: true, completion: nil)
                                                })
                                            }
                                        } else {
                                            self.dismiss(animated: true, completion: {
                                                AlertManager.shared.presentAlert(withTitle: "Error downloading file!", message: "Returned data is empty", style: .alert, actions: [AlertManager.shared.cancel], inside: self, animated: true, completion: nil)
                                            })
                                        }
                                    } else {
                                        self.dismiss(animated: true, completion: {
                                            AlertManager.shared.present(error: error!, withTitle: "Error downloading file!", inside: self)
                                        })
                                    }
                                }).resume()
                            })], inside: self, animated: true, completion: nil)
                            self.session.stopRunning()
                        }
                    } else {
                        AudioServicesPlaySystemSound(1102)
                    }
                }
            }
        }
    }
}
