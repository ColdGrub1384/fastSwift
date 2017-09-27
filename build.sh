#!/bin/bash

xcodebuild -scheme fastSwift -workspace *.xcworkspace clean archive -archivePath build/archive
xcodebuild -exportArchive -archivePath "build/archive.xcarchive" -exportPath "build/application.ipa" -exportOptionsPlist ExportOptions.plist

