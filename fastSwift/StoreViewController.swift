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


class StoreViewController: UIViewController, UICollectionViewDataSource, UITableViewDataSource, GADRewardBasedVideoAdDelegate {
    
    var currentPurchase: SKProduct?
    @IBOutlet weak var compilations: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    var prices = [String]()
    var plusOne = false
    var canMakePayments = true
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 1 {
            return 4
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if canMakePayments {
            return 2
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(indexPath.row)", for: indexPath)
        
        if collectionView.tag == 1 {
            if prices != [] {
                let button = cell.viewWithTag(5) as! UIButton
                button.setTitle(prices[indexPath.row], for: .normal)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if canMakePayments {
            return tableView.dequeueReusableCell(withIdentifier: "\(indexPath.row)")!
        } else {
            return tableView.dequeueReusableCell(withIdentifier: "1")!
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        canMakePayments = SKPaymentQueue.canMakePayments()
        
        prices = AccountManager.shared.productPrices
        tableView.isHidden = false
        activity.stopAnimating()
        
        compilations.text = ""
        
        AccountManager.shared.storeViewController = self
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        compilations.text = "\(AccountManager.shared.compilations) 🐧"
        if plusOne {
            print("+1")
            let alert = AlertManager.shared.alert(withTitle: "+1 🐧", message: "You have now \(AccountManager.shared.compilations)🐧", style: .alert, actions: [AlertManager.shared.ok(handler: nil)])
            self.present(alert, animated: true, completion: nil)
            plusOne = false
        }
        
    }
    
    @IBAction func done(sender: Any) {
        self.dismiss(animated: true, completion:nil)
    }
    
    func buy(_ product: SKProduct) {
        print("Buy "+product.localizedTitle)
        let pay = SKPayment(product: product)
        currentPurchase = product
        AppDelegate.shared.currentPurchase = currentPurchase
        SKPaymentQueue.default().add(pay)
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
        print("Error loading ad! \(error.localizedDescription)")
        self.dismiss(animated: true, completion: nil)
    }
    
    
}
