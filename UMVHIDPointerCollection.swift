//
//  UMVHIDPointerCollection.swift
//  UMVHIDDevice
//
//  Created by fOrest on 6/24/16.
//  Copyright © 2016 fOrest. All rights reserved.
//

import Foundation
import CoreGraphics

let HIDStatePointerSize                     =   2

let HIDDescriptorBaseSize                   =   12 + 2
let HIDDescriptorPointerCoordinateBase      =   0x30
let HIDDescriptorPointerCoordinateBase2     =   0x40

let HIDDescriptorMaxPointersBase            =   3
let HIDDescriptorMaxPointersBase2           =   3

class UMVHIDPointerCollection {
    
    static func clipCoordinateFrom( value: inout Float) ->Float {
        
        value /= 127.0
        
        if value < -1.0 {
            value = -1.0
        }
        
        if value > 1.0 {
            value = 1.0
        }
        
        return value;
    }
    
    static func clipCoordinateTo( value: inout Float) ->Float {
        
        value *= 127.0
        
        if value < -127.0 {
            value = -127.0
        }
        
        if value > 127.0 {
            value = 127.0
        }
        return value
    }
    
    static var maxPointerCount: Int {
        
        get{
            return (HIDDescriptorMaxPointersBase + HIDDescriptorMaxPointersBase2);
        }
    }
    
    static func translatePointerCoordinateIndex(pointerCoordinateIndex: Int) ->UInt8 {
        
        var pointerIndex = pointerCoordinateIndex
        if pointerIndex < (HIDDescriptorMaxPointersBase * 2) {
            return UInt8(HIDDescriptorPointerCoordinateBase + pointerCoordinateIndex)
        }
    
        pointerIndex -= HIDDescriptorMaxPointersBase * 2
        if pointerIndex < (HIDDescriptorMaxPointersBase2 * 2) {
            return UInt8(HIDDescriptorPointerCoordinateBase2 + pointerCoordinateIndex);
        }


        return 255
    }
    
//    static func descriptorWithPointerCount(pointerCount: Int, isRelative relative: Bool ,inout reportSize: Int) ->[UInt8] {
//        
//        reportSize = pointerCount * HIDStatePointerSize
//
//        let length = HIDDescriptorBaseSize + pointerCount * 4
//        
//        var result: [UInt8] = Array<UInt8>(count: length, repeatedValue: 0x00)
//        
//        
//        var index = 0
//        result[index] = 0x05; index += 1; result[index] = 0x01;        index += 1 //  USAGE_PAGE (Generic Desktop)
//        
//        var coordinateIndex: UInt8 = 0
//        let CoordinateCount: UInt8 = UInt8(pointerCount * 2);
//        
//        while coordinateIndex < CoordinateCount {
//            
//            let usage = translatePointerCoordinateIndex(Int(coordinateIndex))
//            result[index] = 0x09; index += 1; result[index] = usage;   index += 1 //  USAGE (X (Vx) + coordinate_index)
//            
//            coordinateIndex += 1
//        }
//        
//        result[index] = 0x15; index += 1; result[index] = 0x81;        index += 1 //  LOGICAL_MINIMUM (-127)
//        result[index] = 0x25; index += 1; result[index] = 0x7f;        index += 1 //  LOGICAL_MAXIMUM (127)
//        result[index] = 0x75; index += 1; result[index] = 0x08;        index += 1 //  REPORT_SIZE (8)
//        result[index] = 0x95; index += 1; result[index] = CoordinateCount;        index += 1 //  REPORT_COUNT (pointerCount * 2)
//        result[index] = 0x81; index += 1; result[index] = relative ? 0x06 : 0x02; index += 1 //  INPUT (Data,Var,Rel/Abs)
//        
//        return result
//    }
    
    static func descriptorWithPointerCount(pointerCount: Int, isRelative relative: Bool , reportSize: inout Int) ->[UInt8] {
        
        reportSize = pointerCount * HIDStatePointerSize
        
        let length = HIDDescriptorBaseSize + pointerCount * 4
        
        var result: [UInt8] = Array<UInt8>(repeating: 0x00, count: length)
        
        
        var index = 0
        result[index] = 0x05; index += 1; result[index] = 0x01;        index += 1 //  USAGE_PAGE (Generic Desktop)
        
        var coordinateIndex: UInt8 = 0
        let CoordinateCount: UInt8 = UInt8(pointerCount * 2);
        
        while coordinateIndex < CoordinateCount {
            
            let usage = translatePointerCoordinateIndex(pointerCoordinateIndex: Int(coordinateIndex))
            result[index] = 0x09; index += 1; result[index] = usage;   index += 1 //  USAGE (X (Vx) + coordinate_index)
            
            coordinateIndex += 1
        }
        
        result[index] = 0x16; index += 1; result[index] = 0x00;        index += 1; result[index] = 0x80;        index += 1 //  LOGICAL_MINIMUM (-32768)
        result[index] = 0x26; index += 1; result[index] = 0xff;        index += 1; result[index] = 0x7f;        index += 1 //  LOGICAL_MAXIMUM (32767)
        result[index] = 0x75; index += 1; result[index] = 0x10;        index += 1 //  REPORT_SIZE (8)
        result[index] = 0x95; index += 1; result[index] = CoordinateCount;        index += 1 //  REPORT_COUNT (pointerCount * 2)
        result[index] = 0x81; index += 1; result[index] = relative ? 0x06 : 0x02; index += 1 //  INPUT (Data,Var,Rel/Abs)
        
        return result
    }
    
    
    var count: Int = 0
    var relative: Bool = false
    var descriptor: [UInt8] = []
    var report: [Int16] = []

    
    init?(pointerCount: Int, isRelative relative: Bool) {
        
        if pointerCount <= 0 || pointerCount > UMVHIDPointerCollection.maxPointerCount {
            return nil
        }
        
        var reportSize: Int = 0
        
        self.count      = pointerCount
        self.relative   = relative
        self.descriptor = UMVHIDPointerCollection.descriptorWithPointerCount(pointerCount: pointerCount, isRelative: relative, reportSize: &reportSize)
        self.report     = [Int16](repeating: 0, count: reportSize )
    }
    
        
    var isRelative: Bool {
        get {
            return self.relative
        }
    }
            
    var pointerCount: Int {
        get {
            return count;
        }
    }
    
    func pointerPosition(pointerIndex: Int) ->CGPoint {
        
        if pointerIndex >= count {
            return CGPoint.zero
        }
    
        let indexInReport: Int = pointerIndex * HIDStatePointerSize
        
        let x: Float = Float(report[indexInReport])
        let y: Float = Float(report[indexInReport + 1])
        
//        x = UMVHIDPointerCollection.clipCoordinateFrom(&x)
//        y = UMVHIDPointerCollection.clipCoordinateFrom(&y)
        
        //report[indexInReport]       = Int8(x)
        //report[indexInReport + 1]   = Int8(y)
        
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
    
    func setPointer(pointerIndex:Int, position: CGPoint) ->Bool{
        
        if pointerIndex >= UMVHIDPointerCollection.maxPointerCount {
            return false
        }
        
        let indexInReport: Int = pointerIndex * HIDStatePointerSize
        
        var x: Float = Float(position.x)
        var y: Float = Float(position.y)
        
//        report[indexInReport]       = Int8(UMVHIDPointerCollection.clipCoordinateTo(&x))
//        report[indexInReport + 1]   = Int8(UMVHIDPointerCollection.clipCoordinateTo(&y))
        report[indexInReport]       = Int16(position.x)
        report[indexInReport + 1]   = Int16(position.y)

        return true
    }
    
    func reset() {
        
        self.report = [Int16](repeating: 0, count: report.count )
    }
}
