//
//  AlertManager.swift
//  fastSwift
//
//  Created by Adrian on 11.06.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit

class AlertManager {
    private init() {}
    static let shared = AlertManager()
    
    func openWebView(withURL url:URL, inside viewController: UIViewController) {
        let vc = AppViewControllers().web
        vc.url = url
        vc.modalTransitionStyle = .flipHorizontal
        
        viewController.present(vc, animated: true, completion: nil)
    }
    
    var connectionErrorViewController: UIViewController {
        return AppViewControllers().connectionError
    }
    
    func presentAlert(withTitle title:String, message:String, style: UIAlertControllerStyle, actions: [UIAlertAction], inside viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: style)
            alert.view.tintColor = Theme.current.tintColor
            
            for action in actions {
                alert.addAction(action)
            }
            
            viewController.present(alert, animated: animated, completion: completion)
        }
    }
    
    
    func alert(withTitle title:String, message:String, style: UIAlertControllerStyle, actions: [UIAlertAction]) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        alert.view.tintColor = Theme.current.tintColor
        
        for action in actions {
            alert.addAction(action)
        }
        return alert
    }
    
    func ok(handler:((UIAlertAction) -> Void)?) -> UIAlertAction {
        return UIAlertAction(title: "Ok", style: .default, handler: handler)
    }
    
    let cancel = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)
    
    func present(error: Error, withTitle title:String, inside viewController: UIViewController) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
            alert.view.tintColor = Theme.current.tintColor
            
            alert.addAction(self.ok(handler: nil))
            
            viewController.present(alert, animated: true, completion: nil)
        }
    }
}

class ActivityViewController: UIViewController {
    
    let activityView = ActivityView()
    
    init(message: String) {
        super.init(nibName: nil, bundle: nil)
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overFullScreen
        activityView.messageLabel.text = message
        view = activityView
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ActivityView: UIView {
    
    let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    let boundingBoxView = UIView(frame: CGRect.zero)
    let messageLabel = UILabel(frame: CGRect.zero)
    
    init() {
        super.init(frame: CGRect.zero)
        
        backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        
        boundingBoxView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        boundingBoxView.layer.cornerRadius = 12.0
        
        activityIndicatorView.startAnimating()
        
        messageLabel.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
        messageLabel.textColor = UIColor.white
        messageLabel.textAlignment = .center
        messageLabel.shadowColor = UIColor.black
        messageLabel.shadowOffset = CGSize(width: 0, height: 1)
        messageLabel.numberOfLines = 0
        
        addSubview(boundingBoxView)
        addSubview(activityIndicatorView)
        addSubview(messageLabel)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        boundingBoxView.frame.size.width = 160.0
        boundingBoxView.frame.size.height = 160.0
        boundingBoxView.frame.origin.x = ceil((bounds.width / 2.0) - (boundingBoxView.frame.width / 2.0))
        boundingBoxView.frame.origin.y = ceil((bounds.height / 2.0) - (boundingBoxView.frame.height / 2.0))
        
        activityIndicatorView.frame.origin.x = ceil((bounds.width / 2.0) - (activityIndicatorView.frame.width / 2.0))
        activityIndicatorView.frame.origin.y = ceil((bounds.height / 2.0) - (activityIndicatorView.frame.height / 2.0))
        
        let messageLabelSize = messageLabel.sizeThatFits(CGSize(width:160.0 - 20.0 * 2.0, height: CGFloat.greatestFiniteMagnitude))
        messageLabel.frame.size.width = messageLabelSize.width
        messageLabel.frame.size.height = messageLabelSize.height
        messageLabel.frame.origin.x = ceil((bounds.width / 2.0) - (messageLabel.frame.width / 2.0))
        messageLabel.frame.origin.y = ceil(activityIndicatorView.frame.origin.y + activityIndicatorView.frame.size.height + ((boundingBoxView.frame.height - activityIndicatorView.frame.height) / 4.0) - (messageLabel.frame.height / 2.0))
    }
}

