//
//  HexUtil.swift
//  ber-tlv
//
//  Created by Şükrü Can Avcı on 11.07.2022.
//  Copyright (c) 2022 Şükrü Can Avcı. All rights reserved.
//

import Foundation

let HEX_BYTES: [UInt8] = [
       // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
         99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99
/* 0 */, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99
/* 1 */, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99
/* 2 */,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 99, 99, 99, 99, 99, 99
/* 3 */, 99, 10, 11, 12, 13, 14, 15, 99, 99, 99, 99, 99, 99, 99, 99, 99
/* 4 */, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99
/* 5 */, 99, 10, 11, 12, 13, 14, 15, 99, 99, 99, 99, 99, 99, 99, 99, 99
/* 6 */, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99
]

let HEX_BYTES_LEN: UInt8 = 128
let HEX_BYTE_SKIP: UInt8 = 99

class HexUtil: NSObject {
    
    static func format(_ data: Data) -> String {
        
        var sb: String = String.init()
        let bytes: [UInt8] = data.copyBytes(as: UInt8.self)
        for i in 0..<data.count {
            let b: UInt8 = bytes[i];
            let st = String(NSString(format:"%2X", b))
            sb += st
        }

        return sb
    }
    
    static func prettyFormat(_ data: Data) -> String {
        
        return HexUtil.format(data: data, offset: 0, len: data.count)
    }
    
    static func parse(_ hex: String) -> Data {
        
        let text = hex.cString(using: .ascii)
        let len = strlen(text!)// returns a UInt

        var high: UInt8 = 0
        var highPassed: Bool = false

        var data: Data = Data.init()

        for i in 0..<len {
            let index: Int = Int(text![i])

            // checks if value out of 127 (ASCII must contains from 0 to 127)
            if index >= HEX_BYTES_LEN {
                continue
            }

            let nibble: UInt8 = HEX_BYTES[index]

            // checks if not HEX chars
            if(nibble == HEX_BYTE_SKIP) {
                continue
            }

            if highPassed {
                // fills right nibble, creates byte and adds it
                let low: UInt8 = (UInt8)(nibble & 0x7f)
                highPassed = false
                let currentByte: UInt8 = ((high << 4) + low)
                data.append(data:  Data([currentByte]), offset: 0, size: 1)
            } else {
                // fills left nibble
                high = (UInt8)(nibble & 0x7f);
                highPassed = true
            }
        }
        //TODO: error
        
        return data
    }
    
    static func format(data: Data, offset: Int, len: Int) -> String {
        
        var sb: String = String.init() //initWithCapacity:aData.length*2];
        let bytes: [UInt8] = data.copyBytes(as: UInt8.self)
        let max: Int = offset + len
        if max <= data.count {
            for i in offset..<max {
                let b: UInt8 = bytes[i]
                sb = sb.appendingFormat("%02X", b)
            }
        }
        return sb
    }
}

extension Data {
    mutating func append(data: Data, offset: Int, size: Int) {
        // guard offset and size are valid ...
        data.withUnsafeBytes { buf in
            self.append(buf.bindMemory(to: UInt8.self).baseAddress!.advanced(by: offset), count: size)
        }
    }
}
