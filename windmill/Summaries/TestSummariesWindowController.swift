//
//  TestSummariesWindowController.swift
//  windmill
//
//  Created by Markos Charatzas (markos@qnoid.com) on 23/3/18.
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

class TestSummariesWindowController: NSWindowController, TestSummariesViewControllerDelegate {

    static func make(testableSummaries: [TestableSummary]) -> TestSummariesWindowController? {
        
        let testSummariesStoryboard = NSStoryboard.Windmill.testSummariesStoryboard()
        
        let testSummariesWindowController = testSummariesStoryboard.instantiateInitialController() as? TestSummariesWindowController
        let testSummariesViewController = testSummariesWindowController?.testSummariesViewController
        testSummariesViewController?.delegate = testSummariesWindowController
        testSummariesViewController?.testableSummaries = testableSummaries
        
        return testSummariesWindowController
    }
    
    lazy var splitViewController = self.contentViewController as? NSSplitViewController
    
    lazy var testSummariesViewController: TestSummariesViewController? = {
        guard let splitViewController = splitViewController else {
            return nil
        }
        
        return splitViewController.children[0] as? TestSummariesViewController
    }()
    
    lazy var summaryViewController: SummaryViewController? = {
        guard let splitViewController = splitViewController else {
            return nil
        }
        
        return splitViewController.children[1] as? SummaryViewController
    }()
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = self.window else {
            return
        }
        
        window.collectionBehavior = [window.collectionBehavior, NSWindow.CollectionBehavior.fullScreenAllowsTiling]
    }
    
    func toggleSummaryPane(isCollapsed: Bool? = nil, completionHandler: (() -> Swift.Void)? = nil) {
        
        NSAnimationContext.runAnimationGroup({ [summarySplitViewItem  = self.splitViewController?.splitViewItem(for: self.summaryViewController!)]_ in
            summarySplitViewItem?.animator().isCollapsed = isCollapsed ?? !summarySplitViewItem!.isCollapsed
            }, completionHandler: completionHandler)
    }
    
    func didSelect(_ testSummariesViewController: TestSummariesViewController, test: Test) {
        self.toggleSummaryPane(isCollapsed: false) {
            self.summaryViewController?.summary = test.failureSummaries.first
        }
    }
}
