#!/bin/bash

xcodebuild -quiet -scheme fastSwift -workspace *.xcworkspace clean archive -archivePath build/archive
xcodebuild -quiet -exportArchive -archivePath "build/archive.xcarchive" -exportPath "build/application.ipa" -exportOptionsPlist ExportOptions.plist

