//
//  USBDetector.swift
//  macNXLauncher
//
//  Created by KRX Develops on 21.12.2019.
//  Copyright © 2019 KRX Develops. All rights reserved.
//
//
// Just Wanted to give credits
// Thanks to Eric Aya !
// A great USB Device checking system !
// Slightly modified for Nintendo Switch
//

import Foundation
import IOKit
import IOKit.usb
import IOKit.usb.IOUSBLib

public protocol USBWatcherDelegate: class {
    func deviceAdded(_ device: io_object_t)

    func deviceRemoved(_ device: io_object_t)
}
public class USBWatcher {
    private weak var delegate: USBWatcherDelegate?
    private let notificationPort = IONotificationPortCreate(kIOMasterPortDefault)
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0

    public init(delegate: USBWatcherDelegate) {
        self.delegate = delegate

        func handleNotification(instance: UnsafeMutableRawPointer?, _ iterator: io_iterator_t) {
            let watcher = Unmanaged<USBWatcher>.fromOpaque(instance!).takeUnretainedValue()
            let handler: ((io_iterator_t) -> Void)?
            switch iterator {
            case watcher.addedIterator: handler = watcher.delegate?.deviceAdded
            case watcher.removedIterator: handler = watcher.delegate?.deviceRemoved
            default: assertionFailure("received unexpected IOIterator"); return
            }
            while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
                handler?(device)
                IOObjectRelease(device)
            }
        }

        let query = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary
        query[kUSBVendorID] = NSNumber(value: 0x0955)
        query[kUSBProductID] = NSNumber(value: 0x7321)
        let opaqueSelf = Unmanaged.passUnretained(self).toOpaque()

        // Watch for connected devices.
        IOServiceAddMatchingNotification(
            notificationPort, kIOMatchedNotification, query,
            handleNotification, opaqueSelf, &addedIterator)

        handleNotification(instance: opaqueSelf, addedIterator)

        // Watch for disconnected devices.
        IOServiceAddMatchingNotification(
            notificationPort, kIOTerminatedNotification, query,
            handleNotification, opaqueSelf, &removedIterator)

        handleNotification(instance: opaqueSelf, removedIterator)

        // Add the notification to the main run loop to receive future updates.
        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue(),
            .commonModes)
    }

    deinit {
        IOObjectRelease(addedIterator)
        IOObjectRelease(removedIterator)
        IONotificationPortDestroy(notificationPort)
    }
}
extension io_object_t {
    /// - Returns: The device's name.
    func name() -> String? {
        let buf = UnsafeMutablePointer<io_name_t>.allocate(capacity: 1)
        defer { buf.deallocate() }
        return buf.withMemoryRebound(to: CChar.self, capacity: MemoryLayout<io_name_t>.size) {
            if IORegistryEntryGetName(self, $0) == KERN_SUCCESS {
                return String(cString: $0)
            }
            return nil
        }
    }
}
