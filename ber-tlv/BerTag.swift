//
//  BerTag.swift
//  ber-tlv
//
//  Created by Şükrü Can Avcı on 11.07.2022.
//  Copyright (c) 2022 Şükrü Can Avcı. All rights reserved.
//

import Foundation

public class BerTag: NSObject {
    
    var data: Data!
    
    required init(data: Data, offset: Int, length: Int) {
        
        super.init()

        if (offset + length <= data.count) {
            let range = Range(NSMakeRange(offset, length))
            self.data = data.subdata(in: range!)
        }
    }
    
    required init(firstByte: UInt8) {
        
        super.init()

        data = Data(bytes: [firstByte] as [UInt8], count: 1)
    }
    
    required init(firstByte: UInt8, secondByte: UInt8) {
        
        super.init()

        var bytes: [UInt8] = []
        bytes[0] = firstByte;
        bytes[1] = secondByte;
        data = Data(bytes: bytes, count: 2)
    }
    
    required init(firstByte: UInt8, secondByte: UInt8, thirdByte: UInt8) {
        
        super.init()

        var bytes: [UInt8] = []
        bytes[0] = firstByte;
        bytes[1] = secondByte;
        bytes[2] = thirdByte;
        data = Data(bytes: bytes, count: 3)
    }
    
    func isConstructed() -> Bool {

        let bytes: [UInt8] = data.copyBytes(as: UInt8.self)
        return (bytes[0] & 0x20) != 0
    }
    
    func isEqual(other: NSObject?) -> Bool {
        
        if let object = other {
            return self == object
        }

        return self.isEqualToTag(tag: other as? BerTag);
    }

    func isEqualToTag(tag: BerTag?) -> Bool {
        
        if (self == tag) {
            return true
        }

        if (tag == nil) {
            return false
        }

        return (data == tag?.data)
    }
    
    func hash() -> Int {
        
        return data.hashValue
    }
    
    func description() -> String {
        
        var description: String = String.init()
        if(self.isConstructed()) {
            description.append("+ ")
        } else {
            description.append("- ")
        }
        description = description.appendingFormat("%@", [HexUtil.format(data)])
        
        return description
    }
    
    func hex() -> String {
        
        return HexUtil.format(data)
    }
    
    static func parse(_ hexString: String) -> BerTag {
        
        let data: Data = HexUtil.parse(hexString)
        return BerTag.init(data: data, offset: 0, length: data.count)
    }
    
    
}

extension Data {
    func copyBytes<T>(as _: T.Type) -> [T] {
        return withUnsafeBytes { (bytes: UnsafePointer<T>) in
            Array(UnsafeBufferPointer(start: bytes, count: count / MemoryLayout<T>.stride))
        }
    }
}
