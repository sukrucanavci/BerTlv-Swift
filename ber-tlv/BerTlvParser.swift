//
//  BerTlvParser.swift
//  ber-tlv
//
//  Created by Şükrü Can Avcı on 11.07.2022.
//  Copyright (c) 2022 Şükrü Can Avcı. All rights reserved.
//

import Foundation

class BerTlvParser: NSObject {
    
    static var IS_DEBUG_ENABLED: Bool = false
    var outResult = 0
    
    func parseConstructed(data: Data) -> BerTlv? {
        
       outResult = 0
        let ret: BerTlv = self.parseWithResult(buf: data, offset: 0, len: data.count, level: 0)
        return ret
    }
    
    func parseTlvs(_ data: Data) -> BerTlvs {
        
        return self.parseTlvs(data, numberOfTags: 100)
    }
    
    func parseTlvs(_ data: Data, numberOfTags: Int) -> BerTlvs {
        
        if data.count == 0 {

            return BerTlvs.init(list: [])
        }
        
        var list = Array<BerTlv>.init()
        var offset = 0

        for _ in 0..<numberOfTags {
            outResult = 0
            let ret: BerTlv? = self.parseWithResult(buf: data, offset: offset, len: (data.count-offset), level:0)
            
            if (ret != nil) {
                list.append(ret!)
            } else {
                break
            }

            if outResult >= data.count {
                break
            }

            offset = outResult
        }
        //TODO: error
        
        return BerTlvs.init(list: list)
    }
    
    func parseWithResult(buf: Data, offset: Int, len: Int, level: Int) -> BerTlv {
        
        let levelPadding: String =  self.createLevelPadding(level: level)
        if BerTlvParser.IS_DEBUG_ENABLED {
            NSLog("%@parseWithResult( level=%d, offset=%d, len=%d, buf=%@)", levelPadding, level, offset, len, HexUtil.format(buf))
        }
        
        // TAG
        //TODO: change this
//        let tagBytesCount: Int = self.calcTagBytesCount(buf, offset: offset)
        let tagBytesCount: Int = 2
        let tag: BerTag = self.createTag(buf: buf, offset: offset, len: tagBytesCount, levelPadding: levelPadding) //0x0000000280d25500
        
        // LENGTH
        let lengthBytesCount: Int = self.calcLengthBytesCount(buf: buf, offset: offset + tagBytesCount) //1
        let valueLength: Int = self.calcDataLength(buf: buf, offset: offset + tagBytesCount)
        //TODO: error
        
        if BerTlvParser.IS_DEBUG_ENABLED {
            NSLog("%@lenBytesCount = %d, len = %d, lenBuf = %@", levelPadding, lengthBytesCount, valueLength, HexUtil.format(data: buf, offset: offset + tagBytesCount, len: lengthBytesCount))
        }
        
        // VALUE
        if(tag.isConstructed()) {
            let array: Array = Array<BerTlv>.init()
            self.addChildren(buf: buf, offset: offset, level: level, levelPadding: levelPadding, tagBytesCount: tagBytesCount, dataBytesCount: lengthBytesCount, valueLength: valueLength, array: array)

            //TODO: error
            let resultOffset: Int = offset + tagBytesCount + lengthBytesCount + valueLength
            if BerTlvParser.IS_DEBUG_ENABLED {
                NSLog("%@Returning constructed offset = %d", levelPadding, resultOffset)
            }
            outResult = resultOffset
            return BerTlv.init(tag, array)
        } else {

            let range2 = NSMakeRange((offset + tagBytesCount + lengthBytesCount), valueLength)
            let range = Range(range2)

            let resultOffset: Int = offset + tagBytesCount + lengthBytesCount + valueLength //4
            outResult = resultOffset

            //TODO: error
            let value: Data = buf.subdata(in: range!)
            
            if BerTlvParser.IS_DEBUG_ENABLED {
                NSLog("%@Primitive value = %@", levelPadding, HexUtil.format(value))
                NSLog("%@Returning primitive offset = %d", levelPadding, resultOffset)
            }
            return BerTlv.init(tag, value)
        }
        
        
        
    }
    
    func calcTagBytesCount(buf: Data, offset: Int) -> Int {
        
        if offset > buf.count {
            return 1
        }
        
        let bytes: [UInt8] = buf.copyBytes(as: UInt8.self)
        if((bytes[offset] & 0x1F) == 0x1F) { // see subsequent bytes
            var len: Int = 2
            for i in offset+1..<offset+10 {
                if( (bytes[i] & 0x80) != 0x80) {
                    break
                }
                len += 1
            }
            return len
        } else {
            return 1
        }
    }
    
    func createTag(buf: Data, offset: Int, len: Int, levelPadding: String) -> BerTag {
        
        let tag: BerTag = BerTag.init(data: buf, offset: offset, length: len)
        if BerTlvParser.IS_DEBUG_ENABLED {
            NSLog("%@Created tag %@ from buffer %@", levelPadding, tag, HexUtil.format(data: buf, offset: offset, len: len))
        }
        return tag
    }

    func createLevelPadding(level: Int) -> String {
        
        var sb: String = String.init()
        
        for _ in 0..<(level*4) {
            sb = sb.appending(" ")
        }
        return sb
    }
    
    func calcLengthBytesCount(buf: Data, offset: Int) -> Int {
        if offset > buf.count {
            return 1
        }
        
        let bytes: [UInt8] = buf.copyBytes(as: UInt8.self)
        let len: Int = (Int)(bytes[offset])
        if( (len & 0x80) == 0x80) {
            return (Int)(1 + (len & 0x7f))
        } else {
            return 1
        }
    }
    
    func calcDataLength(buf: Data, offset: Int) -> Int {
        if offset > buf.count {
            return 1
        }
        
        let bytes: [UInt8] = buf.copyBytes(as: UInt8.self)
        var length: Int = (Int)(bytes[offset])

        if((length & 0x80) == 0x80) {
            let numberOfBytes: Int = length & 0x7f
            if(numberOfBytes>3) {
                //TODO: Sanırım bu try catch muhabbeti
            }

            length = 0;
            for i in offset+1..<offset+1+numberOfBytes {
                length = length * 0x100 + Int(bytes[i])
            }

        }
        return length //1
    }

    func addChildren(buf: Data, offset: Int, level: Int, levelPadding: String, tagBytesCount: Int, dataBytesCount: Int, valueLength: Int, array: Array<BerTlv>) {

        var startPosition: Int = offset + tagBytesCount + dataBytesCount
        var len: Int = valueLength

        if startPosition + len > buf.count {
            //TODO: error
            return
        }
        
        var arrayCopy = array
        while startPosition < offset + valueLength + tagBytesCount + dataBytesCount {
            outResult = 0
            let tlv: BerTlv? = self.parseWithResult(buf: buf, offset:startPosition, len:len, level:level+1)
            //TODO: error
            
            if (tlv != nil) {
                arrayCopy.append(tlv!)
            }
            
            startPosition = outResult
            len = valueLength - startPosition

            if BerTlvParser.IS_DEBUG_ENABLED {
                NSLog("%@level %d: adding %@ with offset %d, startPosition=%d, aDataBytesCount=%d, valueLength=%u", levelPadding, level, tlv!.tag, outResult, startPosition,  dataBytesCount, valueLength
                );
            }
        }

    }
    
    

}
