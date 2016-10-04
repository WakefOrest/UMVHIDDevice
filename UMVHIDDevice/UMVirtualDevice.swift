//
//  UMVirtualDevice.swift
//  UMVHIDDevice
//
//  Created by fOrest on 7/2/16.
//  Copyright © 2016 fOrest. All rights reserved.
//

import Foundation
import IOKit

let kUMVirtualDeviceDriverName = "com_fOrest_umvhid_service"

public enum UMVirtualDevicePropertyKeys: String {
    
    case kUMVirtualDeviceProductName = "kUMVirtualDeviceProductName"
    case kUMVirtualDeviceSerialNumber = "kUMVirtualDeviceSerialNumber"
    case kUMVirtualDeviceVendorId = "kUMVirtualDeviceVendorId"
    case kUMVirtualDeivceProductId = "kUMVirtualDeivceProductId"
}


open class UMVirtualDevice: NSObject {
    
    fileprivate var productName: String
    
    fileprivate var serialNumber: String
    
    fileprivate var vendorId: UInt32
    
    fileprivate var productId: UInt32
    
    fileprivate var serviceName: String
    
    fileprivate var reportDescriptor: Data
    
    fileprivate var adapter: UMVHIDDeviceDriverAdapter
    
    open var properties: NSDictionary
    
    /**@property    deviceState get IOSerivce object state
     *
     * @result      0x00000000 device(ioserivce) does not exist
     *              0x00000001 device(ioservice) inactive
     */
    open var deviceState: UInt32 {
        get {
            var state: UInt32 = 0;
            if !self.adapter.callDriverGetDeviceState(self.productName, state: &state) {
                print("getDeviceState failed, name: \(self.productName)")
            }
            return state
        }
    }
    
    public init(productName: String, serialNumber: String, vendorId: UInt32, productId: UInt32, reportDescriptor descriptor: Data, serviceName: String = kUMVirtualDeviceDriverName) {
        
        self.productName = productName
        self.serialNumber = serialNumber
        self.vendorId = vendorId
        self.productId = productId
        self.reportDescriptor = descriptor
        self.serviceName = serviceName
        
        properties = NSDictionary(dictionaryLiteral:
        
            (UMVirtualDevicePropertyKeys.kUMVirtualDeviceProductName.rawValue, self.productName),
            (UMVirtualDevicePropertyKeys.kUMVirtualDeviceSerialNumber.rawValue, self.serialNumber),
            (UMVirtualDevicePropertyKeys.kUMVirtualDeviceVendorId.rawValue, Int(self.vendorId)),
            (UMVirtualDevicePropertyKeys.kUMVirtualDeivceProductId.rawValue, Int(self.productId))
        )
        self.adapter = UMVHIDDeviceDriverAdapter(kUMVirtualDeviceDriverName)
    }
    
    public convenience init?(properties: NSDictionary, reportDescriptor descriptor: Data, serviceName: String = kUMVirtualDeviceDriverName) {
        
        let productName  = properties["UMVirtualDevicePropertyKeys.kUMVirtualDeviceProductName.rawValue"] as? String
        let serialNumber = properties["UMVirtualDevicePropertyKeys.kUMVirtualDeviceSerialNumber.rawValue"] as? String
        let vendorId     = properties["UMVirtualDevicePropertyKeys.kUMVirtualDeviceVendorId.rawValue"] as? UInt32
        let productId    = properties["UMVirtualDevicePropertyKeys.kUMVirtualDeivceProductId.rawValue"] as? UInt32
        
        if productName == nil || serialNumber == nil || vendorId == nil || productId == nil{
            
            return nil
        }
        
        self.init(productName: productName!, serialNumber: serialNumber!, vendorId: vendorId!,productId: productId!, reportDescriptor: descriptor, serviceName: serviceName)
    }
    
    deinit {
        
        close()
    }
    
    open func sendReport(_ report: Data) ->Bool {
        
        return self.adapter.callDriverHandleReport(self.productName, report: report)
    }
    
    open func isOpen() ->Bool {
        
        if !self.adapter.isOpen() {
            return false
        }
        if deviceState == 0 {
            return false
        }
        return true
    }
    
    open func open() ->Bool {
        
        if !self.adapter.open() {
            return false
        }
        if !self.adapter.callDriverCreateDevice(self.productName, serialName: self.serialNumber, vendorId: self.vendorId, productId: self.productId, reportDescriptor: self.reportDescriptor as Data!) {
            return false
        }
        return true
    }
    
    open func close() ->Void {
        
        if self.adapter.isOpen() {
            
            self.adapter.callDriverDestroyDevice(self.productName)
            self.adapter.close()
        }
    }
}
