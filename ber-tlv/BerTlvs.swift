//
//  BerTlvs.swift
//  ber-tlv
//
//  Created by Şükrü Can Avcı on 11.07.2022.
//  Copyright (c) 2022 Şükrü Can Avcı. All rights reserved.
//

import Foundation

class BerTlvs: NSObject {
    
    var list: Array<BerTlv>
    
    override init() {
        
        list = Array<BerTlv>()
    }
    
    required init(list: Array<BerTlv>) {
        
        self.list = list
    }
    
    func find(tag: BerTag) -> BerTlv? {

        for tlv in list {
            let found: BerTlv? = tlv.find(tag)
            if found != nil {
                return found
            }
        }
        return nil
    }
    
    func findAll(tag: BerTag) -> Array<BerTlv> {
        
        var ret: Array<BerTlv> = Array()
        for tlv in list {
            ret.append(contentsOf: tlv.findAll(tag))
        }
        return ret
    }
    
    func dump(padding: String) -> String {
        
        var sb: String = String.init()
        for tlv in list {
            sb.append(tlv.dump(padding)!)
        }
        return sb
    }

}
