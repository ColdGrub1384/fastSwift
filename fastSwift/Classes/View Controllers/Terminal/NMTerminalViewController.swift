//
//  NMTerminalViewController.swift
//  fastFiles
//
//  Created by Adrian on 16.04.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import UIKit
import NMSSH
import Zip


class NMTerminalViewController: UIViewController, NMSSHSessionDelegate, NMSSHChannelDelegate, UITextViewDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var terminal: TerminalTextView!
    var session = NMSSHSession()
    var command = ""
    var host = UserDefaults.standard.string(forKey: "IP")
    var user = UserDefaults.standard.string(forKey: "USER")
    var password = UserDefaults.standard.string(forKey: "PASSWORD")
    var project = ""
    var needsUserInput = true
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var navBar: UINavigationBar!
    var mainFile = ""
    var delegate: DocumentViewController?
    var browserVC: DocumentBrowserViewController?
    var console = ""
    var reopen = false
    var downloadExec = false
    var guiViewController: UIViewController?
    
    var terminalHTML: String {
        return try! String(contentsOfFile: Bundle.main.path(forResource: "terminal", ofType: "html")!).replacingOccurrences(of: "$BACKGROUNDCOLOR", with:"#"+Theme.current.color.hexString).replacingOccurrences(of: "$TEXTCOLOR", with: "#"+Theme.current.textColor.hexString)
    }
    
    var consoleHTML = ""
    
    @objc func closeGUIViewController() {
        guiViewController?.dismiss(animated: true, completion: {
            do { try self.session.channel.write("closeWindow\n") } catch _ {}
            self.guiViewController = nil
        })
    }
    
    // -------------------------------------------------------------------------
    // MARK: UIViewController
    // -------------------------------------------------------------------------
    
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let delegate = browserVC {
            delegate.viewDidAppear(true)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        terminal.layoutManager.allowsNonContiguousLayout = false
        terminal.isSelectable = false
        terminal.delegate = self
        terminal.isEditable = true
        terminal.keyboardAppearance = Theme.current.keyboardAppearance
        terminal.tintColor = Theme.current.textColor
        terminal.text = "\n"
        terminal.isHidden = true
        if needsUserInput {
            terminal.becomeFirstResponder()
        }
        terminal.backgroundColor = Theme.current.color
        terminal.textColor = terminal.tintColor
        navBar.barStyle = Theme.current.barStyle
        navBar.barTintColor = Theme.current.color
        view.backgroundColor = Theme.current.color
        view.tintColor = Theme.current.tintColor
        
        // Update text view size
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
                
        session = NMSSHSession.connect(toHost: host, withUsername: user)
        if (session.isConnected) {
            session.authenticate(byPassword: password)
            if (session.isAuthorized) {
                session.channel.delegate = self
                session.delegate = self
                session.channel.requestSizeWidth(UInt(self.view.frame.size.width), height: UInt(self.view.frame.size.height))
                session.channel.requestPty = true
                
                do {
                    try session.channel.startShell()
                    try session.channel.write("echo Progr\\am output;"+command+"\n")
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
        
        if let item = navBar.items?.first {
            item.title = "Output"
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        terminal.becomeFirstResponder()
    }
    
    @IBAction func disconnect(_ sender: Any) {
        session.disconnect()
        self.dismiss(animated: true, completion: {
            
            if self.reopen {
                AppDelegate.shared.window?.rootViewController = AppViewControllers().launchScreen
                _ = Afte.r(1, seconds: { (timer) in
                    AppDelegate.shared.applicationWillTerminate(UIApplication.shared)
                    _ = AppDelegate.shared.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                })
            }
            
        })
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Theme.current.statusBarStyle
    }
    
    // -------------------------------------------------------------------------
    // MARK: NMSSHChannelDelegate
    // -------------------------------------------------------------------------
    
    func channelShellDidClose(_ channel: NMSSHChannel!) {
        DispatchQueue.main.async {
            print("Shell closed!")
            self.terminal.resignFirstResponder()
            self.terminal.isEditable = false
            self.activity.stopAnimating()
            self.terminal.isSelectable = true
            self.terminal.tintColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        }
    }
    
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        DispatchQueue.main.async {
            
            self.terminal.text = (self.terminal.text+message).replacingOccurrences(of: "\n", with: "<br/>")
            self.consoleHTML = (self.consoleHTML+message).replacingOccurrences(of: "\n", with: "<br/>")
            
            print(self.terminal.text)
            
            if self.terminal.text.contains("Program output") { // Clear shell
                let newString = self.terminal.text.components(separatedBy: "Program output")
                let newHTML = self.consoleHTML.components(separatedBy: "Program output")
                
                self.activity.stopAnimating()
                self.terminal.text = newString[1]
                self.consoleHTML = newHTML[1]
                self.console = self.terminal.text
                self.terminal.isHidden = false
            }
            
            
            if self.terminal.text.contains("<showAlert>") { // Show an alert
                if let text = self.terminal.text.slice(from: "<showAlert>", to: "</showAlert>") {
                    if let buttonsStr = text.slice(from: "<buttons>", to: "</buttons>") {
                        let buttons = buttonsStr.components(separatedBy: "<bt>")
                        var actions = [UIAlertAction]()
                        for button in buttons {
                            actions.append(UIAlertAction(title: button, style: .default, handler: { (action) in
                                if self.terminal.isFirstResponder {
                                    do {
                                        try self.session.channel.write(button+"\n")
                                    } catch _ {
                                        self.present(AppViewControllers().connectionError, animated: true, completion: nil)
                                    }
                                }
                            }))
                        }
                        
                        var title = ""
                        
                        if let title_ = text.slice(from: "<title>", to: "</title>") {
                            title = title_
                        }
                        
                        var msg = ""
                        
                        if let msg_ = text.slice(from: "<message>", to: "</message>") {
                            msg = msg_
                        }
                        
                        AppDelegate.shared.topViewController()?.present(AlertManager.shared.alert(withTitle: title, message: msg, style: .alert, actions: actions), animated: true, completion: nil)
                    }
                }
                
                self.terminal.text = self.terminal.text.replacingFirstOccurrence(of: self.terminal.text.slice(from: "<showAlert>", to: "</showAlert>")!, with: "")
                self.terminal.text = self.terminal.text.replacingFirstOccurrence(of: "<showAlert>", with: "")
                self.terminal.text = self.terminal.text.replacingFirstOccurrence(of: "</showAlert>", with: "")
                
                self.consoleHTML = self.consoleHTML.replacingFirstOccurrence(of: self.consoleHTML.slice(from: "<showAlert>", to: "</showAlert>")!, with: "")
                self.consoleHTML = self.consoleHTML.replacingFirstOccurrence(of: "<showAlert>", with: "")
                self.consoleHTML = self.consoleHTML.replacingFirstOccurrence(of: "</showAlert>", with: "")
            }
            
            if self.terminal.text.contains("Show activity") {
                self.activity.startAnimating()
                self.terminal.text = self.terminal.text.replacingOccurrences(of: "Show activity", with: "")
                self.console = self.terminal.text
                self.consoleHTML = self.consoleHTML.replacingOccurrences(of: "Show activity", with: "")
            }
            
            if self.terminal.text.contains("Hide activity") {
                self.activity.stopAnimating()
                self.terminal.text = self.terminal.text.replacingOccurrences(of: "Hide activity", with: "")
                self.console = self.terminal.text
                self.consoleHTML = self.consoleHTML.replacingOccurrences(of: "Hide activity", with: "")
            }
            
            if self.terminal.text.contains("closeWindow") {
                self.closeGUIViewController()
                self.terminal.text = self.terminal.text.replacingOccurrences(of: "closeWindow", with: "")
            }
            
            if self.terminal.text.contains("<GUI>") { // Show GUI
                if let gui = self.terminal.text.slice(from: "<GUI>", to: "</GUI>") {
                    
                    class FFViewController: UIViewController {
                        
                        var navBar: UINavigationBar!
                        var items = [UIBarButtonItem]()
                        var terminal: NMTerminalViewController!
                        
                        override var preferredStatusBarStyle: UIStatusBarStyle {
                            return Theme.current.statusBarStyle
                        }
                        
                        override func viewDidAppear(_ animated: Bool) {
                            super.viewDidAppear(animated)
                            
                            print("Title: \(title ?? "nil")")
                            
                            navBar.setItems([UINavigationItem(title: title ?? "")], animated: true)
                            navBar.topItem?.setRightBarButtonItems(items, animated: true)
                        }
                    }
                    
                    class FFButton: UIButton {
                        var id: String?
                        var terminal: NMTerminalViewController!
                        
                        @objc func sendData() {
                            do { try self.terminal.session.channel.write("button;\(id ?? "")\n") } catch _ {}
                        }
                        
                    }
                    
                    class FFTextField: UITextField, UITextFieldDelegate {
                        var id: String?
                        var terminal: NMTerminalViewController!
                        
                        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
                            textField.resignFirstResponder()
                            sendData()
                            
                            return true
                        }
                        
                        func sendData() {
                            do { try self.terminal.session.channel.write("textfield;\(id ?? "");\(self.text ?? "")\n") } catch _ {}
                        }
                        
                    }
                    
                    func color(fromString string: String) -> UIColor? {
                        guard let redString = string.slice(from: "<red>", to: "</red>") else { return nil }
                        guard let red = Float(redString) else { return nil }
                        
                        guard let greenString = string.slice(from: "<green>", to: "</green>") else { return nil }
                        guard let green = Float(greenString) else { return nil }
                        
                        guard let blueString = string.slice(from: "<blue>", to: "</blue>") else { return nil }
                        guard let blue = Float(blueString) else { return nil }
                        
                        guard let alphaString = string.slice(from: "<alpha>", to: "</alpha>") else { return nil }
                        guard let alpha = Float(alphaString) else { return nil }
                        
                        return UIColor(displayP3Red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
                    }
                    
                    func frame(fromString string: String) -> CGRect? {
                        guard let xString = string.slice(from: "<x>", to: "</x>") else { return nil }
                        guard let x = Float(xString) else { return nil }
                        
                        guard let yString = string.slice(from: "<y>", to: "</y>") else { return nil }
                        guard let y = Float(yString) else { return nil }
                        
                        guard let widthString = string.slice(from: "<width>", to: "</width>") else { return nil }
                        guard let width = Float(widthString) else { return nil }
                        
                        guard let heigthString = string.slice(from: "<height>", to: "</height>") else { return nil }
                        guard let heigth = Float(heigthString) else { return nil }
                        
                        return CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(heigth))
                    }
                    
                    
                    self.guiViewController = FFViewController()
                    
                    guard let vc = self.guiViewController as? FFViewController else { return }
                    
                    vc.terminal = self
                    
                    vc.view.backgroundColor = .white
                    
                    // Set background color
                    if let backgroundColorString = gui.slice(from: "<backgroundColor>", to: "</backgroundColor>") {
                        if let color = color(fromString: backgroundColorString) {
                            vc.view.backgroundColor = color
                        }
                    }
                    
                    if vc.view.backgroundColor == .clear || vc.view.backgroundColor == UIColor(red: 0, green: 0, blue: 0, alpha: 0) {
                        vc.view.backgroundColor = Theme.current.color
                    }
                    
                    let navBar = UINavigationBar(frame: CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height:44))
                    navBar.barStyle = self.navBar.barStyle
                    navBar.barTintColor = self.navBar.barTintColor
                    navBar.tintColor = self.navBar.tintColor
                    
                    let statusBar = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height:20))
                    statusBar.backgroundColor = Theme.current.color
                    
                    // Set title
                    if let title = self.terminal.text.slice(from: "<title>", to: "</title>") {
                        vc.title = title
                    }
                    
                    vc.view.addSubview(navBar)
                    vc.view.addSubview(statusBar)
                    
                    vc.navBar = navBar
                    
                    vc.view.tintColor = self.view.tintColor
                    
                    let close = UIBarButtonItem.init(barButtonSystemItem: .stop, target: self, action: #selector(self.closeGUIViewController))
                    vc.items.append(close)
                    
                    var views = [UIView]()
                    
                    var gui_ = gui
                    
                    var currentView = gui_.slice(from: "<FFView>",to: "</FFView>") // FFView
                    if currentView != nil {
                        while true {
                            if let frameString = currentView?.slice(from: "<frame>", to: "</frame>") {
                                if let frame = frame(fromString: frameString) {
                                    
                                    if let backgroundColorString = currentView?.slice(from: "<backgroundColor>", to: "</backgroundColor>") {
                                        if let backgroundColor = color(fromString: backgroundColorString) {
                                            
                                            let newView = UIView(frame: frame)
                                            newView.backgroundColor = backgroundColor
                                            
                                            views.append(newView)
                                        }
                                    }
                                }
                            }
                                
                            
                            if let currentView_ = gui_.slice(from: "<FFView>",to: "</FFView>") {
                                gui_ = gui_.replacingFirstOccurrence(of: currentView!, with: "")
                                gui_ = gui_.replacingFirstOccurrence(of: "<FFView>", with: "")
                                gui_ = gui_.replacingFirstOccurrence(of: "</FFView>", with: "")
                                currentView = currentView_
                            } else {
                                break
                            }
                        }
                    }
                    
                    currentView = gui_.slice(from: "<FFLabel>",to: "</FFLabel>") // FFLabel
                    if currentView != nil {
                        while true {
                            if let frameString = currentView?.slice(from: "<frame>", to: "</frame>") {
                                if let frame = frame(fromString: frameString) {
                                    
                                    if let backgroundColorString = currentView?.slice(from: "<backgroundColor>", to: "</backgroundColor>") {
                                        if let backgroundColor = color(fromString: backgroundColorString) {
                                            
                                            if let text = currentView?.slice(from: "<text>", to: "</text>") {
                                                
                                                if let textColorString = currentView?.slice(from: "<textColor>", to: "</textColor>") {
                                                    if let textColor = color(fromString: textColorString) {
                                                        if let font = currentView?.slice(from: "<font>", to: "</font>") {
                                                            if let fontName = font.slice(from: "<name>", to: "</name>") {
                                                                if let fontSizeString = font.slice(from: "<size>", to: "</size>") {
                                                                    if let fontSize = Float(fontSizeString) {
                                                                        if let alignment = currentView?.slice(from: "<alignment>", to: "</alignment>") {
                                                                            let newView = UILabel(frame: frame)
                                                                            newView.backgroundColor = backgroundColor
                                                                            newView.text = text
                                                                            newView.textColor = textColor
                                                                            newView.font = UIFont(name: fontName, size: CGFloat(fontSize))
                                                                            
                                                                            if newView.textColor == .clear || newView.textColor == UIColor(red: 0, green: 0, blue: 0, alpha: 0) {
                                                                                newView.textColor = Theme.current.textColor
                                                                            }
                                                                            
                                                                            switch alignment {
                                                                            case "left":
                                                                                newView.textAlignment = .left
                                                                            case "right":
                                                                                newView.textAlignment = .right
                                                                            default:
                                                                                newView.textAlignment = .center
                                                                            }
                                                                            
                                                                            views.append(newView)
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            if let currentView_ = gui_.slice(from: "<FFLabel>",to: "</FFLabel>") {
                                gui_ = gui_.replacingFirstOccurrence(of: currentView!, with: "")
                                gui_ = gui_.replacingFirstOccurrence(of: "<FFLabel>", with: "")
                                gui_ = gui_.replacingFirstOccurrence(of: "</FFLabel>", with: "")
                                currentView = currentView_
                            } else {
                                break
                            }
                        }
                    }
                            
                    currentView = gui_.slice(from: "<FFButton>",to: "</FFButton>") // FFButton
                    if currentView != nil {
                        while true {
                            if let frameString = currentView?.slice(from: "<frame>", to: "</frame>") {
                                if let frame = frame(fromString: frameString) {
                                    
                                    if let backgroundColorString = currentView?.slice(from: "<backgroundColor>", to: "</backgroundColor>") {
                                        if let backgroundColor = color(fromString: backgroundColorString) {
                                            
                                            if let text = currentView?.slice(from: "<text>", to: "</text>") {
                                                
                                                if let textColorString = currentView?.slice(from: "<textColor>", to: "</textColor>") {
                                                    if let textColor = color(fromString: textColorString) {
                                                        if let font = currentView?.slice(from: "<font>", to: "</font>") {
                                                            if let fontName = font.slice(from: "<name>", to: "</name>") {
                                                                if let fontSizeString = font.slice(from: "<size>", to: "</size>") {
                                                                    if let fontSize = Float(fontSizeString) {
                                                                        if let id = currentView?.slice(from: "<id>", to: "</id>") {
                                                                            let newView = FFButton(frame: frame)
                                                                            newView.backgroundColor = backgroundColor
                                                                            newView.setTitle(text, for: .normal)
                                                                            
                                                                            if textColor == .clear || textColor == UIColor(red: 0, green: 0, blue: 0, alpha: 0) {
                                                                                newView.setTitleColor(vc.view.tintColor, for: .normal)
                                                                            } else {
                                                                                newView.setTitleColor(textColor, for: .normal)
                                                                            }
                                                                            
                                                                            newView.titleLabel?.font = UIFont(name: fontName, size: CGFloat(fontSize))
                                                                            
                                                                            newView.id = id
                                                                            newView.addTarget(newView, action: #selector(newView.sendData), for: .touchUpInside)
                                                                            
                                                                            newView.terminal = self
                                                                            views.append(newView)
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            if let currentView_ = gui_.slice(from: "<FFButton>",to: "</FFButton>") {
                                gui_ = gui_.replacingFirstOccurrence(of: currentView!, with: "")
                                gui_ = gui_.replacingFirstOccurrence(of: "<FFButton>", with: "")
                                gui_ = gui_.replacingFirstOccurrence(of: "</FFButton>", with: "")
                                currentView = currentView_
                            } else {
                                break
                            }
                        }
                    }
                    
                    currentView = gui_.slice(from: "<FFTextField>",to: "</FFTextField>") // FFTextField
                    if currentView != nil {
                        while true {
                            if let frameString = currentView?.slice(from: "<frame>", to: "</frame>") {
                                if let frame = frame(fromString: frameString) {
                                    
                                    if let backgroundColorString = currentView?.slice(from: "<backgroundColor>", to: "</backgroundColor>") {
                                        if let backgroundColor = color(fromString: backgroundColorString) {
                                            
                                            if let text = currentView?.slice(from: "<text>", to: "</text>") {
                                                
                                                if let textColorString = currentView?.slice(from: "<textColor>", to: "</textColor>") {
                                                    if let textColor = color(fromString: textColorString) {
                                                        if let alignment = currentView?.slice(from: "<alignment>", to: "</alignment>") {
                                                            if let placeholder = currentView?.slice(from: "<placeholder>", to: "</placeholder>") {
                                                                if let id = currentView?.slice(from: "<id>", to: "</id>") {
                                                                    let newView = FFTextField(frame: frame)
                                                                    newView.backgroundColor = backgroundColor
                                                                    newView.placeholder = placeholder
                                                                    newView.text = text
                                                                    newView.textColor = textColor
                                                                    newView.isSecureTextEntry = (currentView?.contains("</isSecure>") ?? false)
                                                                    
                                                                    switch alignment {
                                                                    case "left":
                                                                        newView.textAlignment = .left
                                                                    case "right":
                                                                        newView.textAlignment = .right
                                                                    default:
                                                                        newView.textAlignment = .center
                                                                    }
                                                                    
                                                                    newView.id = id
                                                                    
                                                                    newView.terminal = self
                                                                    newView.delegate = newView
                                                                    views.append(newView)
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            if let currentView_ = gui_.slice(from: "<FFTextField>",to: "</FFTextField>") {
                                gui_ = gui_.replacingFirstOccurrence(of: currentView!, with: "")
                                gui_ = gui_.replacingFirstOccurrence(of: "<FFTextField>", with: "")
                                gui_ = gui_.replacingFirstOccurrence(of: "</FFTextField>", with: "")
                                currentView = currentView_
                            } else {
                                break
                            }
                        }
                    }
                            
                            
                    for view in views {
                        vc.view.addSubview(view)
                    }
                    
                    if let currentGUIState = AppDelegate.shared.topViewController() as? FFViewController {
                        currentGUIState.dismiss(animated: false, completion: {
                            self.present(vc, animated: false, completion: nil)
                        })
                    } else {
                        self.present(vc, animated: true, completion: nil)
                    }
                    
                    self.terminal.text = self.terminal.text.replacingFirstOccurrence(of: gui, with: "")
                    self.terminal.text = self.terminal.text.replacingOccurrences(of: "<GUI>", with: "")
                    self.terminal.text = self.terminal.text.replacingOccurrences(of: "</GUI>", with: "")
                }
            }
            
            if self.terminal.text.contains("<theme>") {
                if let theme = self.terminal.text.slice(from: "<theme>", to: "</theme>") {
                    let color = theme.slice(from: "<color>", to: "</color>")
                    let tint = theme.slice(from: "<tintColor>", to: "</tintColor>")
                    let textColor = theme.slice(from: "<textColor>", to: "</textColor>")
                    let barStyle = theme.slice(from: "<barStyle>", to: "</barStyle>")
                    let keyboard = theme.slice(from: "<keyboard>", to: "</keyboard>")
                    let statusBar = theme.slice(from: "<statusBarStyle>", to: "</statusBarStyle>")
                    let browserStyle = theme.slice(from: "<browserStyle>", to: "</browserStyle>")
                    let codeEditorBackground = theme.slice(from: "<codeEditorBackground>", to: "</codeEditorBackground>")
                    let codeEditorTheme = theme.slice(from: "<codeEditorTheme>", to: "</codeEditorTheme>")
                    let alternateIcon = theme.slice(from: "<alternateIcon>", to: "</alternateIcon>")

                    
                    self.present(AlertManager.shared.alert(withTitle: "Available theme!", message: "This program want to install a theme", style: .alert, actions: [UIAlertAction.init(title: "Install", style: .default, handler: { (action) in
                        
                        if color != nil {
                            if tint != nil {
                                if textColor != nil {
                                    if barStyle != nil {
                                        if keyboard != nil {
                                            if statusBar != nil {
                                                if browserStyle != nil {
                                                    if codeEditorBackground != nil {
                                                        if codeEditorTheme != nil {
                                                            if alternateIcon != nil {
                                                                UserDefaults.standard.set("custom", forKey: "theme")
                                                                UserDefaults.standard.set(color, forKey: "ct_color")
                                                                UserDefaults.standard.set(tint, forKey: "ct_tint")
                                                                UserDefaults.standard.set(textColor, forKey: "ct_text")
                                                                UserDefaults.standard.set(barStyle, forKey: "ct_bar")
                                                                UserDefaults.standard.set(keyboard, forKey: "ct_keyboard")
                                                                UserDefaults.standard.set(statusBar, forKey: "ct_sbar")
                                                                UserDefaults.standard.set(browserStyle, forKey: "ct_browser")
                                                                UserDefaults.standard.set(codeEditorBackground, forKey: "ct_eback")
                                                                UserDefaults.standard.set(codeEditorTheme, forKey: "ct_etheme")
                                                                UserDefaults.standard.set(alternateIcon, forKey: "ct_icon")
                                                                
                                                                self.reopen = true
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                    }), AlertManager.shared.cancel]), animated: true, completion: nil)
                    
                    self.terminal.text = self.terminal.text.replacingFirstOccurrence(of: theme, with: "")
                    self.terminal.text = self.terminal.text.replacingFirstOccurrence(of: "<theme>", with: "")
                    self.terminal.text = self.terminal.text.replacingFirstOccurrence(of: "</theme>", with: "")
                    
                }
                
            }
            
            
            if self.terminal.text.contains("DownloadBinaryFileNow") {
                let inCurrentVC = self.terminal.text.contains("DownloadBinaryFileNowInCurrentVC")
                self.terminal.text = self.terminal.text.replacingOccurrences(of: "DownloadBinaryFileNow", with: "")
                
                let file = try! self.session.channel.execute("ls /home/\(Server.user)/\(UIDevice.current.identifierForVendor!.uuidString)/main")
                
                let fileExists = (file.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "") == "/home/\(Server.user)/\(UIDevice.current.identifierForVendor!.uuidString)/main")
                
                if fileExists {
                    self.terminal.text = "Downloading executable file..."
                    _ = try? self.session.channel.execute("zip \(UIDevice.current.identifierForVendor!.uuidString)/main.zip \(UIDevice.current.identifierForVendor!.uuidString)/main")
                    
                    let fileURL = URL(string:"http://\(Server.default.host)/dl.php?f=/home/\(Server.user)/\(UIDevice.current.identifierForVendor!.uuidString)/main.zip")!
                    print(fileURL)
                    URLSession.shared.downloadTask(with: fileURL, completionHandler: { (url, response, error) in
                        do {try self.session.channel.write("\n")} catch _ {}
                        if error == nil {
                            if url != nil {
                                do {
                                    let destURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!.appendingPathComponent(self.mainFile+".swiftc")
                                    
                                    print("DEST URL: \(destURL.absoluteString)")
                                    
                                    if FileManager.default.fileExists(atPath: destURL.path) {
                                        try FileManager.default.removeItem(at: destURL)
                                    }
                                    
                                    print("ZIP URL: \(destURL.deletingLastPathComponent().appendingPathComponent(self.mainFile+".tmp"+".zip"))")
                                    
                                    try FileManager.default.copyItem(at: url!, to: destURL.deletingLastPathComponent().appendingPathComponent(self.mainFile+".tmp"+".zip"))
                                    
                                    let unziped = try Zip.quickUnzipFile(destURL.deletingLastPathComponent().appendingPathComponent(self.mainFile+".tmp"+".zip"))
                                    
                                    try FileManager.default.moveItem(at: unziped.appendingPathComponent(UIDevice.current.identifierForVendor!.uuidString).appendingPathComponent("main"), to: destURL)
                                    try FileManager.default.removeItem(at: unziped)
                                    try FileManager.default.removeItem(at:
                                        destURL.deletingLastPathComponent().appendingPathComponent(self.mainFile+".tmp"+".zip"))
                                    
                                    
                                    let publish = PublishToStoreActivity()
                                    publish.fileURL = destURL
                                    publish.delegate = self.delegate
                                    
                                    let activityVC = UIActivityViewController(activityItems: [destURL], applicationActivities: [publish])
                                    
                                    _ = try? self.session.channel.execute("rm -rf /home/\(Server.user)/\(UIDevice.current.identifierForVendor!.uuidString)")
                                    
                                    if !inCurrentVC {
                                        self.dismiss(animated: true, completion: {
                                            self.delegate?.present(activityVC, animated: true, completion: nil)
                                            self.session.disconnect()
                                            
                                            if self.downloadExec {
                                                AccountManager.shared.compilations.substract(1)
                                                self.delegate?.compilations.title = "\(AccountManager.shared.compilations.description) 🐧"
                                            }
                                        })
                                    } else {
                                        self.present(activityVC, animated: true, completion: nil)
                                    }
                                    
                                } catch let error {
                                    AlertManager.shared.present(error: error, withTitle: "Error saving file!", inside: self)
                                }
                            }
                        } else {
                            self.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                        }
                    }).resume()
                    
                } else {
                    self.session.disconnect()
                }
            }
            
            if let html = (self.consoleHTML+self.terminalHTML).attributedStringFromHTML {
                self.terminal.attributedText = html
            }
            
            self.terminal.scrollToBotom()
            self.console = self.terminal.text
        }
        
    }
    
    // -------------------------------------------------------------------------
    // MARK: TextView
    // -------------------------------------------------------------------------
    
    @objc func keyboardWillShow(_ notification:Notification) {
        let d = notification.userInfo!
        var r = d[UIKeyboardFrameEndUserInfoKey] as! CGRect
        
        r = self.terminal.convert(r, from:nil)
        self.terminal.contentInset.bottom = r.size.height+50
        self.terminal.scrollIndicatorInsets.bottom = r.size.height+50
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        self.terminal.contentInset = .zero
        self.terminal.scrollIndicatorInsets = .zero
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if (textView.text as NSString).replacingCharacters(in: range, with: text).count >= console.count {
            if text.contains("\n") {
                let newConsole = textView.text+text
                let console = self.console
                print("newConsole: \(newConsole)")
                let cmd = newConsole.replacingOccurrences(of: console, with: "")
                print("Command: { \(cmd) }")
                do {
                    let range = newConsole.range(of: cmd)
                    textView.text = newConsole.replacingCharacters(in: range!, with: "")
                    
                    try session.channel.write(cmd)
                    return false
                } catch _ {
                    self.present(AlertManager.shared.connectionErrorViewController, animated: true, completion: nil)
                }
            }
            
            
            return true
        }
        
        return false
    }

    func textExceedBoundsOf(_ textView: UITextView) -> Bool {
        let textHeight = textView.contentSize.height
        return textHeight > textView.bounds.height
    }
}
