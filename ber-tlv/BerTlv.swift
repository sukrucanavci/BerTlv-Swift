//
//  BerTlv.swift
//  ber-tlv
//
//  Created by Şükrü Can Avcı on 11.07.2022.
//  Copyright (c) 2022 Şükrü Can Avcı. All rights reserved.
//

import Foundation

public class BerTlv: NSObject {
    
    var tag: BerTag!
    var value: Data?
    var list: Array<BerTlv>?
    var primitive: Bool!
    var constructed: Bool!
    
    required init(_ tag: BerTag, _ value: Data) {
        
        super.init()

        self.tag = tag
        self.value = value
        self.constructed = tag.isConstructed()
        self.primitive = !constructed
    }
    
    required init(_ tag: BerTag, _ array: Array<BerTlv>) {
        
        super.init()

        self.tag = tag
        self.list = array
        self.constructed = tag.isConstructed()
        self.primitive = !constructed
    }
    
    func hasTag(_ tag: BerTag) -> Bool {
        return self.find(tag) != nil
    }
    
    func find(_ tag: BerTag) -> BerTlv? {
        
        if tag.isEqualToTag(tag: self.tag) {
            return self;
        }

        if(primitive) {
            return nil;
        }
        
        for tlv in list ?? [] {
            let found: BerTlv? = tlv.find(tag)
            if(found != nil) {
                return found;
            }
        }

        return nil;
    }
    
    func findAll(_ tag: BerTag) -> Array<BerTlv> {
        
        var array: Array<BerTlv> = Array()
        if tag.isEqualToTag(tag: self.tag) {
            array.append(self)
        }

        if constructed {
            for tlv in list ?? [] {
                let found: Array<BerTlv> = tlv.findAll(tag)
                array.append(contentsOf: found)
            }
        }

        return array
    }
    
    func hexValue() -> String? {
        
        if constructed {
            NSLog("Tag %@ is constructed \(tag!)")
            return nil
        } else {
            return HexUtil.format(value!);
        }
    }
    
    func textValue() -> String? {
        
        return String.init(data: self.value!, encoding: .ascii)
    }
    
    func dump(_ padding: String) -> String? {
        
        var sb: String = String.init()

        if(primitive) {
            sb = sb.appendingFormat("%@ - [%@] %@\n", [padding, tag.hex(), self.hexValue()])
        } else {
            sb = sb.appendingFormat("%@ + [%@]\n", [padding, tag.hex()])
            var childPadding: String = ""
            childPadding.append(padding)
            childPadding.append(padding)
            for tlv in list ?? [] {
                sb.append(tlv.dump(childPadding)!)
            }
        }
        return sb
    }
    
    
}

