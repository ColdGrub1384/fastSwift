# fastSwift

An iOS client for Swift compiler
<br/><br/>
<img src="http://coldg.ddns.net/wp-content/uploads/2017/05/fastSwift-1.png" width="100px">
<br/>

![Version](https://img.shields.io/badge/iOS-11.0%2B-blue.svg?style=flat) 
![Xcode](https://img.shields.io/badge/Xcode-9-blue.svg?style=flat)
![Swift](https://img.shields.io/badge/Swift-4-blue.svg?style=flat)
<br/>
<br/>

# THIS APP WILL NEVER BE RELEASED TO THE APP STORE DUE TO MULTIPLE REJECTIONS AND THE PROJECT IS DEPRECATED, USE PISTH TO RUN YOUR CODE FROM AN SSH SERVER.

fastSwift is a Swift IDE for your iPhone and iPad.
Program Swift and run it directly from your device.

Write your code in a editor with syntax highlighting, keyboard shortcuts and organise your project with multiple files.

Supports currently Swift 3.


# Features

- [x] Edit code with syntax highlighting and with shortcuts

- [x] Organise code into multiple files and compile as one   program

- [x] Run code in real time and with input

- [x] Publish scripts to be executed by other people

# Preview

<img src="https://is1-ssl.mzstatic.com/image/thumb/Purple118/v4/8d/bf/de/8dbfdef5-97d9-8e0b-2df4-8b30b5b6d65e/pr_source.png/0x0ss.jpg" width="35%" style="display: inline"><img src="https://is1-ssl.mzstatic.com/image/thumb/Purple128/v4/89/1e/94/891e948b-7e59-dc4d-50b0-d79b0cf5cac3/pr_source.png/0x0ss.jpg" width="35%" style="display: inline"><img src="https://is1-ssl.mzstatic.com/image/thumb/Purple118/v4/d3/0c/d4/d30cd4e6-753d-6457-4df2-e04a5d2a276e/pr_source.png/0x0ss.jpg" width="35%" style="display: inline"><img src="https://is1-ssl.mzstatic.com/image/thumb/Purple128/v4/03/c9/05/03c905b7-e47a-14f1-c3c1-953a42188aac/pr_source.png/0x0ss.jpg" width="35%" style="display: inline">

# App menu
When you open the app you have a ```UIDocumentBrowserViewController```, you can open and create Swift files or, sroll to the right or to the left, to the left, there are a WebView with an HTML file provided by fastSwift server and a QR Code scanner to open scripts. To the left, there are a store and a settings View Controller.

## Menu's hierarchy

### [```LaunchScreenViewController```](https://github.com/ColdGrub1384/fastSwift/blob/master/fastSwift/Classes/View%20Controllers/Main/LaunchScreenViewController.swift)
#### [```MenuViewController```](https://github.com/ColdGrub1384/fastSwift/blob/master/fastSwift/Classes/View%20Controllers/Menu/MenuViewController.swift)

[```QRScanViewController```](https://github.com/ColdGrub1384/fastSwift/blob/master/fastSwift/Classes/View%20Controllers/Camera/QRScanViewController.swift)
[```WebViewController```](https://github.com/ColdGrub1384/fastSwift/blob/master/fastSwift/Classes/View%20Controllers/Web/WebViewController.swift)
[```DocumentBrowserViewController```](https://github.com/ColdGrub1384/fastSwift/blob/master/fastSwift/Classes/View%20Controllers/DocumentBrowser/DocumentBrowserViewController.swift)
[```StoreViewController```](https://github.com/ColdGrub1384/fastSwift/blob/master/fastSwift/Classes/View%20Controllers/Store/StoreViewController.swift)
[```SettingsViewController```](https://github.com/ColdGrub1384/fastSwift/blob/master/fastSwift/Classes/View%20Controllers/Settings/SettingsViewController.swift)

# In App purchases
To compile scripts, you need compilations, you can buy compilations:
## 32 Compilations
Price: Tier 1
## 64 Compilations
Price: Tier 2
## 128 Compilations
Price: Tier 3
## 256 Compilations
Price: Tier 4
## Unlimited
<img src="http://coldg.ddns.net/files/Public/unlimited-icon.png" width="10%">

Price: Tier 5


# Code editor
The [code editor](https://github.com/ColdGrub1384/fastSwift/blob/master/fastSwift/Classes/View%20Controllers/Document/DocumentViewController.swift) is opened to edit a Swift script. It includes syntax highlighting and shortcuts for special characters. You can add another file to be part of the project and compile them with the hammer button. The output is shown.

# Terminal
The [terminal](https://github.com/ColdGrub1384/fastSwift/blob/master/fastSwift/Classes/View%20Controllers/Terminal/TerminalViewController.swift) is opened when a Swift project is compiled, it support real time output and input and HTML.

# Store
In the [store](https://github.com/ColdGrub1384/fastSwift/blob/master/fastSwift/Classes/View%20Controllers/Store/StoreViewController.swift), you can buy [In App Purchases](#in-app-purchases), download scripts made by other people and play [challenges](#challenges).

# Challenges
To play a challenge, go to store and select the challenge, write code to do, and if is correct the first time, you win a point.

# QR Codes
The [QR Code Scanner](https://github.com/ColdGrub1384/fastSwift/blob/master/fastSwift/Classes/View%20Controllers/Camera/QRScanViewController.swift) allows to scan QR Codes, and if the contents begin with $CODE=, the URL after $CODE= will be downloaded and opened. If it's a binary, it will be ran, and if it's a project, it will be opened with the editor.

If the contents begin with $SERVER=, the server after $SERVER= will be used to compile projects if the user says yes. The structure is $SERVER=username@host;password


## Test in your browser
Go to http://coldg.ddns.net:83/test.html to test the app in your Web Browser

## Acknowledgements
See licenses [here](https://github.com/ColdGrub1384/fastSwift/blob/master/Pods/Target%20Support%20Files/Pods-fastSwift/Pods-fastSwift-acknowledgements.markdown)
