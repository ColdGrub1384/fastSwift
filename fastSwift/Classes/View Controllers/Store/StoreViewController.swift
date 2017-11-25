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
import SwiftyStoreKit

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
    var challenges = [Challenge]()
    var leaderboard = [Player]()
    var areProgramsFetched = false
    
    @IBOutlet weak var bannerSuperView: UIView!
    @IBOutlet weak var bannerView: GADBannerView!
    
    func fetchData() {
        var challengesURL = URL(string:"http://\(Server.default.host)/challenges.php?viewChallenges")!
        if let username = AccountManager.shared.username?.addingPercentEncodingForURLQueryValue() {
            challengesURL = URL(string: challengesURL.absoluteString+"&username=\(username)")!
        }
        
        URLSession.shared.dataTask(with: challengesURL) { (data, response, error) in // Fetch challenges
            if let data = data {
                if let str = String(data: data, encoding: .utf8) {
                    let challenges = str.components(separatedBy: ";")
                    
                    for challenge in challenges {
                        let properties = challenge.components(separatedBy: "->")
                        
                        if properties.count <= 1 { // Break if challenge is empty, always the last
                            break
                        }
                        
                        let name = properties[0]
                        let code = properties[1]
                        
                        
                        let challenge_ = Challenge(name: name, code: code)
                        self.challenges.append(challenge_)
                    }
                    
                    for challenge in self.challenges {
                        print("Challenge found: \(challenge.name)")
                    }
                }
            }
            }.resume()
        
        URLSession.shared.dataTask(with: URL(string:"http://\(Server.default.host)/leaderboard.php")!) { (data, response, error) in // Fetch leaderboard
            if let data = data {
                if let str = String(data: data, encoding: .utf8) {
                    let users = str.components(separatedBy: ";")
                    
                    for user in users {
                        let properties = user.components(separatedBy: ":")
                        
                        if properties.count <= 1 {
                            break
                        }
                        
                        let name = properties[0]
                        let points_ = properties[1]
                        
                        if let points = Int(points_) {
                            let player = Player(name: name, points: points)
                            self.leaderboard.append(player)
                        }
                    }
                    
                    for player in self.leaderboard {
                        print("Player found: \(player.name)")
                    }
                }
            }
            }.resume()
        
        URLSession.shared.dataTask(with: URL(string:"http://\(Server.default.host)/dir.php?dir=/mnt/FFSwift/\(Server.user)@\(Server.host)/files")!) { (data, response, error) in // Fetch store programs
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
                        self.filesCollectionView?.reloadData()
                        self.areProgramsFetched = true
                    }
                    
                    print(self.files)
                } else {
                    AlertManager.shared.present(error: error!, withTitle: "Error fetching store content!", inside: self)
                }
            } else {
                AlertManager.shared.present(error: error!, withTitle: "Error fetching store content!", inside: self)
            }
            }.resume()
    }
    
    
    // -------------------------------------------------------------------------
    // MARK: CollectionViewCells buttons
    // -------------------------------------------------------------------------
    
    @objc func viewProfile(_ sender: UIButton) {
        let webViewController = AppViewControllers().web
        let index_ = sender.title(for: .disabled)
        if let index = Int(index_!) {
            let player = leaderboard[index]
            let url = player.profile
            
            webViewController.url = url
            self.present(webViewController, animated: true, completion: nil)
        }
        
    }
    
    @objc func tryChallenge(_ sender: UIButton) {
        let documentViewController = AppViewControllers().document
        let index_ = sender.title(for: .disabled)
        if let index = Int(index_!) {
            documentViewController.challenge = self.challenges[index]
            if AccountManager.shared.username != nil && AccountManager.shared.password != nil { // User is logged, so start the challenge
                self.present(documentViewController, animated: true, completion: nil)
            } else { // User is not logged
                AccountManager.shared.login(inside: self, completion: {
                    self.tryChallenge(sender)
                })
            }
        }
        
    }

        
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
                        
                        let vc = AppViewControllers().documentBrowser
                        
                        self.present(vc, animated: true, completion: {
                            vc.dismissState = .ready
                            let _ = Afte.r(1, seconds: { (timer) in
                                vc.presentDocument(at: [tmpFile])
                            })
                        })
                    } else {
                        self.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                    }
                } else {
                    self.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
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
                                        let vc = AppViewControllers().documentBrowser
                                        vc.dismissState = .ready
                                        
                                        self.present(vc, animated: true, completion: {
                                            let _ = Afte.r(1, seconds: { (timer) in
                                                vc.presentDocument(at: [dest])
                                            })
                                        })
                                    })
                                } catch let error {
                                    print("Error processing files! \(error)")
                                }
                            } else {
                                self.dismiss(animated: true, completion: {
                                    self.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
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
                        self.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                    })
                }
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
    }
    
    // -------------------------------------------------------------------------
    // MARK: UITableViewDataSource
    // -------------------------------------------------------------------------
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if canMakePayments {
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(indexPath.row)")!
            cell.backgroundColor = AppDelegate.shared.theme.color
            
            for subview in cell.contentView.subviews {
                if let collectionView = subview as? UICollectionView {
                    print("Collectionview found!")
                    collectionView.backgroundColor = AppDelegate.shared.theme.color
                    collectionView.backgroundColor = AppDelegate.shared.theme.color
                }
            }
            
            return cell
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(indexPath.row+1)")!
            cell.backgroundColor = AppDelegate.shared.theme.color
            
            for subview in cell.contentView.subviews {
                if let collectionView = subview as? UICollectionView {
                    print("Collectionview found!")
                    collectionView.backgroundColor = AppDelegate.shared.theme.color
                    collectionView.backgroundColor = AppDelegate.shared.theme.color
                }
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if canMakePayments {
            return 6
        } else {
            return 5
        }
        
    }
    
    // -------------------------------------------------------------------------
    // MARK: UITableViewDelegate
    // -------------------------------------------------------------------------
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Hide store if infinite compilations is bought
        
        if UserDefaults.standard.bool(forKey: "infinite") {
            if indexPath.row == 0 || indexPath.row == 1 {
                return 0
            }
        }
        
        return 200
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let currents = tableView.indexPathsForVisibleRows!
        var current: UITableViewCell!
        
        for current_ in currents {
            let cellRect = tableView.rectForRow(at: current_)
            let isVisible = tableView.bounds.contains(cellRect)
            
            if isVisible && cellRect.height != 0 {
                current = tableView.cellForRow(at: current_)
                break
            }
        }
        
        print("Current cell reuse identifier: \(current.reuseIdentifier ?? "nil")")
        
        if (current.reuseIdentifier == "0" || current.reuseIdentifier == "1") { // Sale
            title = "Sale"
        } else if current.reuseIdentifier == "2" { // Programs
            title = "Programs"
        } else if current.reuseIdentifier == "3" { // Challenges
            title = "Challenges"
        } else if current.reuseIdentifier == "4" { // Leaderboard
            title = "Leaderboard"
        }
        
        
        UIView.animate(withDuration: 1) {
            self.navigationController?.navigationBar.prefersLargeTitles = scrollView.isAtTop
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: UICollectionViewDataSource
    // -------------------------------------------------------------------------
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 1 {
            print("1: 5")
            return 5
        } else if collectionView.tag == 2 {
            print("2: \(files.count)")
            return files.count
        } else if collectionView.tag == 7 {
            print("7: \(challenges.count)")
            return challenges.count
        } else if collectionView.tag == 8 {
            print("8: \(leaderboard.count)")
            return leaderboard.count
        } else {
            print("1")
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: "0", for: indexPath)
        
        if collectionView.tag != 2 && collectionView.tag != 8 && collectionView.tag != 7 {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(indexPath.row)", for: indexPath)
        }
        
        if collectionView.tag == 1 { // Store
            if prices != [] {
                let button = cell.viewWithTag(5) as! UIButton
                button.setTitle(prices[indexPath.row], for: .normal)
                button.backgroundColor = .clear
                cell.backgroundColor = AppDelegate.shared.theme.color
                
                if let restore = cell.viewWithTag(4) as? UIButton {
                    restore.backgroundColor = .clear
                    restore.backgroundColor = AppDelegate.shared.theme.color
                }
                
                
                let iconView = cell.viewWithTag(6) as! UIImageView
                let icon = iconView.image!
                let icon_ = icon.withRenderingMode(.alwaysTemplate)
                iconView.image = icon_
                iconView.tintColor = AppDelegate.shared.theme.textColor
                
                let label = cell.viewWithTag(7) as! UILabel
                label.textColor = AppDelegate.shared.theme.textColor
            }
        } else if collectionView.tag == 2 { // Programs
            
            if self.filesCollectionView != nil {
                
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: "0", for: indexPath)
                cell.backgroundColor = AppDelegate.shared.theme.color
                
                let label = cell.viewWithTag(4) as! UILabel
                label.text = (files[indexPath.row] as NSString).deletingPathExtension
                label.textColor = AppDelegate.shared.theme.textColor
                
                guard let buttonRun = cell.viewWithTag(5) as? UIButton else { return cell}
                guard let buttonSource = cell.viewWithTag(6) as? UIButton else { return cell}
                
                buttonSource.backgroundColor = .clear
                buttonRun.backgroundColor = .clear
                
                buttonRun.tag = higherRunButtonTag
                higherRunButtonTag += 1
                buttonRun.addTarget(self, action: #selector(runFileFromStore(_:)), for: .touchUpInside)
                
                buttonSource.tag = higherSourceButtonTag
                higherSourceButtonTag += 1
                buttonSource.addTarget(self, action: #selector(showSourceFromStore(_:)), for: .touchUpInside)
            } else {
                self.filesCollectionView = collectionView
                
                if self.areProgramsFetched {
                    _ = Afte.r(0.5, seconds: { (timer) in
                        collectionView.reloadData()
                    })
                }
                
                let loadingCell = collectionView.dequeueReusableCell(withReuseIdentifier: "1", for: indexPath)
                for subview in loadingCell.contentView.subviews {
                    if let activity = subview as? UIActivityIndicatorView {
                        activity.tintColor = AppDelegate.shared.theme.tintColor
                    }
                }
                
                return loadingCell
                
            }
        } else if collectionView.tag == 3 { // View video
            let label = cell.viewWithTag(2) as! UILabel
            label.textColor = AppDelegate.shared.theme.textColor
            
            cell.backgroundColor = AppDelegate.shared.theme.color
            
            let button = cell.viewWithTag(4) as! UIButton
            button.backgroundColor = .clear
            
            let iconView = cell.viewWithTag(3) as! UIImageView
            let icon = iconView.image
            let icon_ = icon?.withRenderingMode(.alwaysTemplate)
            iconView.image = icon_
            iconView.tintColor = AppDelegate.shared.theme.textColor
        } else if collectionView.tag == 7 { // Challenges
            let label = cell.viewWithTag(4) as! UILabel
            label.textColor = AppDelegate.shared.theme.textColor
            label.text = self.challenges[indexPath.row].name
            
            cell.backgroundColor = AppDelegate.shared.theme.color
            
            let button = cell.viewWithTag(5) as! UIButton
            button.backgroundColor = .clear
            button.setTitle("\(indexPath.row)", for: .disabled)
            button.addTarget(self, action: #selector(tryChallenge(_:)), for: .touchUpInside)
            
        } else if collectionView.tag == 8 { // Leaderboard
            let points = cell.viewWithTag(3) as! UILabel
            points.textColor = AppDelegate.shared.theme.textColor
            points.text = "\(self.leaderboard[indexPath.row].points) Points"
            
            let name = cell.viewWithTag(4) as! UILabel
            name.textColor = AppDelegate.shared.theme.textColor
            name.text = self.leaderboard[indexPath.row].name
            
            cell.backgroundColor = AppDelegate.shared.theme.color
        
            if self.leaderboard[indexPath.row].name == AccountManager.shared.username { // Is current user
                cell.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            }
            
            let button = cell.viewWithTag(5) as! UIButton
            button.backgroundColor = .clear
            button.setTitle("\(indexPath.row)", for: .disabled)
            button.addTarget(self, action: #selector(viewProfile(_:)), for: .touchUpInside)
            
            let iconView = cell.viewWithTag(1) as! UIImageView
            let icon = iconView.image!
            let icon_ = icon.withRenderingMode(.alwaysTemplate)
            iconView.image = icon_
            iconView.tintColor = AppDelegate.shared.theme.textColor
            
        }

        
        return cell
    }
    
    // -------------------------------------------------------------------------
    // MARK: UIViewController
    // -------------------------------------------------------------------------
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppDelegate.shared.theme.statusBarStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchData()
        
        canMakePayments = SKPaymentQueue.canMakePayments()
        
        prices = AccountManager.shared.productPrices
        tableView.isHidden = false
        activity.stopAnimating()
        
        compilations.text = ""
        
        tableView.delegate = self
        
        // Ads
        bannerSuperView.backgroundColor = AppDelegate.shared.theme.color
        bannerView.adSize = kGADAdSizeBanner
        bannerView.adUnitID = "ca-app-pub-9214899206650515/9138245460"
        bannerView.rootViewController = self
        let request = GADRequest()
        request.keywords = ["code","Swift","compile"]
        request.contentURL = "https://github.com/ColdGrub1384/fastSwift"
        bannerView.load(request)

        tableView.reloadData()
        
        tableView.backgroundColor = AppDelegate.shared.theme.color
        view.backgroundColor = AppDelegate.shared.theme.color
        view.tintColor = AppDelegate.shared.theme.tintColor
        compilations.backgroundColor = AppDelegate.shared.theme.color
        compilations.textColor = AppDelegate.shared.theme.textColor
        navigationController?.navigationBar.barTintColor = AppDelegate.shared.theme.color
        navigationController?.navigationBar.tintColor = AppDelegate.shared.theme.tintColor
        navigationController?.navigationBar.barStyle = AppDelegate.shared.theme.barStyle
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        view.backgroundColor = AppDelegate.shared.theme.color
        if AppDelegate.shared.theme.isEqual(to: Theme.white) {
            view.backgroundColor = #colorLiteral(red: 0.9627815673, green: 0.9627815673, blue: 0.9627815673, alpha: 1)
        }
        
        if UserDefaults.standard.bool(forKey: "infinite") {
            title = "Programs"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("viewDidAppear!")
        
        compilations.text = "\(AccountManager.shared.compilations.description) 🐧"
        if plusOne {
            print("+1")
            let alert = AlertManager.shared.alert(withTitle: "+1 🐧", message: "You have now \(AccountManager.shared.compilations.description)🐧", style: .alert, actions: [AlertManager.shared.ok(handler: nil)])
            self.present(alert, animated: true, completion: nil)
            plusOne = false
        }
        
        AccountManager.shared.storeViewController = self
        
        bannerView.isHidden = UserDefaults.standard.bool(forKey: "infinite")
    }
    
    // -------------------------------------------------------------------------
    // MARK: Buy compilations
    // -------------------------------------------------------------------------
    
    func redeem_(code: String) {
        
        var valid = true
        
        for redeemed in AccountManager.shared.redeemed {
            
            if redeemed == code {
                valid = false
                AlertManager.shared.presentAlert(withTitle: "Error redeeming code!", message: "The code is not valid or was already redeemed.", style: .alert, actions: [AlertManager.shared.ok(handler: nil)], inside: self, animated: true, completion: nil)
                break
            }
        }
        
        if !valid {
            return
        }
        
        func redeem(data: Data?, response: URLResponse?, error: Error?) {
            if let error = error {
                AlertManager.shared.present(error: error, withTitle: "Error redeeming code!", inside: self)
            } else if let data = data {
                if let reward = String(data: data, encoding: .utf8)?.slice(from: "Reward(", to: ")") {
                    if let reward_ = Int(reward) {
                        AccountManager.shared.compilations.add(reward_)
                        
                        AccountManager.shared.redeemed.append(code)
                        
                        AlertManager.shared.presentAlert(withTitle: "Added \(reward) 🐧!", message: "You have now \(AccountManager.shared.compilations.description) 🐧", style: .alert, actions: [AlertManager.shared.ok(handler: nil)], inside: self, animated: true, completion: nil)
                    } else {
                        AlertManager.shared.presentAlert(withTitle: "Error redeeming code!", message: "The code is not valid or was already redeemed.", style: .alert, actions: [AlertManager.shared.ok(handler: nil)], inside: self, animated: true, completion: nil)
                    }
                    
                } else {
                    AlertManager.shared.presentAlert(withTitle: "Error redeeming code!", message: "The code is not valid or was already redeemed.", style: .alert, actions: [AlertManager.shared.ok(handler: nil)], inside: self, animated: true, completion: nil)
                }
            } else {
                AlertManager.shared.presentAlert(withTitle: "Error redeeming code!", message: "The code is not valid or was already redeemed.", style: .alert, actions: [AlertManager.shared.ok(handler: nil)], inside: self, animated: true, completion: nil)
            }
        }
        
        if AccountManager.shared.compilations.type != .infinite {
            URLSession.shared.dataTask(with: URL(string:"http://\(Server.default.host)/redeem.php?code=\(code)")!, completionHandler: { (data, response, error) in
                redeem(data: data, response: response, error: error)
            }).resume()
        } else {
            AlertManager.shared.presentAlert(withTitle: "Error redeeming code", message: "You cannot add 🐧 because you have infinites 🐧.", style: .alert, actions: [AlertManager.shared.ok(handler: nil)], inside: self, animated: true, completion: nil)
        }
    }
    
    
    func buy(_ product: SKProduct) {
        print("Buy "+product.localizedTitle)
        currentPurchase = product
        AppDelegate.shared.currentPurchase = currentPurchase
        
        SwiftyStoreKit.purchaseProduct(product) { (result) in
            switch result {
            case .success(let purchase):
                print("Purchased!")
                
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                
                switch product.productIdentifier.components(separatedBy: ".").last {
                case "pendrive"?:
                    AccountManager.shared.buy(product: .pendrive)
                case "sd"?:
                    AccountManager.shared.buy(product: .sdCard)
                case "cd"?:
                    AccountManager.shared.buy(product: .cd)
                case "hd"?:
                    AccountManager.shared.buy(product: .hardDrive)
                case "unlimited"?:
                    UserDefaults.standard.set(true, forKey: "infinite")
                    UserDefaults.standard.synchronize()
                    AppDelegate.shared.window?.rootViewController = AppViewControllers().launchScreen
                    _ = AppDelegate.shared.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                default:
                    print("Unknown purchase!")
                }
            case .error(error: let error):
                
                let skError = SKError(_nsError: error as NSError)
                
                if skError.code == .paymentCancelled {
                    return
                }
                
                if let vc = AccountManager.shared.storeViewController {
                    AlertManager.shared.present(error: error, withTitle: "Error!", inside: vc)
                }
                print("Error! \(error)")
            }
        }
    }
    
    @IBAction func done(sender: Any) {
        self.dismiss(animated: true, completion:nil)
    }
    
    @IBAction func buyPendrive(_ sender: Any) {
        print("Buy pendrive")
        
        for item in AccountManager.shared.shop {
            if item.productIdentifier.components(separatedBy: ".").last == "pendrive" {
                buy(item)
                break
            }
        }
    }
    
    @IBAction func buySDCard(_ sender: Any) {
        print("Buy SD Card")
        for item in AccountManager.shared.shop {
            if item.productIdentifier.components(separatedBy: ".").last == "sd" {
                buy(item)
                break
            }
        }
    }
    
    @IBAction func buyCD(_ sender: Any) {
        print("Buy CD")
        for item in AccountManager.shared.shop {
            if item.productIdentifier.components(separatedBy: ".").last == "cd" {
                buy(item)
                break
            }
        }
    }
    
    @IBAction func buyHD(_ sender: Any) {
        print("Buy hard drive")
        for item in AccountManager.shared.shop {
            if item.productIdentifier.components(separatedBy: ".").last == "hd" {
                buy(item)
                break
            }
        }
    }
    
    @IBAction func buyUnlimited(_ sender: Any) {
        print("Buy unlimited")
        for item in AccountManager.shared.shop {
            if item.productIdentifier.components(separatedBy: ".").last == "unlimited" {
                if UserDefaults.standard.bool(forKey: "infinite") {
                    AlertManager.shared.presentAlert(withTitle: "You already purchase this product", message: "You already purchased unlimited compilations, you can now compile all scripts you want.", style: .alert, actions: [AlertManager.shared.ok(handler: nil)], inside: self, animated: true, completion: nil)
                } else {
                    buy(item)
                }
                break
            }
        }
    }
    
    @IBAction func restorePurchases(_ sender: Any) {
        SwiftyStoreKit.restorePurchases { (results) in
            if results.restoredPurchases.count > 0 {
                for result in results.restoredPurchases {
                    if result.productId.components(separatedBy: ".").last == "unlimited" {
                        
                        AlertManager.shared.presentAlert(withTitle: "Restored product!", message: "Unlimited compilations product was restored", style: .alert, actions: [AlertManager.shared.ok(handler: { (action) in
                            UserDefaults.standard.set(true, forKey: "infinite")
                            AppDelegate.shared.window?.rootViewController = AppViewControllers().launchScreen
                            _ = AppDelegate.shared.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                            UserDefaults.standard.synchronize()
                        })], inside: self, animated: true, completion: nil)
                    }
                }
            } else {
                AlertManager.shared.presentAlert(withTitle: "You never purchased this product", message: "Purchase Unlimited to unlock unlimited compilations", style: .alert, actions: [AlertManager.shared.ok(handler: nil)], inside: self, animated: true, completion: nil)
            }
        }
    }
    
    
    // -------------------------------------------------------------------------
    // MARK: Watch videos
    // -------------------------------------------------------------------------
    
    @IBAction func watchVideo(_ sender: Any) {
        print("Watch video")
        
        GADRewardBasedVideoAd.sharedInstance().delegate = self
        let request = GADRequest()
        GADRewardBasedVideoAd.sharedInstance().load(request, withAdUnitID: "ca-app-pub-9214899206650515/9664605186")
        
        self.present(ActivityViewController.init(message: "Searching ad..."), animated: true, completion: nil)
        
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        AccountManager.shared.compilations.add(1)
        plusOne = true
    }
    
    func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        if GADRewardBasedVideoAd.sharedInstance().isReady {
            print("Is ready!")
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
    
    // -------------------------------------------------------------------------
    // MARK: Buttons
    // -------------------------------------------------------------------------
    
    @IBAction func account(_ sender: Any) {
        AccountManager.shared.presentAccountInfo(inside: self)
    }
    
    
    @IBAction func setupServer(_ sender: Any) {
        self.present(AppViewControllers().setupServer, animated: true, completion: nil)
    }
    
    @IBAction func redeem(_ sender: Any) {
        let alert = UIAlertController(title: "Redeem code", message: "Type a valid 8 digits code", preferredStyle: .alert)
        alert.addAction(AlertManager.shared.cancel)
        alert.addAction(UIAlertAction(title: "Redeem", style: .default, handler: { (action) in
            if let textfield = alert.textFields?.first {
                if let text = textfield.text {
                    self.redeem_(code: text)
                }
            }
        }))
        
        alert.addTextField { (textfield) in
            textfield.placeholder = "Promo code"
        }
        
        alert.view.tintColor = AppDelegate.shared.theme.tintColor
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
}
