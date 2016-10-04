//
//  UMVHIDDeviceDriverAdapter.h
//  UMVHIDDevice
//
//  Created by fOrest on 7/2/16.
//  Copyright © 2016 fOrest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>

#define kUMVirtualDeviceDriverName = @"com_fOrest_umvhid_service"

enum{
    
    UMVirtualDeviceExternalMethodCreateDevice,
    UMVirtualDeviceExternalMethodDestroyDevice,
    UMVirtualDeviceExternalMethodHandleReport,
    UMVirtualDeviceExternalMethodListDevices,
    UMVirtualDeviceExternalMethodGetDeviceState
    
} UMVirtualDeviceExternalMethod;

@interface UMVHIDDeviceDriverAdapter : NSObject {
    
@private
    io_connect_t m_connection;
    
    NSString *m_serviceName;
}

- (id)init:(NSString *)serviceName;

-(BOOL)callDriverCreateDevice:(NSString *)productName serialName:(NSString *)serialName vendorId:(UInt32 )vendorId productId:(UInt32)productId reportDescriptor:(NSData *)descriptor;

-(BOOL)callDriverDestroyDevice:(NSString *)productName;

-(BOOL)callDriverHandleReport:(NSString *)productName reportData:(NSData *)report;

-(BOOL)callDriverListDevices:(NSMutableArray *)devices;

-(BOOL)callDriverGetDeviceState:(NSString *)productName state:(UInt32 *)state;

-(BOOL)open;

-(void)close;

-(BOOL)isOpen;

@end
