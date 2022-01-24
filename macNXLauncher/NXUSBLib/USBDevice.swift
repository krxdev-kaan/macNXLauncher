//
//  USBDevice.swift
//  macNXLauncher
//
//  Created by Kaan Uyumaz on 24.01.2022.
//  Copyright © 2022 Kaan Uyumaz. All rights reserved.
//

import Foundation
import IOKit
import IOKit.usb

public class USBDevice {
    static func claimInterface (interfaceNum: Int32) {
        var kr: Int32 = 0
        var interfaceService: io_service_t = 0
        var subInterface: io_iterator_t = 0
        var subInterfaceReq: IOUSBFindInterfaceRequest = IOUSBFindInterfaceRequest(
            bInterfaceClass: UInt16(kIOUSBFindInterfaceDontCare),
            bInterfaceSubClass: UInt16(kIOUSBFindInterfaceDontCare),
            bInterfaceProtocol: UInt16(kIOUSBFindInterfaceDontCare),
            bAlternateSetting: UInt16(kIOUSBFindInterfaceDontCare)
        )
        
        kr = USBBackend.tegraDeviceInterface!.CreateInterfaceIterator(
            USBBackend.tegraDeviceInterfacePtrPtr,
            &subInterfaceReq,
            &subInterface
        )
        interfaceService = IOIteratorNext(subInterface)
        while(interfaceService != 0) {
            let interfaceReferance: Unmanaged<CFTypeRef>! = IORegistryEntryCreateCFProperty(
                interfaceService,
                "bInterfaceNumber" as CFString,
                kCFAllocatorDefault,
                0
            )
            
            if ((interfaceReferance.takeUnretainedValue() as! NSNumber).int32Value == 0) {
                break
            }
            
            IOObjectRelease(interfaceService)
            interfaceService = IOIteratorNext(subInterface)
        }
        
        var score: Int32 = 0
        var pluginInterfacePtrPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?
        kr = IOCreatePlugInInterfaceForService(
            interfaceService,
            kIOUSBInterfaceUserClientTypeID,
            kIOCFPlugInInterfaceID,
            &pluginInterfacePtrPtr,
            &score
        )
        guard let plugInInterface = pluginInterfacePtrPtr?.pointee?.pointee else {
            print("USBDevice: Failed to create Plugin Interface for InterfaceInterface.")
            return
        }
        
        kr = withUnsafeMutablePointer(to: &USBBackend.tegraInterfaceInterfacePtrPtr) {
           $0.withMemoryRebound(to: Optional<LPVOID>.self, capacity: 1) {
               plugInInterface.QueryInterface(
                   pluginInterfacePtrPtr,
                   CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
                   $0
               )
           }
        }
        
        var rr: ULONG = 0
        rr = plugInInterface.Release(pluginInterfacePtrPtr)
        if (rr != 1) {
            print("USBDevice: Unnecessary Plugin Interface failed to release. Error code: \(rr)")
        }
        
        USBBackend.tegraInterfaceInterface = USBBackend.tegraInterfaceInterfacePtrPtr?.pointee?.pointee
        if (USBBackend.tegraInterfaceInterface == nil) {
            print("USBDevice: InterfaceInterface cannot be acquired.")
            return
        }
        
        kr = USBBackend.tegraInterfaceInterface!.USBInterfaceOpen(USBBackend.tegraInterfaceInterfacePtrPtr)
        if (!KernelSucceeded(kernelReturn: kr)) {
            print("USBDevice: InterfaceInterface failed to open. Error code: \(kr)")
            return
        }
    }
}
