//
//  UMVHIDDeviceDriverAdapter.m
//  UMVHIDDevice
//
//  Created by fOrest on 7/2/16.
//  Copyright © 2016 fOrest. All rights reserved.
//

#import "UMVHIDDeviceDriverAdapter.h"

@implementation UMVHIDDeviceDriverAdapter

- (id)init:(NSString *)serviceName
{
    self = [super init];
    
    self->m_serviceName = serviceName;
    self->m_connection = [UMVHIDDeviceDriverAdapter createNewConnection: serviceName];
    
    return self;
}

- (void)dealloc
{
    [self close];
}

-(BOOL)callDriverCreateDevice:(NSString *)productName serialName:(NSString *)serialName vendorId:(UInt32 )vendorId productId:(UInt32)productId reportDescriptor:(NSData *)descriptor
{
    if (![self isOpen]) return NO;
    
    uint32_t inputCnt = 8;
    uint64_t inputBuffer[inputCnt];
    
    inputBuffer[0] = (uint64_t) strdup (productName.UTF8String);  // device name
    inputBuffer[1] = strlen((char *)inputBuffer[0]);              // name length
    inputBuffer[2] = (uint64_t) descriptor.bytes;                 // report descriptor
    inputBuffer[3] = (uint64_t) descriptor.length;                // report descriptor len
    inputBuffer[4] = (uint64_t) strdup (productName.UTF8String);  // serial number
    inputBuffer[5] = strlen((char *)inputBuffer[4]);              // serial number len
    inputBuffer[6] = (uint64_t) vendorId;                         // vendor ID
    inputBuffer[7] = (uint64_t) productId;                        // device ID
    
    return IOConnectCallScalarMethod(m_connection, (uint32_t)UMVirtualDeviceExternalMethodCreateDevice, inputBuffer, inputCnt, NULL, NULL) == KERN_SUCCESS;
}

-(BOOL)callDriverDestroyDevice:(NSString *)productName
{
    if (![self isOpen]) return NO;
    
    uint32_t inputCnt = 2;
    uint64_t inputBuffer[inputCnt];
    
    inputBuffer[0] = (uint64_t) strdup (productName.UTF8String);  // device name
    inputBuffer[1] = strlen((char *)inputBuffer[0]);              // name length
    
    return IOConnectCallScalarMethod(m_connection, (uint32_t)UMVirtualDeviceExternalMethodDestroyDevice, inputBuffer, inputCnt, NULL, NULL) == KERN_SUCCESS;
}

-(BOOL)callDriverHandleReport:(NSString *)productName reportData:(NSData *)report
{
    if (![self isOpen]) return NO;
    
    uint32_t inputCnt = 4;
    uint64_t inputBuffer[inputCnt];
    
    inputBuffer[0] = (uint64_t) strdup (productName.UTF8String);  // device name
    inputBuffer[1] = strlen((char *)inputBuffer[0]);              // name length
    inputBuffer[2] = (uint64_t) report.bytes;                     // report data
    inputBuffer[3] = (uint64_t) report.length;                    // report data len
    
    return IOConnectCallScalarMethod(m_connection, (uint32_t)UMVirtualDeviceExternalMethodHandleReport, inputBuffer, inputCnt, NULL, NULL) == KERN_SUCCESS;
}

-(BOOL)callDriverListDevices:(NSMutableArray *)devices
{
    if (![self isOpen]) return NO;
    
    BOOL ret = NO;
    
    char * deviceBuffer = (char * )malloc(128);
    
    uint32_t inputCnt = 2;
    uint64_t inputBuffer[inputCnt];
    
    inputBuffer[0] = (uint64_t) deviceBuffer;                     // device name buffer
    inputBuffer[1] = strlen((char *)inputBuffer[0]);              // buffer length
    
    uint32_t outputCnt = 2;
    uint64_t outputBuffer[outputCnt];
    
    BOOL called = NO;
    
call:
    if (IOConnectCallScalarMethod(m_connection, (uint32_t)UMVirtualDeviceExternalMethodListDevices, inputBuffer, inputCnt, outputBuffer, &outputCnt) == KERN_SUCCESS) {
        
        if (outputCnt != 2 ){
            goto end;
        }
        uint64_t lengthNeeded = outputBuffer[0];
        
        if (lengthNeeded != 0) {
            
            if (called){
                goto end;
            }
            
            free(deviceBuffer);
            deviceBuffer = (char * )malloc(lengthNeeded);
            called = YES;
            
            goto call;
        }
        
        uint64_t itemCount = outputBuffer[1];
        char *pointer = deviceBuffer;
        
        while (itemCount > 0) {
            
            if (strlen(pointer) <= 0) {
                goto end;
            }
                
            NSString *deviceName = [NSString stringWithUTF8String:pointer];
            if (deviceName == NULL) {
                goto end;
            }
            
            [devices addObject:deviceName];
            pointer += strlen(pointer) + 1;
            
            if (pointer > (deviceBuffer + sizeof(deviceBuffer))) {
                goto end;
            }
            itemCount--;
        }
        ret = YES;
    }
    
end:
    if (deviceBuffer) {
        free(deviceBuffer);
    }
    return ret;
}

-(BOOL)callDriverGetDeviceState:(NSString *)productName state:(UInt32 *)state
{
    if (![self isOpen]) return NO;
    
    BOOL ret = NO;
    
    uint32_t inputCnt = 2;
    uint64_t inputBuffer[inputCnt];
    
    inputBuffer[0] = (uint64_t) strdup (productName.UTF8String);  // device name
    inputBuffer[1] = strlen((char *)inputBuffer[0]);              // name length
    
    uint32_t outputCnt = 1;
    uint64_t outputBuffer[outputCnt];
    
    IOReturn ioret = IOConnectCallScalarMethod(m_connection, (uint32_t)UMVirtualDeviceExternalMethodGetDeviceState, inputBuffer, inputCnt, outputBuffer, &outputCnt);
    if ( ioret == KERN_SUCCESS) {
        ret = YES;
        *state = (UInt32)outputBuffer[0];
    }
    
    return ret;
}


-(BOOL)open
{
    if ([self isOpen]) return YES;

    self->m_connection = [UMVHIDDeviceDriverAdapter createNewConnection: self->m_serviceName];
    if(self->m_connection == IO_OBJECT_NULL)
    {
        return NO;
    }
    return YES;
}

-(BOOL)isOpen
{
    if(m_connection == IO_OBJECT_NULL) {
        return NO;
    }
    return YES;
}

-(void)close
{
    if (![self isOpen]) return;
    
    IOServiceClose(m_connection);
    if (m_connection != IO_OBJECT_NULL) {
        
        IOConnectRelease(m_connection);
        m_connection = IO_OBJECT_NULL;
    }
}

+ (io_service_t)findService:(NSString *)serivceName
{
    io_service_t	result = IO_OBJECT_NULL;
    io_iterator_t 	iterator;
    
    if(IOServiceGetMatchingServices(
                                    kIOMasterPortDefault,
                                    IOServiceMatching([serivceName UTF8String]),
                                    &iterator) != KERN_SUCCESS)
    {
        return result;
    }
    
    result = IOIteratorNext(iterator);
    IOObjectRelease(iterator);
    return result;
}

+ (io_connect_t)createNewConnection:(NSString *)serivceName
{
    io_connect_t result    = IO_OBJECT_NULL;
    io_service_t service   = [UMVHIDDeviceDriverAdapter findService:serivceName];
    
    if(service == IO_OBJECT_NULL)
        return result;
    
    if(IOServiceOpen(service, mach_task_self(), 0, &result) != KERN_SUCCESS)
        result = IO_OBJECT_NULL;
    
    IOObjectRelease(service);
    return result;
}

+(BOOL)isDriverLoaded:(NSString *)serivceName
{
    io_service_t service = [UMVHIDDeviceDriverAdapter findService:serivceName];
    BOOL         result  = (service != IO_OBJECT_NULL);
    
    IOObjectRelease(service);
    return result;
}

+(BOOL)loadDriver:(NSString *)serivceName
{
    if([UMVHIDDeviceDriverAdapter isDriverLoaded: serivceName])
        return YES;
    // TODO:
    return YES;
}

+(BOOL)unloadDriver:(NSString *)serivceName
{
    if(![UMVHIDDeviceDriverAdapter isDriverLoaded:serivceName])
        return YES;
    // TODO:
    return YES;
}

@end
