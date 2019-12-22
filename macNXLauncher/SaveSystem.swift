//
//  SaveSystem.swift
//  macNXLauncher
//
//  Created by KRX Develops on 21.12.2019.
//  Copyright © 2019 KRX Develops. All rights reserved.
//

import Foundation

class SaveSystem
{
    static var saveInstance : [Payload]?
    
    static func retrieveAndUpdate() -> [Payload] {
        var arr : [Payload]
        let data = UserDefaults.standard.value(forKey:"payloads") as? Data
        if data != nil
        {
            let pins = try? PropertyListDecoder().decode(Array<Payload>.self, from: data!)
            arr = pins ?? [Payload]()
        }
        else
        {
            arr = [Payload]()
        }
        saveInstance = arr
        return arr
    }
    
    static func retrieveAtIndex(index: Int) -> Payload
    {
        let saveArr = retrieveAndUpdate()
        return saveArr[index]
    }
    
    static func push(el: Payload)
    {
        var saveArr = retrieveAndUpdate()
        saveArr.append(el)
        UserDefaults.standard.set(try? PropertyListEncoder().encode(saveArr), forKey:"payloads")
    }
    
    static func pushSave(arr: [Payload])
    {
        UserDefaults.standard.set(try? PropertyListEncoder().encode(arr), forKey:"payloads")
    }
}
