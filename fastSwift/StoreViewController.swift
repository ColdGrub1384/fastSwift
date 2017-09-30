//
//  StoreViewController.swift
//  fastSwift
//
//  Created by Adrian on 24.06.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import StoreKit
import AdSupport
import GoogleMobileAds
import NMSSH
import Zip

extension String {
    func addingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
    
}


class StoreViewController: UIViewController, UICollectionViewDataSource, UITableViewDataSource, GADRewardBasedVideoAdDelegate, UITableViewDelegate {
    
    var currentPurchase: SKProduct?
    @IBOutlet weak var compilations: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    var prices = [String]()
    var plusOne = false
    var canMakePayments = true
    var files = [String]()
    var higherRunButtonTag = 0
    var higherSourceButtonTag = 0
    var filesCollectionView: UICollectionView?
    @IBOutlet weak var doneBtn: UIBarButtonItem!
    
    @objc func runFileFromStore(_ sender: UIButton) {
        let file = files[sender.tag]
        let fileURL = URL(string:"http://\(Server.default.host)/dl.php?f=/mnt/FFSwift/\(Server.user)@\(Server.host)/files/\(file.addingPercentEncodingForURLQueryValue()!)")!
        
        let activityVC = ActivityViewController(message: "Downloading...")
        self.present(activityVC, animated: true, completion: nil)
        
        URLSession.shared.dataTask(with: fileURL, completionHandler: { (data, response, error) in
            self.dismiss(animated: true, completion: {
                if error == nil {
                    if data != nil {
                        let tmpFile = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask)[0].appendingPathComponent("TMPEXECFILETOSEND.swiftc")
                        FileManager.default.createFile(atPath: tmpFile.path, contents: data, attributes: nil)
                        
                        let vc = self.storyboard!.instantiateViewController(withIdentifier: "browser") as! DocumentBrowserViewController
                        
                        self.present(vc, animated: true, completion: {
                            vc.dismissState = .ready
                            let _ = Afte.r(1, seconds: { (timer) in
                                vc.presentDocument(at: [tmpFile])
                            })
                        })
                    } else {
                        self.present(AlertManager.shared.serverErrorViewController, animated: true, completion: nil)
                    }
                } else {
                    self.present(AlertManager.shared.serverErrorViewController, animated: true, completion: nil)
                }
            })
        }).resume()
    }
    
    @objc func showSourceFromStore(_ sender: UIButton) {
        let file = files[sender.tag]
        let docs = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!
        
        let vc = ActivityViewController(message: "Downloading...")
        self.present(vc, animated: true, completion: nil)
        
        let session = NMSSHSession.connect(toHost: Server.default.host, withUsername: Server.default.user)
        if (session?.isConnected)! {
            session?.authenticate(byPassword: Server.default.password)
            if (session?.isAuthorized)! {
                do {
                    try session?.channel.execute("mkdir zips; mkdir zips/\(UIDevice.current.identifierForVendor!.uuidString); cd /mnt/FFSwift/\(Server.user)@\(Server.host)/source/; cd '\(file)'; cp * ~/zips/\(UIDevice.current.identifierForVendor!.uuidString)/; cd ~/zips/\(UIDevice.current.identifierForVendor!.uuidString); zip download *")
                    
                    URLSession.shared.downloadTask(with: URL(string:"http://\(Server.default.host)/dl.php?f=/home/swiftexec/zips/\(UIDevice.current.identifierForVendor!.uuidString)/download.zip")!, completionHandler: { (url, response, error) in
                        
                        do {
                            try session?.channel.execute("rm -rf  ~/zips/\(UIDevice.current.identifierForVendor!.uuidString)/")
                            session?.disconnect()
                        } catch _ {
                            self.dismiss(animated: true, completion: {
                                self.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                            })
                        }
                        
                        if error == nil {
                            if url != nil {
                                let dest = docs.appendingPathComponent((file as NSString).deletingPathExtension+".zip")
                                
                                do {try FileManager.default.removeItem(at: dest)} catch _ {}
                                
                                do {
                                    try FileManager.default.moveItem(at: url!, to: dest)
                                    
                                    self.dismiss(animated: true, completion: {
                                        let vc = self.storyboard!.instantiateInitialViewController() as! DocumentBrowserViewController
                                        vc.dismissState = .ready
                                        
                                        self.present(vc, animated: true, completion: {
                                            let _ = Afte.r(1, seconds: { (timer) in
                                                vc.presentDocument(at: [dest])
                                            })
                                        })
                                    })
                                } catch let error {
                                    Debugger.shared.debug_("Error processing files! \(error)")
                                }
                            } else {
                                self.dismiss(animated: true, completion: {
                                    self.present(AlertManager.shared.serverErrorViewController, animated: true, completion: nil)
                                })
                            }
                        } else {
                            self.dismiss(animated: true, completion: {
                                AlertManager.shared.present(error: error!, withTitle: "Error downloading source!", inside: self)
                            })
                        }
                    }).resume()
                } catch _ {
                    self.dismiss(animated: true, completion: {
                        self.present(AlertManager.shared.serverErrorViewController, animated: true, completion: nil)
                    })
                }
            } else {
                self.dismiss(animated: true, completion: {
                    self.present(AlertManager.shared.serverErrorViewController, animated: true, completion: nil)
                })
            }
        } else {
            self.dismiss(animated: true, completion: {
                self.present(AlertManager.shared.serverErrorViewController, animated: true, completion: nil)
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 1 {
            return 4
        } else if collectionView.tag == 2 {
            if self.filesCollectionView != nil {
                return files.count
            } else {
                return 1
            }
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if canMakePayments {
            return 4
        } else {
            return 3
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: "0", for: indexPath)
        
        if collectionView.tag != 2 {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(indexPath.row)", for: indexPath)
        }
        
        if collectionView.tag == 1 {
            if prices != [] {
                let button = cell.viewWithTag(5) as! UIButton
                button.setTitle(prices[indexPath.row], for: .normal)
            }
        } else if collectionView.tag == 2 {
            
            if let _ = self.filesCollectionView {
                
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: "0", for: indexPath)
                
                let label = cell.viewWithTag(4) as! UILabel
                label.text = (files[indexPath.row] as NSString).deletingPathExtension
                
                let buttonRun = cell.viewWithTag(5) as! UIButton
                let buttonSource = cell.viewWithTag(6) as! UIButton
                
                buttonRun.tag = higherRunButtonTag
                higherRunButtonTag += 1
                buttonRun.addTarget(self, action: #selector(runFileFromStore(_:)), for: .touchUpInside)
                
                buttonSource.tag = higherSourceButtonTag
                higherSourceButtonTag += 1
                buttonSource.addTarget(self, action: #selector(showSourceFromStore(_:)), for: .touchUpInside)
            } else {
                self.filesCollectionView = collectionView
                return cell
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if canMakePayments {
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(indexPath.row)")!
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(indexPath.row+1)")!
            return cell
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        canMakePayments = SKPaymentQueue.canMakePayments()
        
        prices = AccountManager.shared.productPrices
        tableView.isHidden = false
        activity.stopAnimating()
        
        compilations.text = ""
        
        tableView.delegate = self
        
        AccountManager.shared.storeViewController = self
        
        URLSession.shared.dataTask(with: URL(string:"http://\(Server.default.host)/dir.php?dir=/mnt/FFSwift/\(Server.user)@\(Server.host)/files")!) { (data, response, error) in
            if error == nil {
                if data != nil {
                    let string = String.init(data: data!, encoding: .utf8)!
                    var processed = string.components(separatedBy: "\n")
                    
                    for element in processed {
                        if element == "" {
                            processed.remove(at: processed.index(of: element)!)
                        }
                    }
                    
                    self.files = processed
                    
                    DispatchQueue.main.async {
                        self.filesCollectionView!.reloadData()
                    }
                    
                    Debugger.shared.debug_(self.files)
                } else {
                    AlertManager.shared.present(error: error!, withTitle: "Error fetching store content!", inside: self)
                }
            } else {
                AlertManager.shared.present(error: error!, withTitle: "Error fetching store content!", inside: self)
            }
        }.resume()
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        compilations.text = "\(AccountManager.shared.compilations) 🐧"
        if plusOne {
            Debugger.shared.debug_("+1")
            let alert = AlertManager.shared.alert(withTitle: "+1 🐧", message: "You have now \(AccountManager.shared.compilations)🐧", style: .alert, actions: [AlertManager.shared.ok(handler: nil)])
            self.present(alert, animated: true, completion: nil)
            plusOne = false
        }
        
    }
    
    @IBAction func done(sender: Any) {
        self.dismiss(animated: true, completion:nil)
    }
    
    func buy(_ product: SKProduct) {
        Debugger.shared.debug_("Buy "+product.localizedTitle)
        let pay = SKPayment(product: product)
        currentPurchase = product
        AppDelegate.shared.currentPurchase = currentPurchase
        SKPaymentQueue.default().add(pay)
    }
    
    @IBAction func buyPendrive(_ sender: Any) {
        Debugger.shared.debug_("Buy pendrive")
        
        for item in AccountManager.shared.shop {
            if item.productIdentifier == "ch.marcela.ada.fastSwift.purchases.pendrive" {
                buy(item)
                break
            }
        }
    }
    
    @IBAction func buySDCard(_ sender: Any) {
        Debugger.shared.debug_("Buy SD Card")
        for item in AccountManager.shared.shop {
            if item.productIdentifier == "ch.marcela.ada.fastSwift.purchases.sd" {
                buy(item)
                break
            }
        }
    }
    
    @IBAction func buyCD(_ sender: Any) {
        Debugger.shared.debug_("Buy CD")
        for item in AccountManager.shared.shop {
            if item.productIdentifier == "ch.marcela.ada.fastSwift.purchases.cd" {
                buy(item)
                break
            }
        }
    }
    
    @IBAction func buyHD(_ sender: Any) {
        Debugger.shared.debug_("Buy hard drive")
        for item in AccountManager.shared.shop {
            if item.productIdentifier == "ch.marcela.ada.fastSwift.purchases.hd" {
                buy(item)
                break
            }
        }
    }
    
    @IBAction func watchVideo(_ sender: Any) {
        Debugger.shared.debug_("Watch video")
        
        GADRewardBasedVideoAd.sharedInstance().delegate = self
        let request = GADRequest()
        GADRewardBasedVideoAd.sharedInstance().load(request, withAdUnitID: "ca-app-pub-9214899206650515/9664605186")
        
        self.present(ActivityViewController.init(message: "Searching ad..."), animated: true, completion: nil)
        
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        AccountManager.shared.compilations = AccountManager.shared.compilations+1
        plusOne = true
    }
    
    func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        if GADRewardBasedVideoAd.sharedInstance().isReady {
            Debugger.shared.debug_("Is ready!")
            self.dismiss(animated: true, completion: {
                GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: self)
            })
        }
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
        self.dismiss(animated: true) {
            AlertManager.shared.present(error: error, withTitle: "Error loading ad!", inside: self)
        }
    }
    
    @IBAction func account(_ sender: Any) {
        AccountManager.shared.presentAccountInfo(inside: self)
    }
    
    
}
