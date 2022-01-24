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
        /*
            guard let deviceInterface = USBBackend.tegraDevice!.deviceInterfacePtrPtr?.pointee?.pointee else {
                return
            }
            
            var kr : Int32 = 0
            var intfService: io_service_t = 0
            var subIntf: io_iterator_t = 0
            var subIntfReq: IOUSBFindInterfaceRequest = IOUSBFindInterfaceRequest(
                bInterfaceClass: UInt16(kIOUSBFindInterfaceDontCare),
                bInterfaceSubClass: UInt16(kIOUSBFindInterfaceDontCare),
                bInterfaceProtocol: UInt16(kIOUSBFindInterfaceDontCare),
                bAlternateSetting: UInt16(kIOUSBFindInterfaceDontCare)
            )
            kr = deviceInterface.CreateInterfaceIterator(USBBackend.tegraDevice!.deviceInterfacePtrPtr, &subIntfReq, &subIntf)
            intfService = IOIteratorNext(subIntf)
            while(intfService != 0) {
                let intfnum: Unmanaged<CFTypeRef>! = IORegistryEntryCreateCFProperty(intfService, "bInterfaceNumber" as CFString, kCFAllocatorDefault, 0)
                
                if ((intfnum.takeUnretainedValue() as! NSNumber).int32Value == 0) {
                    break
                }
                
                IOObjectRelease(intfService)
                intfService = IOIteratorNext(subIntf)
            }
            
            var plugin: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?
            var interface: UnsafeMutablePointer<UnsafeMutablePointer<IOUSBInterfaceInterface>?>?
            var score: Int32 = 0
            var vid:UInt16 = 0
            var pid:UInt16 = 0
            
            let kIOUSBInterfaceUserClientTypeID: CFUUID! =  CFUUIDGetConstantUUIDWithBytes(
                nil,
                0x2d, 0x97, 0x86, 0xc6, 0x9e,
                0xf3, 0x11, 0xD4, 0xad, 0x51,
                0x00, 0x0a, 0x27, 0x05, 0x28,
                0x61
            )
            
            kr = IOCreatePlugInInterfaceForService(
                intfService,
                kIOUSBInterfaceUserClientTypeID,
                kIOCFPlugInInterfaceID,
                &plugin,
                &score
            )
            
            guard let plugInInterface = plugin?.pointee?.pointee else {
                print("Unable to get Plug-In Interface")
                return
            }
            
            let kIOUSBInterfaceInterfaceID: CFUUID! = CFUUIDGetConstantUUIDWithBytes(
                kCFAllocatorSystemDefault,
                0x87, 0x52, 0x66, 0x3B, 0xC0,
                0x7B, 0x4B, 0xAE, 0x95, 0x84,
                0x22, 0x03, 0x2F, 0xAB, 0x9C,
                0x5A
            )
            
            kr = withUnsafeMutablePointer(to: &interface) {
               $0.withMemoryRebound(to: Optional<LPVOID>.self, capacity: 1) {
                   plugInInterface.QueryInterface(
                       plugin,
                       CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
                       $0)
               }
            }
            
            plugInInterface.Release(plugin)
            
            guard let interfaceZero = interface?.pointee?.pointee else {
                print("Unable to get Device Interface")
                return
            }
            
            kr = interfaceZero.USBInterfaceOpen(interface)
            
            kr = interfaceZero.GetDeviceVendor(interface, &vid)
            if (kr != kIOReturnSuccess) {
                print("Unable to get Device PID")
                return
            }
            
            kr = interfaceZero.GetDeviceProduct(interface, &pid)
            if (kr != kIOReturnSuccess) {
                print("Unable to get Device VID")
                return
            }
            
            var readPipeRef: UInt8 = 0
            var writePipeRef: UInt8 = 0
            
            var numEndpoints: UInt8 = 0
            
            kr = interfaceZero.GetNumEndpoints(interface, &numEndpoints)
            if (kr == kIOReturnSuccess) {
                for pipeRef in 1...numEndpoints {
                    var direction: UInt8 = 0
                    var num: UInt8 = 0
                    var transferType: UInt8 = 0
                    var maxPacketSize: UInt16 = 0
                    var interval: UInt8 = 0
                    
                    kr = interfaceZero.GetPipeProperties(
                        interface,
                        pipeRef,
                        &direction,
                        &num,
                        &transferType,
                        &maxPacketSize,
                        &interval
                    )
                    
                    if (kr == kIOReturnSuccess) {
                        if (readPipeRef == 0 && transferType == kUSBBulk && direction == kUSBIn) {
                            readPipeRef = pipeRef
                        }
                        if (writePipeRef == 0 && transferType == kUSBBulk && direction == kUSBOut) {
                            writePipeRef = pipeRef
                        }
                    }
                }
            }
            
            var buffer: [UInt8] = [UInt8](repeating: 0, count: 16)
            var length: UInt32 = UInt32(buffer.count)
            
            kr = interfaceZero.ReadPipe(
                interface,
                readPipeRef,
                &buffer,
                &length
            )
            if (kr == kIOReturnSuccess) {
                print(buffer)
            } else {
                print("Error while reading device id")
            }
            
            kr = interfaceZero.USBInterfaceClose(interface)
            interfaceZero.Release(interface)
        */
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
