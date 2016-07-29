//
//  ShareViewController.swift
//  share
//
//  Created by Zhuhao Wang on 5/15/16.
//  Copyright © 2016 Zhuhao Wang. All rights reserved.
//

import Cocoa

class ShareViewController: NSViewController {

    override var nibName: String? {
        return "ShareViewController"
    }

    override func loadView() {
        super.loadView()
    
        // Insert code here to customize the view
        let item = self.extensionContext!.inputItems[0] as! NSExtensionItem
        if let attachments = item.attachments {
            NSLog("Attachments = %@", attachments as NSArray)
        } else {
            NSLog("No Attachments")
        }
    }

    @IBAction func send(sender: AnyObject?) {
        let outputItem = NSExtensionItem()
        // Complete implementation by setting the appropriate value on the output item
    
        let outputItems = [outputItem]
        self.extensionContext!.completeRequestReturningItems(outputItems, completionHandler: nil)
}

    @IBAction func cancel(sender: AnyObject?) {
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        self.extensionContext!.cancelRequestWithError(cancelError)
    }

}
