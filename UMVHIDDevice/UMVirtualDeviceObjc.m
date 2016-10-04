//
//  UMVirtualDeviceObjc.m
//  UMVHIDDevice
//
//  Created by fOrest on 7/2/16.
//  Copyright © 2016 fOrest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMVirtualDeviceObjc.h"
#import <IOKit/IOKitLib.h>

@implementation UMVirtualDeviceObjc

+(BOOL)openDevice
{
    uint32_t input_count = 8;
    uint64_t input[input_count];
    input[0] = (uint64_t) strdup("devicename");  // device name
    input[1] = strlen((char *)input[0]);  // name length
    input[5] = strlen((char *)input[4]);  // serial number len
    input[6] = (uint64_t) 2;  // vendor ID
    input[7] = (uint64_t) 3;  // device ID
    
    return YES;
}


+ (io_service_t)findService
{
    io_service_t	result = IO_OBJECT_NULL;
    io_iterator_t 	iterator;
    
    if(IOServiceGetMatchingServices(
                                    kIOMasterPortDefault,
                                    IOServiceMatching([@"servicename" UTF8String]),
                                    &iterator) != KERN_SUCCESS)
    {
        return result;
    }
    
    result = IOIteratorNext(iterator);
    IOObjectRelease(iterator);
    return result;
}

+ (io_connect_t)createNewConnection
{
    io_connect_t result    = IO_OBJECT_NULL;
    io_service_t service   = [UMVirtualDeviceObjc findService];
    
    if(service == IO_OBJECT_NULL)
        return result;
    
    if(IOServiceOpen(service, mach_task_self(), 0, &result) != KERN_SUCCESS)
        result = IO_OBJECT_NULL;
    
    IOObjectRelease(service);
    return result;
}
@end