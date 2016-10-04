//
//  UMVHIDButtonCollection.swift
//  UMVHIDDevice
//
//  Created by fOrest on 6/24/16.
//  Copyright © 2016 fOrest. All rights reserved.
//

import Foundation

let HIDDescriptorSizeWithPadding = 22
let HIDDescriptorSizeWithoutPadding = 16

let buttonMasks: [UInt8] = [1, 2, 4, 8, 16, 32, 64, 128]

class UMVHIDButtonCollection {
    
    
    fileprivate var count: Int = 0
    var descriptor: [UInt8] = []
    var report: [UInt8] = []
    
    static let maxButtonCount: Int = 0xff
    
    static func descriptorWithButtonCount(_ buttonCount: Int, reportSize: inout Int) ->[UInt8] {
        
        let count = UInt8(buttonCount)
        let paddingBits    = (8 - count % 8) % 8
        var result: [UInt8]
        
        reportSize = Int((count + paddingBits) / 8)
        
        let length = (paddingBits == 0) ? HIDDescriptorSizeWithoutPadding : HIDDescriptorSizeWithPadding
        
        result = Array<UInt8>(repeating: 0x00, count: length)
        
        var index: Int = 0
        
        result[index] = 0x05; index += 1; result[index] = 0x09;        index += 1 //  USAGE_PAGE (Button)
        result[index] = 0x19; index += 1; result[index] = 0x01;        index += 1 //  USAGE_MINIMUM (Button 1)
        result[index] = 0x29; index += 1; result[index] = count;       index += 1 //  USAGE_MAXIMUM (Button buttonCount)
        result[index] = 0x15; index += 1; result[index] = 0x00;        index += 1 //  LOGICAL_MINIMUM (0)
        result[index] = 0x25; index += 1; result[index] = 0x01;        index += 1 //  LOGICAL_MAXIMUM (1)
        result[index] = 0x95; index += 1; result[index] = count;       index += 1 //  REPORT_COUNT (buttonCount)
        result[index] = 0x75; index += 1; result[index] = 0x01;        index += 1 //  REPORT_SIZE (1)
        result[index] = 0x81; index += 1; result[index] = 0x02;        index += 1 //  INPUT (Data, Var, Abs)
        
        if paddingBits == 0 {
            
            return result
        }
        
        result[index] = 0x95; index += 1; result[index] = 0x01;        index += 1 //  REPORT_COUNT (1)
        result[index] = 0x75; index += 1; result[index] = paddingBits; index += 1 //  REPORT_SIZE (paddingBits)
        result[index] = 0x81; index += 1; result[index] = 0x03;        index += 1 //  INPUT (Cnst, Var, Abs)
        
        return result
    }
    
    var buttonCount: Int {
        get {
            return count
        }
    }

    init?(buttonCount: Int)
    {
        
        if buttonCount == 0 || buttonCount > UMVHIDButtonCollection.maxButtonCount {
            return nil
        }
        
        var reportSize = 0;
        
        self.count         = buttonCount;
        self.descriptor    = UMVHIDButtonCollection.descriptorWithButtonCount(buttonCount, reportSize: &reportSize)
        self.report        = [UInt8](repeating: 0, count: reportSize )
    }
    
    func isButtonPressed(_ buttonIndex: Int) ->Bool
    {
        
        if buttonIndex >= count || buttonIndex < 0 {
            return false
        }
        
        let bytesIndex = buttonIndex / 8;
        let bitIndex   = buttonIndex % 8;
        
        return ((report[bytesIndex] & buttonMasks[bitIndex]) != 0)
    }
    
    func setButton(_ buttonIndex: Int, pressedState pressed: Bool) {
        
        if buttonIndex >= count || buttonIndex < 0 {
            return
        }
        
        let bytesIndex = buttonIndex / 8;
        let bitIndex   = buttonIndex % 8;
        
        if pressed {
            
            report[bytesIndex] |= buttonMasks[bitIndex]
        } else {
            report[bytesIndex] &= ~(buttonMasks[bitIndex])
        }
    }
    
    func reset() {
        
        self.report = [UInt8](repeating: 0, count: report.count)
    }
}
