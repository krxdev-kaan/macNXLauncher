//
//  ViewController.swift
//  macNXLauncher
//
//  Created by KRX Develops on 19.12.2019.
//  Copyright © 2019 KRX Develops. All rights reserved.
//

import Cocoa
import USBDeviceSwift
import IOKit
import IOKit.usb

class ViewController: NSViewController {
    @IBOutlet weak var fileDialogButton: NSButton!
    @IBOutlet weak var fileDirectoryTextField: NSTextField!
    @IBOutlet weak var rcmStateView: NSColorWell!
    @IBOutlet weak var payloadListHeader: NSTableHeaderView!
    @IBOutlet weak var payloadListView: NSTableView!
    
    var pathToFusee : String!
    var selectedPayload = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pathToFusee = UserDefaults.standard.string(forKey: "fuseeDir") ?? ""
        fileDirectoryTextField.stringValue = pathToFusee
        
        setupPayloadList()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.devicePluggedIn), name: .TegraDeviceConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceRemoved), name: .TegraDeviceDisconnected, object: nil)
    }
    
    func setupPayloadList()
    {
        payloadListView.delegate = self
        payloadListView.dataSource = self
    }
    
    @objc func devicePluggedIn(notification: NSNotification)
    {
        DispatchQueue.main.async {
            self.rcmStateView.color = NSColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0)
        }
    }

    @objc func deviceRemoved(notification: NSNotification)
    {
        DispatchQueue.main.async {
            self.rcmStateView.color = NSColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 1.0)
        }
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
        USBDevice.claimInterface(interfaceNum: 0)
        TegraDevice.getTegraReadWriteEndpoints()
        
        let (didSucceedR, deviceId): (Bool, [UInt8]) = TegraDevice.readDeviceId()
        if (!didSucceedR) {
            print("ERROR: Failed to read DeviceID.")
            return
        }
        print("Device ID acquired: \(deviceId)")
        
        let payload: Payload = SaveSystem.retrieveAtIndex(index: selectedPayload)
        let (didSucceedP, payloadData): (Bool, [UInt8]) = NXPayload.createPayloadData(payload: payload)
        if (!didSucceedP) {
            print("ERROR: failed to create payload.")
            return
        }
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
