//
//  TegraDevice.swift
//  macNXLauncher
//
//  Created by Kaan Uyumaz on 24.01.2022.
//  Copyright © 2022 Kaan Uyumaz. All rights reserved.
//

import Foundation
import IOKit
import IOKit.usb

public class TegraDevice {
    static var readPipeRef: UInt8 = 0
    static var writePipeRef: UInt8 = 0
    
    static func getTegraReadWriteEndpoints () {
        var kr: Int32 = 0
        var numEndpoints: UInt8 = 0
        
        kr = USBBackend.tegraInterfaceInterface!.GetNumEndpoints(USBBackend.tegraInterfaceInterfacePtrPtr, &numEndpoints)
        if (kr == kIOReturnSuccess) {
            for pipeRef in 1...numEndpoints {
                var direction: UInt8 = 0
                var num: UInt8 = 0
                var transferType: UInt8 = 0
                var maxPacketSize: UInt16 = 0
                var interval: UInt8 = 0
                
                kr = USBBackend.tegraInterfaceInterface!.GetPipeProperties(
                    USBBackend.tegraInterfaceInterfacePtrPtr,
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
    }
}
