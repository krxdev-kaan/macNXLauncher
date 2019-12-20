//
//  ViewController.swift
//  macNXLauncher
//
//  Created by KRX Develops on 19.12.2019.
//  Copyright © 2019 KRX Develops. All rights reserved.
//

import Cocoa
import IOKit
import IOKit.usb
import IOKit.usb.IOUSBLib

class ViewController: NSViewController {
    @IBOutlet weak var fileDialogButton: NSButton!
    @IBOutlet weak var fileDirectoryTextField: NSTextField!
    @IBOutlet weak var rcmStateView: NSColorWell!
    
    var nxChecker : USBWatcher!
    var pathToFusee : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pathToFusee = UserDefaults.standard.string(forKey: "fuseeDir") ?? ""
        fileDirectoryTextField.stringValue = pathToFusee
        
        nxChecker = USBWatcher(delegate: self)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func browseFile(sender: AnyObject) {
        
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Locate and Choose FuseeGelee Folder";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.canChooseFiles = false;

        if (dialog.runModal() == NSApplication.ModalResponse.OK)
        {
            let result = dialog.url // Pathname of the file
            
            if (result != nil)
            {
                let path = result!.path
                fileDirectoryTextField.stringValue = path
                pathToFusee = path
                UserDefaults.standard.set(pathToFusee, forKey: "fuseeDir")
            }
        }
        else
        {
            // User clicked on "Cancel"
            return
        }
        
    }
}

extension ViewController: USBWatcherDelegate {
    
    func deviceAdded(_ device: io_object_t)
    {
        rcmStateView.color = NSColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0)
    }

    func deviceRemoved(_ device: io_object_t)
    {
        rcmStateView.color = NSColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 1.0)
    }
    
}
