//
//  USBBackend.swift
//  macNXLauncher
//
//  Created by Kaan Uyumaz on 16.01.2022.
//  Copyright © 2022 Kaan Uyumaz. All rights reserved.
//

import Foundation
import USBDeviceSwift

public class USBBackend {
    static let nxVendorID: UInt16 = 0x0955
    static let nxProductId: UInt16 = 0x7321
    
    static var tegraDevice: USBDevice? = nil
    static let tegraMonitor = USBDeviceMonitor([USBMonitorData(vendorId: nxVendorID, productId: nxProductId)])
    
    static func initializeSwitchMonitor() {
        let tegraMonitorDaemon = Thread(target: tegraMonitor, selector: #selector(tegraMonitor.start), object: nil)
        tegraMonitorDaemon.start()
    }
}
