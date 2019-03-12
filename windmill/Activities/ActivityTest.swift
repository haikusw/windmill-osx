//
//  ActivityTest.swift
//  windmill
//
//  Created by Markos Charatzas on 08/03/2019.
//  Copyright © 2019 qnoid.com. All rights reserved.
//

import Foundation

struct ActivityTest {

    let applicationCachesDirectory: ApplicationCachesDirectory
    let applicationSupportDirectory: ApplicationSupportDirectory

    weak var processManager: ProcessManager?
    weak var activityManager: ActivityManager?
    
    let log: URL

    func make(location: Project.Location, project: Project, devices: Devices, scheme: String) -> ActivitySuccess {
        
        let derivedData = self.applicationCachesDirectory.derivedData(at: project.name)
        let resultBundle = self.applicationSupportDirectory.testResultBundle(at: project.name)

        return { next in
            
            return { context in
             
                guard let destination = devices.destination else {
                    preconditionFailure("Destination must not be nil to proceeed. Did you use `ActivityDevices` to read the list of devices?")
                }
                
                let test: Process
                let userInfo: [AnyHashable: Any]
                
                if WindmillStringKey.Test.nothing == (context[WindmillStringKey.test] as? WindmillStringKey.Test) {
                    test = Process.makeSuccess() //no need to go through the process manager now, simply fire the notification for when an activity succeeds
                    userInfo = ["activity" : ActivityType.test, "resultBundle": resultBundle]
                } else {
                    userInfo = ["activity" : ActivityType.test, "artefact": ArtefactType.testReport, "devices": devices, "destination": destination, "resultBundle": resultBundle]
                    test = Process.makeTestWithoutBuilding(location: location, project: project, scheme: scheme, destination: destination, derivedData: derivedData, resultBundle: resultBundle, log: self.log)
                }
                
                self.processManager?.launch(process: test, userInfo: userInfo, wasSuccesful: { userInfo in
                    
                    self.activityManager?.didExitSuccesfully(activity: ActivityType.test, userInfo: userInfo)
                    
                    if let testsCount = resultBundle.info.testsCount, testsCount >= 0 {
                        self.activityManager?.post(notification: Windmill.Notifications.didTestProject, userInfo: ["project":project, "devices": devices, "destination": destination, "testsCount": testsCount, "testableSummaries": resultBundle.testSummaries?.testableSummaries ?? []])
                    }

                    next?([:])
                })
                self.activityManager?.didLaunch(activity: ActivityType.test, userInfo: userInfo)
            }
        }
    }
}