//
//  USBConstants.swift
//  macNXLauncher
//
//  Created by Kaan Uyumaz on 24.01.2022.
//  Copyright © 2022 Kaan Uyumaz. All rights reserved.
//

import Foundation

public let kIOUSBDeviceUserClientTypeID: CFUUID! = CFUUIDGetConstantUUIDWithBytes(
    nil,
    0x9d, 0xc7, 0xb7, 0x80, 0x9e,
    0xc0, 0x11, 0xD4, 0xa5, 0x4f,
    0x00, 0x0a, 0x27, 0x05, 0x28,
    0x61
)

public let kIOUSBDeviceInterfaceID: CFUUID! = CFUUIDGetConstantUUIDWithBytes(
    nil,
    0x5c, 0x81, 0x87, 0xd0, 0x9e,
    0xf3, 0x11, 0xD4, 0x8b, 0x45,
    0x00, 0x0a, 0x27, 0x05, 0x28,
    0x61
)

let kIOUSBInterfaceUserClientTypeID: CFUUID! =  CFUUIDGetConstantUUIDWithBytes(
    nil,
    0x2d, 0x97, 0x86, 0xc6, 0x9e,
    0xf3, 0x11, 0xD4, 0xad, 0x51,
    0x00, 0x0a, 0x27, 0x05, 0x28,
    0x61
)

let kIOUSBInterfaceInterfaceID: CFUUID! = CFUUIDGetConstantUUIDWithBytes(
    kCFAllocatorSystemDefault,
    0x87, 0x52, 0x66, 0x3B, 0xC0,
    0x7B, 0x4B, 0xAE, 0x95, 0x84,
    0x22, 0x03, 0x2F, 0xAB, 0x9C,
    0x5A
)

public let kIOCFPlugInInterfaceID: CFUUID! = CFUUIDGetConstantUUIDWithBytes(
    nil,
    0xC2, 0x44, 0xE8, 0x58, 0x10,
    0x9C, 0x11, 0xD4, 0x91, 0xD4,
    0x00, 0x50, 0xE4, 0xC6, 0x42,
    0x6F
)

public extension Notification.Name {
    static let TegraDeviceConnected = Notification.Name("TegraDeviceConnected")
    static let TegraDeviceDisconnected = Notification.Name("TegraDeviceDisconnected")
}