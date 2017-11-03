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
    
    @IBOutlet weak var bannerSuperView: UIView!
    @IBOutlet weak var bannerView: GADBannerView!
    
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currents = tableView.indexPathsForVisibleRows!
        var current: UITableViewCell!
        
        for current_ in currents {
            let cellRect = tableView.rectForRow(at: current_)
            let isVisible = tableView.bounds.contains(cellRect)
            
            if isVisible {
                current = tableView.cellForRow(at: current_)
                break
            }
        }
        
        if current.reuseIdentifier == "0" || current.reuseIdentifier == "1" { // Sale
            title = "Sale"
        } else if current.reuseIdentifier == "2" { // Programs
            title = "Programs"
        } else if current.reuseIdentifier == "3" { // Challenges
            title = "Challenges"
        } else if current.reuseIdentifier == "4" { // Leaderboard
            title = "Leaderboard"
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: UICollectionViewDataSource
    // -------------------------------------------------------------------------
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 1 {
            return 4
        } else if collectionView.tag == 2 {
            if self.filesCollectionView != nil {
                return files.count
            } else {
                return 1
            }
        } else if collectionView.tag == 7 {
            return challenges.count
        } else if collectionView.tag == 8 {
            return leaderboard.count
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: "0", for: indexPath)
        
        if collectionView.tag != 2 && collectionView.tag != 8 {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(indexPath.row)", for: indexPath)
        }
        
        if collectionView.tag == 1 { // Store
            if prices != [] {
                let button = cell.viewWithTag(5) as! UIButton
                button.setTitle(prices[indexPath.row], for: .normal)
                button.backgroundColor = .clear
                cell.backgroundColor = AppDelegate.shared.theme.color
                
                let iconView = cell.viewWithTag(6) as! UIImageView
                let icon = iconView.image!
                let icon_ = icon.withRenderingMode(.alwaysTemplate)
                iconView.image = icon_
                iconView.tintColor = AppDelegate.shared.theme.textColor
                
                let label = cell.viewWithTag(7) as! UILabel
                label.textColor = AppDelegate.shared.theme.textColor
            }
        } else if collectionView.tag == 2 { // Programs
            
            if let _ = self.filesCollectionView {
                
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: "0", for: indexPath)
                cell.backgroundColor = AppDelegate.shared.theme.color
                
                let label = cell.viewWithTag(4) as! UILabel
                label.text = (files[indexPath.row] as NSString).deletingPathExtension
                label.textColor = AppDelegate.shared.theme.textColor
                
                let buttonRun = cell.viewWithTag(5) as! UIButton
                let buttonSource = cell.viewWithTag(6) as! UIButton
                
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
                return cell
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
                        self.filesCollectionView!.reloadData()
                    }
                    
                    print(self.files)
                } else {
                    AlertManager.shared.present(error: error!, withTitle: "Error fetching store content!", inside: self)
                }
            } else {
                AlertManager.shared.present(error: error!, withTitle: "Error fetching store content!", inside: self)
            }
        }.resume()
        
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("viewDidAppear!")
        
        compilations.text = "\(AccountManager.shared.compilations) 🐧"
        if plusOne {
            print("+1")
            let alert = AlertManager.shared.alert(withTitle: "+1 🐧", message: "You have now \(AccountManager.shared.compilations)🐧", style: .alert, actions: [AlertManager.shared.ok(handler: nil)])
            self.present(alert, animated: true, completion: nil)
            plusOne = false
        }
        
        AccountManager.shared.storeViewController = self
        
    }
    
    // -------------------------------------------------------------------------
    // MARK: Buy compilations
    // -------------------------------------------------------------------------
    
    func buy(_ product: SKProduct) {
        print("Buy "+product.localizedTitle)
        let pay = SKPayment(product: product)
        currentPurchase = product
        AppDelegate.shared.currentPurchase = currentPurchase
        SKPaymentQueue.default().add(pay)
    }
    
    @IBAction func done(sender: Any) {
        self.dismiss(animated: true, completion:nil)
    }
    
    @IBAction func buyPendrive(_ sender: Any) {
        print("Buy pendrive")
        
        for item in AccountManager.shared.shop {
            if item.productIdentifier == "ch.marcela.ada.fastSwift.purchases.pendrive" {
                buy(item)
                break
            }
        }
    }
    
    @IBAction func buySDCard(_ sender: Any) {
        print("Buy SD Card")
        for item in AccountManager.shared.shop {
            if item.productIdentifier == "ch.marcela.ada.fastSwift.purchases.sd" {
                buy(item)
                break
            }
        }
    }
    
    @IBAction func buyCD(_ sender: Any) {
        print("Buy CD")
        for item in AccountManager.shared.shop {
            if item.productIdentifier == "ch.marcela.ada.fastSwift.purchases.cd" {
                buy(item)
                break
            }
        }
    }
    
    @IBAction func buyHD(_ sender: Any) {
        print("Buy hard drive")
        for item in AccountManager.shared.shop {
            if item.productIdentifier == "ch.marcela.ada.fastSwift.purchases.hd" {
                buy(item)
                break
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
        AccountManager.shared.compilations = AccountManager.shared.compilations+1
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
    
    
}
