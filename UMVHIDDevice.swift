//
//  UMVHIDDevice.swift
//  UMVHIDDevice
//
//  Created by fOrest on 6/25/16.
//  Copyright © 2016 fOrest. All rights reserved.
//

import Foundation
import CoreGraphics


let HIDDescriptorMouseAdditionalBytes      = 12
let HIDDescriptorJoystickAdditionalBytes   = 10

public enum UMVHIDDeviceType {
    
    case umVHIDDeviceTypeMouse
    case umVHIDDeviceTypeJoystick
    
    var usgae: UInt8 {
        
        switch self {
        case .umVHIDDeviceTypeMouse:return 0x02
        case .umVHIDDeviceTypeJoystick:return 0x05
        default: break
        }
    }
    
    var additionalBytes: Int {
        
        switch self {
        case .umVHIDDeviceTypeMouse:return HIDDescriptorMouseAdditionalBytes
        case .umVHIDDeviceTypeJoystick:return HIDDescriptorJoystickAdditionalBytes
        default: break
        }
    }
}

public protocol UMVHIDDeviceDelegate: class {
    
    func umVHIDDevice(_ device: UMVHIDDevice, stateDidChange state: [Int8])
}


open class UMVHIDDevice {
    
    var type: UMVHIDDeviceType
    
    var buttons:  UMVHIDButtonCollection?
    var pointers: UMVHIDPointerCollection?
    
    var _descriptor: [UInt8] = []
    var _report: [Int8] = []

    open var delegate: UMVHIDDeviceDelegate?
    
    static var maxButtonCount: Int {
        get {
            return UMVHIDButtonCollection.maxButtonCount
        }
    }
    
    static var maxPointerCount: Int {
        get {
            return UMVHIDPointerCollection.maxPointerCount
        }
    }
    
    func createDescriptor() ->[UInt8] {
        
        
        let isMouse: Bool         = self.type == UMVHIDDeviceType.umVHIDDeviceTypeMouse
        
        let buttonsDescriptor     = self.buttons?.descriptor
        let pointersDescriptor    = self.pointers?.descriptor
        
        let usage          = type.usgae
        
        let length = (buttonsDescriptor?.count ?? 0) + (pointersDescriptor?.count ?? 0) + type.additionalBytes
        var result         = [UInt8](repeating: 0, count: length)
        
        var index: Int = 0
        
        result[index] = 0x05; index += 1; result[index] = 0x01;        index += 1 // USAGE_PAGE (Generic Desktop)
        result[index] = 0x09; index += 1; result[index] = usage;       index += 1 // USAGE (Mouse/Game Pad)
        result[index] = 0xA1; index += 1; result[index] = 0x01;        index += 1 // COLLECTION (Application)
        
        if(isMouse)
        {
            result[index] = 0x09; index += 1; result[index] = 0x01;        index += 1 // USAGE (Pointer)
        }
        
        result[index] = 0xA1; index += 1; result[index] = 0x00;        index += 1 // COLLECTION (Physical)
        
        if buttons != nil {
            
            for byte in buttonsDescriptor! {
                result[index] = byte; index += 1
            }
        }
        
        if pointers != nil {
            
            for byte in pointersDescriptor! {
                result[index] = byte; index += 1
            }
        }
    
        result[index] = 0xC0; index += 1; // END_COLLECTION
        result[index] = 0xC0; index += 1; // END_COLLECTION
    
        return result;
    }

    
    public init?(type: UMVHIDDeviceType, pointerCount: Int, buttonCount: Int, isRelative relative: Bool ) {

        self.type      = type;
        self.buttons   = UMVHIDButtonCollection(buttonCount: buttonCount)
        self.pointers  = UMVHIDPointerCollection(pointerCount: pointerCount, isRelative: relative)
        
        if buttons  == nil && pointers == nil {
            
            return nil
        }
        _report     = [Int8](repeating: 0, count: self.buttons!.report.count + self.pointers!.report.count * 2)
        _descriptor = createDescriptor()
    }
    
    
    open var deviceType: UMVHIDDeviceType {
        get {
            return type
        }
    }
    
    open var isRelative: Bool {
        get {
            return pointers?.isRelative ?? false
        }
    }
    
    open var buttonCount: Int {
        get {
            return buttons?.buttonCount ?? 0
        }
    }
    
    open var pointerCount: Int {
        get {
            return pointers?.pointerCount ?? 0
        }
    }
    
    open func isButtonPressed(_ buttonIndex: Int) ->Bool {
        
        return buttons?.isButtonPressed(buttonIndex) ?? false
    }
    
    open func setButton(_ buttonIndex: Int, pressed: Bool) {
        
        if isButtonPressed(buttonIndex) == pressed {
            
            return
        }
        
        if buttons != nil {
            
            buttons!.setButton(buttonIndex, pressedState: pressed)
            delegate?.umVHIDDevice(self, stateDidChange: state)
        }
    }
    
    
    open func pointerPosition(_ pointerIndex: Int) ->CGPoint {
        
        return pointers?.pointerPosition(pointerIndex: pointerIndex) ?? CGPoint.zero
    }
    
    open func setPointer(_ pointerIndex: Int, position: CGPoint) {
        
        if pointerPosition(pointerIndex).equalTo(position) {
            return
        }
        
        if pointers != nil {
            pointers?.setPointer(pointerIndex: pointerIndex, position: position)
            delegate?.umVHIDDevice(self, stateDidChange: state)
        }
    }
    
    open func setState(buttonSequence buttons:[Bool], pointerSequence pointers:[CGPoint]  ) {
        
        if buttons.count < buttonCount || pointers.count < pointerCount {
            return
        }
        
        for index in 0...buttonCount - 1 {
            self.buttons!.setButton(index, pressedState: buttons[index])
        }
        for index in 0...pointerCount - 1 {
            self.pointers?.setPointer(pointerIndex: index, position: pointers[index])
        }
        
        delegate?.umVHIDDevice(self, stateDidChange: state)
    }

    
    open func reset() {
        
        self.buttons?.reset()
        self.pointers?.reset()
        
        self.delegate?.umVHIDDevice(self, stateDidChange: state)
    }
    
    open var descriptor: [UInt8] {
        get {
            return self._descriptor
        }
    }
    
    open var state: [Int8] {
        
        get {
            
            var index = 0
            if buttons != nil {
                
                var buttonReport = buttons!.report
                memcpy(&_report, &buttonReport, buttonReport.count)
                
                index = buttonReport.count
            }
            if pointers != nil {
                
                var ponterReport = pointers!.report
                memcpy(&_report + index, &ponterReport, _report.count - index)
            }
            
            return _report
        }
    }
}
