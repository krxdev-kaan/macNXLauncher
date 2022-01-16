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
    @IBOutlet weak var payloadListHeader: NSTableHeaderView!
    @IBOutlet weak var payloadListView: NSTableView!
    
    var nxChecker : USBWatcher!
    var pathToFusee : String!
    
    var selectedPayload = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pathToFusee = UserDefaults.standard.string(forKey: "fuseeDir") ?? ""
        fileDirectoryTextField.stringValue = pathToFusee
        
        nxChecker = USBWatcher(delegate: self)
        
        setupPayloadList()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func setupPayloadList()
    {
        payloadListView.delegate = self
        payloadListView.dataSource = self
    }
    
    @IBAction func browseForFusee(sender: AnyObject) {
        
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
            let result = dialog.url
            
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
            return
        }
        
    }
    
    @IBAction func browseForPayload(sender: AnyObject) {
        
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Locate and Choose a Payload";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.canChooseFiles = true;
        dialog.allowedFileTypes = ["bin"]

        if (dialog.runModal() == NSApplication.ModalResponse.OK)
        {
            let result = dialog.url
            
            if (result != nil)
            {
                let path = result!.path
                let name = result!.lastPathComponent
                
                let payload = Payload(directory: path, name: name)
                SaveSystem.push(el: payload)
                payloadListView.reloadData()
            }
        }
        else
        {
            return
        }
        
    }
    
    @IBAction func smashPayload(sender: AnyObject)
    {
        let payload = SaveSystem.retrieveAtIndex(index: selectedPayload)
        if payload.directory == nil
        {
            print("sector1")
            return
        }
        if selectedPayload == -1
        {
            print("sector2")
            return
        }
        let fm = FileManager.default
        if !fm.fileExists(atPath: payload.directory!)
        {
            print("sector3")
            return
        }
        if !fm.fileExists(atPath: pathToFusee + "/intermezzo.bin")
        {
            print("sector4")
            return
        }
        if !fm.fileExists(atPath: pathToFusee + "/fusee-launcher.py")
        {
            print("sector5")
            return
        }
        if !fm.fileExists(atPath: pathToFusee + "/libusbK.py")
        {
            print("sector6")
            return
        }
        
        print("passed all possible errors")
        
        let process = Process()
        process.launchPath = "/usr/bin/python3"
        process.currentDirectoryPath = pathToFusee
        process.arguments = ["fusee-launcher.py", "--smash_payload", payload.directory!]
        process.terminationHandler = { (process) in
            print(process.terminationStatus)
        }
        process.launch()
    }
}

extension ViewController: NSTableViewDelegate
{
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let payload = SaveSystem.retrieveAtIndex(index: row)
        
        var image : NSImage!
        var text : String!
        let cellIdentifier : String = "payloadCell"
        
        let fm = FileManager.default
        if fm.fileExists(atPath: payload.directory!)
        {
            image = NSImage(named: "NSStatusAvailable")
            text = payload.name
        }
        else
        {
            image = NSImage(named: "NSStatusUnavailable")
            text = payload.name
        }

        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
              cell.textField?.stringValue = text
              cell.imageView?.image = image ?? nil
              return cell
        }
        
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        selectedPayload = payloadListView.selectedRow
    }
    
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        
        if edge == .trailing
        {
            let action = NSTableViewRowAction(style: .destructive, title: "Remove Payload", handler:
            { _, _ in
                var arr = SaveSystem.retrieveAndUpdate()
                arr.remove(at: row)
                SaveSystem.pushSave(arr: arr)
                self.payloadListView.reloadData()
            })
            action.backgroundColor = .red
            return [action]
        }
        
        return []
    }
}

extension ViewController: NSTableViewDataSource
{
    func numberOfRows(in tableView: NSTableView) -> Int {
        let arr = SaveSystem.retrieveAndUpdate()
        return arr.count
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        let payload = SaveSystem.retrieveAtIndex(index: row)
        
        let fm = FileManager.default
        if fm.fileExists(atPath: payload.directory!)
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
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
