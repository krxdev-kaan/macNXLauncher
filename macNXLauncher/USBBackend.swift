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
    
    static var switchDevice: USBDevice? = nil
    static let switchMonitor = USBDeviceMonitor([USBMonitorData(vendorId: nxVendorID, productId: nxProductId)])
    
    static func initializeSwitchMonitor() {
        let switchMonitorDaemon = Thread(target: switchMonitor, selector: #selector(switchMonitor.start), object: nil)
        switchMonitorDaemon.start()
    }
}
