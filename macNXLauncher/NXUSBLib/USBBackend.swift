//
//  USBBackend.swift
//  macNXLauncher
//
//  Created by Kaan Uyumaz on 16.01.2022.
//  Copyright © 2022 Kaan Uyumaz. All rights reserved.
//

import Foundation

public class USBBackend {
    static let nxVendorID: UInt16 = 0x0955
    static let nxProductId: UInt16 = 0x7321
    
    static var tegraDeviceInterfacePtrPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOUSBDeviceInterface>?>? = nil
    static var tegraInterfaceInterfacePtrPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOUSBInterfaceInterface>?>? = nil
    static var tegraDeviceInterface: IOUSBDeviceInterface? = nil
    static var tegraInterfaceInterface: IOUSBInterfaceInterface? = nil
    
    static func initializeTegraMonitor() {
        var matchedIterator: io_iterator_t = 0
        var removalIterator: io_iterator_t = 0
        
        let notifyPort: IONotificationPortRef = IONotificationPortCreate(kIOMasterPortDefault)
        IONotificationPortSetDispatchQueue(notifyPort, DispatchQueue(label: "IODetector"))
        
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary
        matchingDict[kUSBVendorID] = NSNumber(value: nxVendorID)
        matchingDict[kUSBProductID] = NSNumber(value: nxProductId)

        let connectedCallback: IOServiceMatchingCallback = { (userData, iterator) in
            print("USBBackend: Connected Callback")
            USBBackend.deviceConnected(iterator: iterator)
        }
        
        let disconnectedCallback: IOServiceMatchingCallback = { (userData, iterator) in
            print("USBBackend: Disconnected Callback")
            USBBackend.deviceDisconnected(iterator: iterator)
        }
        
        IOServiceAddMatchingNotification(
            notifyPort,
            kIOFirstMatchNotification,
            matchingDict,
            connectedCallback,
            nil,
            &matchedIterator
        )
        
        IOServiceAddMatchingNotification(
            notifyPort,
            kIOTerminatedNotification,
            matchingDict,
            disconnectedCallback,
            nil,
            &removalIterator
        )
        
        self.deviceConnected(iterator: matchedIterator)
        self.deviceDisconnected(iterator: removalIterator)
        
        RunLoop.current.run()
    }
    
    static func deviceConnected(iterator: io_iterator_t) {
        print("USBBackend: Device Connected")
        while case let usbDevice: io_object_t = IOIteratorNext(iterator), usbDevice != 0 {
            print("USBBackend: Device Connect Loop. Iteration: \(usbDevice)")
            var score: Int32 = 0
            var kr: Int32 = 0
            var did: UInt64 = 0
            var vid: UInt16 = 0
            var pid: UInt16 = 0
            var plugInInterfacePtrPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?

            kr = IORegistryEntryGetRegistryEntryID(usbDevice, &did)
            if (!KernelSucceeded(kernelReturn: kr)) {
                print("USBBackend: DeviceID cannot be acquired.")
            }
            
            var deviceNameCString: [CChar] = [CChar](repeating: 0, count: 128)
            var name: String?
            kr = IORegistryEntryGetName(usbDevice, &deviceNameCString)
            if(!KernelSucceeded(kernelReturn: kr)) {
                print("USBBackend: Device Name cannot be acquired.")
            }
            name = String.init(cString: &deviceNameCString)
            print("USBBackend: Device called '\(name ?? "404")' acquired.")
            
            kr = IOCreatePlugInInterfaceForService(
                usbDevice,
                kIOUSBDeviceUserClientTypeID,
                kIOCFPlugInInterfaceID,
                &plugInInterfacePtrPtr,
                &score
            )
            if (!KernelSucceeded(kernelReturn: kr)) {
                print("USBBackend: Plug-In Interface Pointer cannot be acquired.")
                continue
            }
            
            IOObjectRelease(usbDevice)
            
            guard let plugInInterface = plugInInterfacePtrPtr?.pointee?.pointee else {
                print("USBBackend: Plug-In Interface cannot be acquired.")
                continue
            }
            kr = withUnsafeMutablePointer(to: &tegraDeviceInterfacePtrPtr) {
                $0.withMemoryRebound(to: Optional<LPVOID>.self, capacity: 1) {
                    plugInInterface.QueryInterface(
                        plugInInterfacePtrPtr,
                        CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                        $0
                    )
                }
            }
            if (!KernelSucceeded(kernelReturn: kr)) {
                print("USBBackend: Device Interface Pointer cannot be acquired.")
                continue
            }

            tegraDeviceInterface = tegraDeviceInterfacePtrPtr?.pointee?.pointee
            if (tegraDeviceInterface == nil) {
                print("USBBackend: Device Interface cannot be acquired.")
                continue
            }
            
            let rr: ULONG = plugInInterface.Release(plugInInterfacePtrPtr)
            if (rr != 1) {
                print("USBBackend: Unnecessary Plugin Interface failed to release. Error code: \(rr)")
            }
            
            kr = tegraDeviceInterface!.USBDeviceOpen(tegraDeviceInterfacePtrPtr)
            if (!KernelSucceededPlus(kernelReturn: kr)) {
                print("USBBackend: Device failed to open. Error code: \(kr)")
                continue
            }
            kr = tegraDeviceInterface!.GetDeviceVendor(tegraDeviceInterfacePtrPtr, &vid)
            if (!KernelSucceeded(kernelReturn: kr) || vid != nxVendorID) {
                print("USBBackend: Device VID check-up failed. Error code: \(kr)")
                continue
            }
            kr = tegraDeviceInterface!.GetDeviceProduct(tegraDeviceInterfacePtrPtr, &pid)
            if (!KernelSucceeded(kernelReturn: kr) || pid != nxProductId) {
                print("USBBackend: Device PID check-up failed. Error code: \(kr)")
                continue
            }
            
            NotificationCenter.default.post(
                name: .TegraDeviceConnected,
                object: []
            )
        }
    }
    
    static func deviceDisconnected(iterator: io_iterator_t) {
        print("USBBackend: Device Disconnected")
        while case let usbDevice: io_object_t = IOIteratorNext(iterator), usbDevice != 0 {
            print("USBBackend: Device Disconnect Loop. Iteration: \(usbDevice)")
            var kr: Int32 = 0
            var rr: ULONG = 0
            var did: UInt64 = 0
            
            kr = IORegistryEntryGetRegistryEntryID(usbDevice, &did)
            if(!KernelSucceeded(kernelReturn: kr)) {
                print("USBBackend: DeviceID cannot be acquired.")
            }
            
            kr = IOObjectRelease(usbDevice)
            if (!KernelSucceeded(kernelReturn: kr)) {
                print("USBBackend: USB Device failed to release. Error code: \(kr)")
                continue
            }
            
            if (tegraDeviceInterface != nil) {
                rr = tegraDeviceInterface!.Release(tegraDeviceInterfacePtrPtr)
                if (rr != 0) {
                    print("USBBackend: USB Device Interface failed to release. Error code: \(rr)")
                }
            }
            if (tegraInterfaceInterface != nil) {
                rr = tegraInterfaceInterface!.Release(tegraInterfaceInterfacePtrPtr)
                if (rr != 0) {
                    print("USBBackend: USB InterfaceInterface failed to release. Error code: \(rr)")
                }
            }
            tegraDeviceInterfacePtrPtr = nil
            tegraDeviceInterface = nil
            tegraInterfaceInterfacePtrPtr = nil
            tegraInterfaceInterface = nil
            
            NotificationCenter.default.post(
                name: .TegraDeviceDisconnected,
                object: []
            )
        }
    }
}
