//
//  ArtefactsViewController.swift
//  windmill
//
//  Created by Markos Charatzas (markos@qnoid.com) on 24/1/18.
//  Copyright © 2014-2020 qnoid.com. All rights reserved.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation is required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source distribution.
//

import Cocoa
import os

public enum ArtefactType
{
    case appBundle
    case testReport
    case archiveBundle
    case ipaFile
    case otaDistribution
}

@IBDesignable class ArtefactsViewControllerView: NSView {
    
    
}

extension ActivityType {
    
    func artefact() -> [ArtefactType] {
        switch self {
        case .build:
            return [.appBundle]
        case .test:
            return [.testReport]
        case .archive:
            return [.archiveBundle]
        case .export:
            return [.ipaFile]
        case .distribute:
            return [.otaDistribution]
        default:
            return []
        }
    }
}

class ArtefactsViewController: NSViewController {

    @IBOutlet weak var buildArtefactView: ArtefactView! {
        didSet {
            buildArtefactView.headerTextField.string = NSLocalizedString("windmill.artefacts.build.header", comment: "")
            buildArtefactView.toolTip = NSLocalizedString("windmill.artefacts.build.tooltip", comment: "")
            buildArtefactView.leadingLabel.stringValue = "Make sure:"
            buildArtefactView.isHidden = true
        }
    }
    @IBOutlet weak var testArtefactView: ArtefactView! {
        didSet {
            testArtefactView.headerTextField.string = NSLocalizedString("windmill.reports.test.header", comment: "")
            testArtefactView.toolTip = NSLocalizedString("windmill.reports.test.tooltip", comment: "")
            testArtefactView.leadingLabel.stringValue = "You need to:"
            testArtefactView.isHidden = true
        }
    }
    @IBOutlet weak var archiveArtefactView: ArtefactView! {
        didSet {
            archiveArtefactView.headerTextField.string = NSLocalizedString("windmill.artefacts.archive.header", comment: "")
            archiveArtefactView.toolTip = NSLocalizedString("windmill.artefacts.archive.tooltip", comment: "")
            archiveArtefactView.isHidden = true
        }
    }
    @IBOutlet weak var exportArtefactView: ArtefactView! {
        didSet {
            exportArtefactView.headerTextField.string = NSLocalizedString("windmill.artefacts.ipa.header", comment: "")
            exportArtefactView.toolTip = NSLocalizedString("windmill.artefacts.ipa.tooltip", comment: "")
            exportArtefactView.leadingLabel.stringValue = ""
            exportArtefactView.isHidden = true
        }
    }
    @IBOutlet weak var distributeArtefactView: ArtefactView! {
        didSet {
            distributeArtefactView.headerTextField.string = NSLocalizedString("windmill.aspects.ota.header", comment: "")
            distributeArtefactView.leadingLabel.stringValue = "You need to:"
            distributeArtefactView.toolTip = NSLocalizedString("windmill.aspects.ota.tooltip", comment: "")
            distributeArtefactView.isHidden = true
        }
    }
    
    lazy var artefactViews: [ArtefactType: ArtefactView] = { [unowned self] in
        return [.appBundle: self.buildArtefactView, .testReport: self.testArtefactView, .archiveBundle: self.archiveArtefactView, .ipaFile: self.exportArtefactView, .otaDistribution: self.distributeArtefactView]
        }()
    
    @IBOutlet weak var appView: AppView! {
        didSet {
            appView.toolTip = NSLocalizedString("windmill.artefacts.build.tooltip", comment: "")
        }
    }
    @IBOutlet weak var testReportView: TestReportView! {
        didSet {
            testReportView.toolTip = NSLocalizedString("windmill.reports.test.tooltip", comment: "")
        }
    }
    @IBOutlet weak var archiveView: ArchiveView! {
        didSet {
            archiveView.toolTip = NSLocalizedString("windmill.artefacts.archive.tooltip", comment: "")
        }
    }
    @IBOutlet weak var exportView: ExportView! {
        didSet {
            exportView.toolTip = NSLocalizedString("windmill.artefacts.ipa.tooltip", comment: "")
        }
    }
    @IBOutlet weak var distributeView: DistributeView! {
        didSet {
            distributeView.toolTip = NSLocalizedString("windmill.aspects.ota.tooltip", comment: "")
        }
    }
    
    lazy var views: [ArtefactType: NSView] = { [unowned self] in
        return [.appBundle: self.appView, .testReport: self.testReportView, .archiveBundle: self.archiveView, .ipaFile: self.exportView, .otaDistribution: self.distributeView]
        }()


    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("dd/MM/YYYY, HH:mm")
        
        return dateFormatter
    }()
    
    let defaultCenter = NotificationCenter.default
    
    weak var windmill: Windmill? {
        didSet{
            self.defaultCenter.addObserver(self, selector: #selector(willRun(_:)), name: Windmill.Notifications.willRun, object: windmill)
            self.defaultCenter.addObserver(self, selector: #selector(didCheckoutProject(_:)), name: Windmill.Notifications.didCheckoutProject, object: windmill)
            self.defaultCenter.addObserver(self, selector: #selector(activityDidLaunch(_:)), name: Windmill.Notifications.activityDidLaunch, object: windmill)
            self.defaultCenter.addObserver(self, selector: #selector(activityError(_:)), name: Windmill.Notifications.didError, object: windmill)
            self.defaultCenter.addObserver(self, selector: #selector(activityDidExitSuccesfully(_:)), name: Windmill.Notifications.activityDidExitSuccesfully, object: windmill)
            self.defaultCenter.addObserver(self, selector: #selector(didBuildProject(_:)), name: Windmill.Notifications.didBuildProject, object: windmill)
            self.defaultCenter.addObserver(self, selector: #selector(didTestProject(_:)), name: Windmill.Notifications.didTestProject, object: windmill)
            self.defaultCenter.addObserver(self, selector: #selector(didArchiveSuccesfully(_:)), name: Windmill.Notifications.didArchiveProject, object: windmill)
            self.defaultCenter.addObserver(self, selector: #selector(didExportProject(_:)), name: Windmill.Notifications.didExportProject, object: windmill)
            self.defaultCenter.addObserver(self, selector: #selector(didDistributeProject(_:)), name: Windmill.Notifications.didDistributeProject, object: windmill)
            
            self.windmill?.configuration.activities.forEach { activity in
                for artefact in activity.artefact() {
                    self.artefactViews[artefact]?.isHidden = false
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for view in self.views.values {
            view.isHidden = true
        }
    }

    @objc func willRun(_ aNotification: Notification) {
        
        self.windmill?.configuration.activities.forEach { activity in
            for artefact in activity.artefact() {
                self.artefactViews[artefact]?.isHidden = false
                self.artefactViews[artefact]?.stopStageAnimation()
            }
        }
        
        for view in self.views.values {
            view.isHidden = true
        }

        self.testReportView.openButton.isHidden = true
    }

    @objc func activityDidLaunch(_ aNotification: Notification) {
        if let artefact = aNotification.userInfo?["artefact"] as? ArtefactType {
            self.artefactViews[artefact]?.startStageAnimation()
        }
    }

    @objc func activityError(_ aNotification: Notification) {
        guard let activity = aNotification.userInfo?["activity"] as? ActivityType, let artefact = aNotification.userInfo?["artefact"] as? ArtefactType  else {
            return
        }
        
        self.artefactViews[artefact]?.stopStageAnimation()
        
        switch activity {
        case .test:
            if let testsFailedCount = aNotification.userInfo?["testsFailedCount"] as? Int {
                self.artefactViews[artefact]?.isHidden = true                
                self.testReportView.testReport = .failure(testsFailedCount: testsFailedCount)
                self.testReportView.isHidden = false
            }

            guard let testableSummaries = aNotification.userInfo?["testableSummaries"] as? [TestableSummary] else {
                return
            }
            
            self.testReportView.openButton.isHidden = testableSummaries.count == 0

        default:
            return
        }
    }
    
    @objc func activityDidExitSuccesfully(_ aNotification: Notification) {
        
        if let artefact = aNotification.userInfo?["artefact"] as? ArtefactType {
            self.artefactViews[artefact]?.stopStageAnimation()
            self.artefactViews[artefact]?.isHidden = true
        }
    }

    @objc func didCheckoutProject(_ aNotification: Notification) {
        
        guard let commit = aNotification.userInfo?["commit"] as? Repository.Commit else {
            os_log("Commit for project not found.", log: .default, type: .debug)
            return
        }

        self.appView.commit = commit
    }

    @objc func didBuildProject(_ aNotification: NSNotification) {
        
        guard let appBundle = aNotification.userInfo?["appBundle"] as? AppBundle else {
            return
        }
        
        self.appView.appBundle = appBundle
        self.appView.isHidden = false
    }
    
    @objc func didTestProject(_ aNotification: NSNotification) {
        
        if let testsCount = aNotification.userInfo?["testsCount"] as? Int {
            self.testReportView.testReport = .success(testsCount: testsCount)
            self.testReportView.isHidden = false
        }

        guard let testableSummaries = aNotification.userInfo?["testableSummaries"] as? [TestableSummary] else {
            return
        }

        self.testReportView.openButton.isHidden = testableSummaries.count == 0
    }
    
    @objc func didArchiveSuccesfully(_ aNotification: Notification) {
        
        guard let archive = aNotification.userInfo?["archive"] as? Archive else {
            return
        }
        
        let info = archive.info
        
        self.archiveView.titleTextField.stringValue = info.name
        self.archiveView.versionTextField.stringValue = "\(info.bundleShortVersion) (\(info.bundleVersion))"
        let creationDate = info.creationDate ?? Date()
        
        self.archiveView.dateTextField.stringValue = self.dateFormatter.string(from: creationDate)
        self.archiveView.archive = archive
        self.archiveView.isHidden = false
    }
    
    @objc func didExportProject(_ aNotification: Notification) {

        if let export = aNotification.userInfo?["export"] as? Export {
            self.exportView.export = export
        }
        
        if let appBundle = aNotification.userInfo?["appBundle"] as? AppBundle {
            self.exportView.appBundle = appBundle
        }
        
        self.exportView.isHidden = false
    }
    
    @objc func didDistributeProject(_ aNotification: Notification) {
        
        if let export = aNotification.userInfo?["export"] as? Export {
            self.distributeView.export = export
        }

        if let metadata = aNotification.userInfo?["metadata"] as? Export.Metadata {
            self.distributeView.metadata = metadata
        }

        if let appBundle = aNotification.userInfo?["appBundle"] as? AppBundle {
            self.distributeView.appBundle = appBundle
        }
        
        self.distributeView.isHidden = false
    }
}
