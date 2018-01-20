//
//  NSTasks.swift
//  windmill
//
//  Created by Markos Charatzas on 07/09/2014.
//  Copyright (c) 2014 qnoid.com. All rights reserved.
//

import Foundation
import os

let WINDMILL_BASE_URL_PRODUCTION = "https://api.windmill.io"
let WINDMILL_BASE_URL_DEVELOPMENT = "http://localhost:8080"

#if DEBUG
let WINDMILL_BASE_URL = WINDMILL_BASE_URL_DEVELOPMENT
#else
let WINDMILL_BASE_URL = WINDMILL_BASE_URL_PRODUCTION
#endif

extension Process {
    
    /* fileprivate */ func windmill_waitForDataInBackground(_ pipe: Pipe, queue: DispatchQueue, callback: @escaping (_ data: String, _ count: Int) -> Void) {
        
        let fileDescriptor = pipe.fileHandleForReading.fileDescriptor
        let readSource = DispatchSource.makeReadSource(fileDescriptor: fileDescriptor, queue: queue)
        
        readSource.setEventHandler {
            let estimated = Int(readSource.data)
            
            var buffer = [UInt8](repeating: 0, count: estimated)
            let count = read(fileDescriptor, &buffer, estimated)
            
            guard case let availableData = Data(buffer), count > 0 else {
                readSource.cancel()
                return
            }
            
            let availableString = String(data: availableData, encoding: .utf8) ?? ""

            DispatchQueue.main.async {
                callback(availableString, availableString.count)
            }
        }
        
        readSource.setCancelHandler {
            close(fileDescriptor)
        }
        
        readSource.activate()
    }
}

extension Windmill {
    
    func waitForStandardOutputInBackground(process: Process, queue: DispatchQueue, type: ActivityType) {
        let standardOutputPipe = Pipe()
        process.standardOutput = standardOutputPipe
        
        process.windmill_waitForDataInBackground(standardOutputPipe, queue: queue) { [weak process, weak self] availableString, count in
            guard let process = process else {
                return
            }
            
            self?.didReceive(process: process, type: type, standardOutput: availableString, count: count)
        }
    }
    
    func waitForStandardErrorInBackground(process: Process, queue: DispatchQueue, type: ActivityType) {
        let standardErrorPipe = Pipe()
        process.standardError = standardErrorPipe
        
        process.windmill_waitForDataInBackground(standardErrorPipe, queue: queue){ [weak process, weak self] availableString, count in
            guard let process = process else {
                return
            }

            self?.didReceive(process: process, type: type, standardError: availableString, count: count)
        }
    }
}

extension Process
{
    struct Notifications {
        static let activityDidLaunch = Notification.Name("activityDidLaunch")
        static let activityError = Notification.Name("activityError")
        static let activityDidExitSuccesfully = Notification.Name("activityDidExitSuccesfully")
        
        static func makeDidLaunchNotification(_ type: ActivityType) -> Notification {
            return Notification(name: activityDidLaunch, object: nil, userInfo: ["activity":type.rawValue])
        }
        static func makeErrorNotification(_ type: ActivityType) -> Notification {
            return Notification(name: activityError, object: nil, userInfo: ["activity":type.rawValue])
        }
        static func makeDidExitSuccesfullyNotification(_ type: ActivityType) -> Notification {
            return Notification(name: activityDidExitSuccesfully, object: nil, userInfo: ["activity":type.rawValue])
        }
    }
    
    fileprivate class func pathForDir(_ name: String) -> String! {
        return Bundle.main.path(forResource: name, ofType:nil);
    }

    public static func makeReadTestMetadata(directoryPath: String, forProject project: Project, metadata: Metadata) -> Process {
        
        let process = Process()
        process.currentDirectoryPath = directoryPath
        process.launchPath = Bundle.main.path(forResource: Scripts.CommandLineTools.READ_TEST_METADATA, ofType: "sh")!
        process.arguments = [metadata.url.path, project.scheme]
        process.qualityOfService = .utility
        
        return process
    }

    public static func makeCheckout(projectDirectoryURL: URL = ApplicationCachesDirectory().URL, branch: String = "master", repoName: String, origin: String) -> Process {
        
        let process = Process()
        process.launchPath = Bundle.main.path(forResource: Scripts.Git.CHECKOUT, ofType: "sh")!
        process.arguments = [projectDirectoryURL.path, self.pathForDir("scripts"), repoName, branch, origin]
        process.qualityOfService = .utility
        
        return process
    }
    
    public static func makeBuild(directoryPath: String, project: Project, configuration: Configuration = .debug) -> Process {
        
        let process = Process()
        process.currentDirectoryPath = directoryPath
        process.launchPath = Bundle.main.path(forResource: Scripts.Xcodebuild.BUILD, ofType: "sh")!
        process.arguments = [FileManager.default.windmillHomeDirectoryURL.path, project.name, project.scheme, configuration.name]
        process.qualityOfService = .utility
        
        return process
    }
    
    
    static func makeTest(directoryPath: String, scheme: String, metadata: Metadata) -> Process {
        
        let process = Process()
        process.currentDirectoryPath = directoryPath
        process.launchPath = Bundle.main.path(forResource: Scripts.Xcodebuild.TEST, ofType: "sh")!
        process.arguments = [metadata.url.path, scheme]
        process.qualityOfService = .utility
        
        return process
    }
    
    public static func makeArchive(directoryPath: String, project: Project, configuration: Configuration = .release) -> Process {
        
        let process = Process()
        process.currentDirectoryPath = directoryPath
        process.launchPath = Bundle.main.path(forResource: Scripts.Xcodebuild.ARCHIVE, ofType: "sh")!
        process.arguments = [FileManager.default.windmillHomeDirectoryURL.path, project.name, project.scheme, configuration.name]
        process.qualityOfService = .utility
        
        return process
    }
    
    public static func makeExport(directoryPath: String, project: Project) -> Process {
        
        let process = Process()
        process.currentDirectoryPath = directoryPath
        process.launchPath = Bundle.main.path(forResource: Scripts.Xcodebuild.EXPORT, ofType: "sh")!
        process.arguments = [FileManager.default.windmillHomeDirectoryURL.path, project.name, project.scheme, self.pathForDir("resources")]
        process.qualityOfService = .utility
        
        return process
    }
    
    public static func makeDeploy(directoryPath: String, project: Project, forUser user:String) -> Process {
        
        let process = Process()
        process.currentDirectoryPath = directoryPath
        process.launchPath = Bundle.main.path(forResource: Scripts.Xcodebuild.DEPLOY, ofType: "sh")!
        process.arguments = [FileManager.default.windmillHomeDirectoryURL.path, project.name, project.scheme, user, WINDMILL_BASE_URL]
        process.qualityOfService = .utility
        
        return process
    }
    
    static func makePoll(directoryPath: String, projectDirectoryURL: URL = ApplicationCachesDirectory().URL, project: Project, branch: String = "master") -> Process
    {
        let process = Process()
        process.currentDirectoryPath = directoryPath
        process.launchPath = Bundle.main.path(forResource: Scripts.Git.POLL, ofType: "sh")!
        process.arguments = [FileManager.default.pollDirectoryURL(forProject: project.name).path, self.pathForDir("scripts"), branch]
        process.qualityOfService = .utility
        
        return process
    }
}


