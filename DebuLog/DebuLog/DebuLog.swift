//
//  DebuLog.swift
//  DebuLog
//
//  Created by Adrian on 23.04.17.
//  Copyright © 2017 Adrian. All rights reserved.
//

import Foundation

open class DebuLog {
    open var file: URL? {
        get {
            return file_
        }
        
        set {
            file_ = newValue
        }
    }
    
    private var file_ = URL(string:"")
        
    public enum errors: Error {
        case errorWritingFile
        case errorWritingToFile
    }
    
    open func close() {
        do {try FileManager.default.removeItem(at: file!)} catch _ {}
    }
    
    public init() {
        print ("DebuLog instantiated!")
    }
    
    open func debug (_ thing:Any..., terminator:String) throws {
        print (thing, terminator: terminator)
        
        if file != nil {
            if !FileManager.default.fileExists(atPath: (file?.path)!) {
                FileManager.default.createFile(atPath: (file?.path)!, contents: nil, attributes: [:])
                
                if !FileManager.default.fileExists(atPath: (file?.path)!) {
                    throw errors.errorWritingFile
                }
            }
            do {
                let filehandle = try FileHandle(forWritingTo: file!)
                filehandle.seekToEndOfFile()
                
                filehandle.write("\n\(thing)".data(using: .utf8)!)
                filehandle.closeFile()
            } catch _ {
                throw errors.errorWritingToFile
            }
        }
    }
    
     open func debug (_ thing:Any) throws {
        print (thing)
        
        if file != nil {
            if !FileManager.default.fileExists(atPath: (file?.path)!) {
                FileManager.default.createFile(atPath: (file?.path)!, contents: nil, attributes: [:])
                
                if !FileManager.default.fileExists(atPath: (file?.path)!) {
                    throw errors.errorWritingFile
                }
            }
            
            do {
                let filehandle = try FileHandle(forWritingTo: file!)
                filehandle.seekToEndOfFile()
                
                filehandle.write("\n\(thing)".data(using: .utf8)!)
                filehandle.closeFile()
            } catch _ {
                throw errors.errorWritingToFile
            }
        }
    }
    
    
    open func debug_ (_ thing:Any..., terminator:String) {
        print (thing, terminator: terminator)
        
        if file != nil {
            if !FileManager.default.fileExists(atPath: (file?.path)!) {
                FileManager.default.createFile(atPath: (file?.path)!, contents: nil, attributes: [:])
            }
            
            do {
                let filehandle = try FileHandle(forWritingTo: file!)
                filehandle.seekToEndOfFile()
                
                filehandle.write("\n\(thing)".data(using: .utf8)!)
                filehandle.closeFile()
            } catch _ {}
        }
    }
    
    open func debug_ (_ thing:Any) {
        print (thing)
        
        if file != nil {
            if !FileManager.default.fileExists(atPath: (file?.path)!) {
                FileManager.default.createFile(atPath: (file?.path)!, contents: nil, attributes: [:])
            }
            
            do {
                let filehandle = try FileHandle(forWritingTo: file!)
                filehandle.seekToEndOfFile()
                
                filehandle.write("\n\(thing)".data(using: .utf8)!)
                filehandle.closeFile()
            } catch _ {}
        }
    }
}
