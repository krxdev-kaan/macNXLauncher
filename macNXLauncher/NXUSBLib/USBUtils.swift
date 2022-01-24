//
//  USBUtils.swift
//  macNXLauncher
//
//  Created by Kaan Uyumaz on 24.01.2022.
//  Copyright © 2022 Kaan Uyumaz. All rights reserved.
//

import Foundation
import IOKit

func KernelSucceeded(kernelReturn: kern_return_t) -> Bool {
    return kernelReturn == kIOReturnSuccess
}

func KernelSucceededPlus(kernelReturn: kern_return_t) -> Bool {
    return kernelReturn == kIOReturnSuccess || kernelReturn == kIOReturnExclusiveAccess
}
