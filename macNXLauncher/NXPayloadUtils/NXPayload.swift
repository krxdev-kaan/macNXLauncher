//
//  NXPayload.swift
//  macNXLauncher
//
//  Created by Kaan Uyumaz on 26.01.2022.
//  Copyright © 2022 Kaan Uyumaz. All rights reserved.
//

import Foundation

public class NXPayload {
    static let RCM_PAYLOAD_ADDR: Int32 = 0x40010000
    static let PAYLOAD_START_ADDR: Int32 = 0x40010E40
    static let STACK_SPRAY_START: Int32 = 0x40014E40
    static let STACK_SPRAY_END: Int32 = 0x40017000
    
    static let maxRCMLength: Int = 0x30298
    
    static func createPayloadData (payload: Payload) -> (Bool, [UInt8]) {
        if (payload.directory == nil) {
            print("NXPayload: Payload not selected.")
            return (false, [])
        }
        
        var payloadBytes = [UInt8]()
        if let data = NSData(contentsOfFile: payload.directory!) {
            var buffer = [UInt8](repeating: 0, count: data.length)
            data.getBytes(&buffer, length: data.length)
            payloadBytes = buffer
        }
        
        var payload: [UInt8] = withUnsafeBytes(of: maxRCMLength.littleEndian, Array.init)
        for _ in 0..<(680 - payload.count) {
            payload.append(0x00)
        }
        payload.append(contentsOf: Intermezzo.intermezzoBytes)
        
        var padding: Int32 = PAYLOAD_START_ADDR - (RCM_PAYLOAD_ADDR + Int32(Intermezzo.intermezzoBytes.count))
        for _ in 0..<padding {
            payload.append(0x00)
        }
        
        padding = STACK_SPRAY_START - PAYLOAD_START_ADDR
        payload.append(contentsOf: payloadBytes[0..<Int(padding)])
        
        let sprayCount: Int = Int((STACK_SPRAY_END - STACK_SPRAY_START) / 4)
        for _ in 0..<sprayCount {
            payload.append(contentsOf: withUnsafeBytes(of: RCM_PAYLOAD_ADDR.littleEndian, Array.init))
        }
        
        payload.append(contentsOf: payloadBytes[Int(padding)..<payloadBytes.count])
        
        let payloadLength: Int32 = Int32(payload.count)
        padding = 0x1000 - (payloadLength % 0x1000)
        for _ in 0..<padding {
            payload.append(0x00)
        }
        
        if (payload.count > maxRCMLength) {
            print("NXPayload: Payload is larger than maximum RCM payload length.")
            return (false, [])
        }
        
        return (true, payload)
    }
}
