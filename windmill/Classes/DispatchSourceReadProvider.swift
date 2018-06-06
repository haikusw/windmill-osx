//
//  DispatchSourceReadProvider.swift
//  windmill
//
//  Created by Markos Charatzas on 20/4/18.
//  Copyright © 2018 qnoid.com. All rights reserved.
//

import Foundation

protocol DispatchSourceReadProvider {
    
    var queue: DispatchQueue { get }
    var fileHandleForReading: FileHandle? { get }
    
    func get(completion: DispatchQueue?) -> DispatchSourceRead?
    
    func output(part: String, count: Int)
}

extension DispatchSourceReadProvider {
    
    func get(completion: DispatchQueue? = nil) -> DispatchSourceRead? {
        
        guard let fileHandleForReading = fileHandleForReading else {
            return nil
        }
        
        let fileDescriptor = fileHandleForReading.fileDescriptor
        let readSource = DispatchSource.makeReadSource(fileDescriptor: fileDescriptor, queue: self.queue)
        
        readSource.setEventHandler { [weak readSource = readSource] in
            guard let data = readSource?.data else {
                return
            }
            
            let estimatedBytesAvailableToRead = Int(data)
            
            var buffer = [UInt8](repeating: 0, count: estimatedBytesAvailableToRead)
            let bytesRead = read(fileDescriptor, &buffer, estimatedBytesAvailableToRead)
            
            guard bytesRead > 0, let availableString = String(bytes: buffer, encoding: .utf8) else {
                return
            }
            
            (completion ?? DispatchQueue.main).async {
                self.output(part: availableString, count: availableString.utf8.count)
            }
        }
        
        readSource.setCancelHandler {
            fileHandleForReading.closeFile()
        }
        
        return readSource
    }
}