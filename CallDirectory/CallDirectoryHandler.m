//
//  CallDirectoryHandler.m
//  CallDirectory
//
//  Created by CRMO on 2017/10/19.
//  Copyright © 2017年 CRMO. All rights reserved.
//

#import "CallDirectoryHandler.h"

@interface CallDirectoryHandler () <CXCallDirectoryExtensionContextDelegate>
@end

@implementation CallDirectoryHandler

// 开始请求的方法，在打开设置-电话-来电阻止与身份识别开关时，系统自动调用
// 调用CXCallDirectoryManager的reloadExtensionWithIdentifier方法会调用
- (void)beginRequestWithExtensionContext:(CXCallDirectoryExtensionContext *)context {
    context.delegate = self;
    
    if (![self addIdentificationPhoneNumbersToContext:context]) {
        NSError *error = [NSError errorWithDomain:@"CallDirectoryHandler" code:2 userInfo:nil];
        [context cancelRequestWithError:error];
        return;
    }
    
    [context completeRequestWithCompletionHandler:nil];
}

// 添加信息标识：需要修改CXCallDirectoryPhoneNumber数组和对应的标识数组；
// CXCallDirectoryPhoneNumber数组存放的号码和标识数组存放的标识要一一对应;
// CXCallDirectoryPhoneNumber数组内的号码要按升序排列
// 注意点：1.电话号码不能重复
//        2.手机号必须加国家码，例如：8615888888888
//        3.固话必须去掉区号的第一个0，加国家码、区号，例如：862861000000
- (BOOL)addIdentificationPhoneNumbersToContext:(CXCallDirectoryExtensionContext *)context {
    // 利用APP Group把待写入系统数据写到共享区域
#warning 必须填写Application Group Identifier
    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.crmo.CallKitDemo"];
    
#warning 必须填写文件名
    containerURL = [containerURL URLByAppendingPathComponent:@"CallDirectoryData"];
    
    FILE *file = fopen([containerURL.path UTF8String], "r");
    if (!file) {
        return YES;
    }
    char buffer[1024];
    
    // 一行一行的读，避免爆内存
    while (fgets(buffer, 1024, file) != NULL) {
        @autoreleasepool {
            NSString *result = [NSString stringWithUTF8String:buffer];
            NSData *jsonData = [result dataUsingEncoding:NSUTF8StringEncoding];
            NSError *err;
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                options:NSJSONReadingAllowFragments
                                                                  error:&err];
            
            if(!err && dic && [dic isKindOfClass:[NSDictionary class]]) {
                NSString *number = dic.allKeys[0];
                NSString *name = dic[number];
                if (number && [number isKindOfClass:[NSString class]] &&
                    name && [name isKindOfClass:[NSString class]]) {
                    CXCallDirectoryPhoneNumber phoneNumber = [number longLongValue];
                    [context addIdentificationEntryWithNextSequentialPhoneNumber:phoneNumber label:name];
                }
            }
            
            dic = nil;
            result = nil;
            jsonData = nil;
            err = nil;
        }
    }
    fclose(file);
    
    return YES;
}

// 号码拦截，与号码识别同理
//- (void)addAllBlockingPhoneNumbersToContext:(CXCallDirectoryExtensionContext *)context {
//    // Retrieve phone numbers to block from data store. For optimal performance and memory usage when there are many phone numbers,
//    // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
//    //
//    // Numbers must be provided in numerically ascending order.
//    CXCallDirectoryPhoneNumber allPhoneNumbers[] = { 14085555555, 18005555555 };
//    NSUInteger count = (sizeof(allPhoneNumbers) / sizeof(CXCallDirectoryPhoneNumber));
//    for (NSUInteger index = 0; index < count; index += 1) {
//        CXCallDirectoryPhoneNumber phoneNumber = allPhoneNumbers[index];
//        [context addBlockingEntryWithNextSequentialPhoneNumber:phoneNumber];
//    }
//}

#pragma mark - CXCallDirectoryExtensionContextDelegate

- (void)requestFailedForExtensionContext:(CXCallDirectoryExtensionContext *)extensionContext withError:(NSError *)error {
    // An error occurred while adding blocking or identification entries, check the NSError for details.
    // For Call Directory error codes, see the CXErrorCodeCallDirectoryManagerError enum in <CallKit/CXError.h>.
    //
    // This may be used to store the error details in a location accessible by the extension's containing app, so that the
    // app may be notified about errors which occured while loading data even if the request to load data was initiated by
    // the user in Settings instead of via the app itself.
}


@end
