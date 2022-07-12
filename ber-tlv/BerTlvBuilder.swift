//
//  BerTlvBuilder.swift
//  ber-tlv
//
//  Created by Şükrü Can Avcı on 11.07.2022.
//  Copyright (c) 2022 Şükrü Can Avcı. All rights reserved.
//

import Foundation

class BerTlvBuilder: NSObject {
    
    var data: Data = Data.init()
    var templateTag: BerTag?
    
    override init() {
        super.init()
    }
    
    required init(tlv: BerTlv) {
        
        super.init()
        
        data = Data.init(capacity: 0xff)
        if tlv.primitive {
            _ = self.addBytes(buf: tlv.value!, tag: tlv.tag)
        } else {
            templateTag = tlv.tag
            for tlv in tlv.list! {
                _ = self.addBerTlv(tlv: tlv)
            }
        }
    }
    
    required init(tlvs: BerTlvs) {
        
        super.init()
        data = Data.init(capacity: 0xff)
        _ = self.addBerTlvs(tlvs: tlvs)
    }
    
    required init(tag: BerTag) {
        
        super.init()
        
        data = Data.init(capacity: 0xff)
        templateTag = tag
    }

    func buildData() -> Data? {
        
        // no template tag so can simply return data buffer
        if templateTag == nil {
            return data
        }

        // calculates bytes count for TYPE and LENGTH
        let typeBytesCount: Int = templateTag!.data.count
        let lengthBytesCount: Int = self.calcBytesCountForLength(length: data.count)
        if lengthBytesCount == 0 {
            return nil
        }
        
        var ret: Data = Data.init(capacity: typeBytesCount + lengthBytesCount + data.count)

        // TYPE
        ret.append((templateTag?.data!)!)

        // LENGTH
        let lengthData: Data? = self.createLengthData(length: data.count)
        if lengthData == nil {
            return nil
        }
        ret.append(lengthData!)

        // VALUE
        ret.append(data)

        return ret
    }

    func buildTlvs() -> BerTlvs? {
        
        let parser: BerTlvParser = BerTlvParser.init()
        let builtData: Data? = self.buildData()
        return builtData != nil ? parser.parseTlvs(builtData!) : nil
    }
    
    func buildTlv() -> BerTlv? {
        
        let parser: BerTlvParser = BerTlvParser.init()
        let builtData: Data? = self.buildData()
        return (builtData != nil) ? parser.parseConstructed(data: builtData!) : nil
    }
    
    func addBerTlv(tlv: BerTlv) -> Bool {
        
        // primitive
        if(tlv.primitive) {
            return self.addBytes(buf: tlv.value!, tag: tlv.tag)

        // constructed
        } else {
            let builder: BerTlvBuilder = BerTlvBuilder.init(tag: tlv.tag)
            for tlv in tlv.list! {
                _ = builder.addBerTlv(tlv: tlv)
            }
            let builtData: Data? = builder.buildData()
            if builtData != nil {
                data.append(builtData!)
                return true
            }
            return false
        }
    }
    
    func addBerTlvs(tlvs: BerTlvs) -> Bool {
        
        for tlv in tlvs.list {
            let success: Bool = self.addBerTlv(tlv: tlv)
            if (!success) {
                return false
            }
        }
        return true
    }
    
    func addAmount(amount: Decimal, tag: BerTag) -> Bool {
        
        let cents: Int = (amount as NSDecimalNumber).intValue * 100
        return self.addBcd(value: cents, tag: tag, length: 6)
    }
    
    func addDate(date: Date, tag: BerTag) {
        
        let dateFormatter: DateFormatter = DateFormatter.init()
        dateFormatter.dateFormat = "yyMMdd"
        let hex: String =  dateFormatter.string(from: date)
        _ = self.addHex(hex, tag: tag)
    }
    
    func addTime(time: Date, tag: BerTag) {
        
        let dateFormatter: DateFormatter = DateFormatter.init()
        dateFormatter.dateFormat = "HHmmss"
        let hex: String =  dateFormatter.string(from: time)
        _ = self.addHex(hex, tag: tag)
    }
    
    func addText(text: String, tag: BerTag) -> Bool {
        
        let buf: Data? = text.data(using: .ascii)
        return self.addBytes(buf: buf!, tag: tag)
    }
    
    func addBcd(value: Int, tag: BerTag, length: Int) -> Bool {
        
        var hex: String = String.init(format: "%@", value)
        for _ in 0..<100 {
            if !(hex.count<length*2) { break }
            hex.insert("0", at: hex.startIndex)
        }
        return self.addHex(hex, tag: tag)
    }
    
    func addBytes(buf: Data, tag: BerTag) -> Bool {
        
        let lenData: Data? = self.createLengthData(length: buf.count)
        if (lenData == nil) {
            return false
        }
        
        // TYPE
        data.append(tag.data)

        // LEN
        data.append(lenData!)

        // VALUE
        data.append(buf)
        return true
    }
    
    func addHex(_ hex: String, tag: BerTag) -> Bool {
        
        let buf: Data? = HexUtil.parse(hex)
        return self.addBytes(buf: buf!, tag: tag)
    }
    
    func calcBytesCountForLength(length: Int) -> Int {
        var ret: Int
        if(length < 0x80) {
            ret = 1;
        } else if length < 0x100 {
            ret = 2;
        } else if length < 0x10000 {
            ret = 3;
        } else if length < 0x1000000 {
            ret = 4;
        } else {
            ret = 0;
        }
        return ret
    }
    
    func createLengthData(length: Int) -> Data? {
        
        if length < 0x80 {
            var buf: [UInt8] = []
            buf.append(UInt8.init(length))
            return Data(bytes: buf, count: 1)

        } else if length < 0x100 {
            var buf: [UInt8] = []
            buf.append(0x81)
            buf.append(UInt8.init(length))
            return Data(bytes: buf, count: 2)

        } else if length < 0x10000 {
            var buf: [UInt8] = []
            buf.append(0x82)
            buf.append(UInt8.init(length / 0x100))
            buf.append(UInt8.init(length % 0x100))
            return Data(bytes: buf, count: 3)

        } else if length < 0x1000000 {
            var buf: [UInt8] = []
            buf.append(0x83)
            buf.append(UInt8.init(length / 0x10000))
            buf.append(UInt8.init(length / 0x100))
            buf.append(UInt8.init(length % 0x100))
            return Data(bytes: buf, count: 3)

        } else {
            NSLog("Length [%lu] is out of range ( > 0x1000000)", Double.init(length))
            return nil
        }
    }

    
}
