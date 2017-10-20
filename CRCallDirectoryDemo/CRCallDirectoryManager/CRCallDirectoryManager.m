//
//  CRCallDirectoryManager.m
//
//  Created by CRMO on 2017/10/17.
//  Copyright © 2017年 CRMO. All rights reserved.
//

#import "CRCallDirectoryManager.h"

@interface CRCallDirectoryManager ()

/** externsion的Bundle ID **/
@property (nonatomic, strong) NSString *externsionIdentifier;
/** APP Groups的ID **/
@property (nonatomic, strong) NSString *groupIdentifier;
/** 存储待写入电话号码与标识，key：号码，value：标识 **/
@property (nonatomic, strong) NSMutableDictionary *dataList;

@end

@implementation CRCallDirectoryManager

- (instancetype)initWithExtensionIdentifier:(NSString *)externsionIdentifier ApplicationGroupIdentifier:(NSString *)groupIdentifier {
    if (self = [super init]) {
        self.externsionIdentifier = externsionIdentifier;
        self.groupIdentifier = groupIdentifier;
    }
    return self;
}

- (void)getEnableStatus:(void (^)(CXCallDirectoryEnabledStatus enabledStatus, NSError * error))completion {
    CXCallDirectoryManager *manager = [CXCallDirectoryManager sharedInstance];
    [manager
     getEnabledStatusForExtensionWithIdentifier:self.externsionIdentifier
     completionHandler:^(CXCallDirectoryEnabledStatus enabledStatus, NSError * _Nullable error) {
         completion(enabledStatus, error);
     }];
}

- (BOOL)addPhoneNumber:(NSString *)phoneNumber label:(NSString *)label {
    if (!phoneNumber || ![phoneNumber isKindOfClass:[NSString class]] ||
        !label || ![label isKindOfClass:[NSString class]] || label.length == 0) {
        return NO;
    }
    
    NSString *handledPhoneNumber = [self handlePhoneNumber:phoneNumber];
    if (!handledPhoneNumber) {
        return NO;
    }
    
    if (self.dataList[handledPhoneNumber]) { // 已经设置过这个phoneNumber
        return NO;
    }
    
    [self.dataList setObject:label forKey:handledPhoneNumber];
    return YES;
}

- (BOOL)reload:(void (^)(NSError *error))completion {
    if (self.dataList.count == 0) {
        return NO;
    }
    
    if (![self writeDataToAppGroupFile]) {
        return NO;
    }
    
    CXCallDirectoryManager *manager = [CXCallDirectoryManager sharedInstance];
    [manager reloadExtensionWithIdentifier:self.externsionIdentifier completionHandler:^(NSError * _Nullable error) {
        completion(error);
    }];
    
    return YES;
}

#pragma mark -
#pragma mark -Inner Method

- (void)clearPhoneNumber {
    [self.dataList removeAllObjects];
}

/**
 处理手机号码
 自动加上国家码，如果号码不合规返回nil
 */
- (NSString *)handlePhoneNumber:(NSString *)phoneNumber {
    NSString *mobileWithNationCodeRegex = @"^861[0-9]{10}$";
    NSPredicate *hasNationCode = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", mobileWithNationCodeRegex];
    if ([hasNationCode evaluateWithObject:phoneNumber]) {
        return phoneNumber;
    }
    
    NSString *mobileWithOutNationCodeRegex = @"^1[0-9]{10}$";
    NSPredicate *notHasNationCode = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", mobileWithOutNationCodeRegex];
    if ([notHasNationCode evaluateWithObject:phoneNumber]) {
        return [NSString stringWithFormat:@"86%@", phoneNumber];
    }
    
    return nil;
}

/**
 对dataList中的记录进行升序排序，然后转换为string
 */
- (NSString *)dataToString {
    NSMutableArray *phoneArray = [NSMutableArray arrayWithArray:[self.dataList allKeys]];
    [phoneArray sortUsingSelector:@selector(compare:)];
    NSMutableString *dataStr = [[NSMutableString alloc] init];
    
    for (NSString *phone in phoneArray) {
        NSString *label = self.dataList[phone];
        NSString *dicStr = [NSString stringWithFormat:@"{\"%@\":\"%@\"}\n", phone, label];
        [dataStr appendString:dicStr];
    }
    
    return [dataStr copy];
}

/**
 将数据写入APP Group指定文件中
 */
- (BOOL)writeDataToAppGroupFile {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:self.groupIdentifier];
    containerURL = [containerURL URLByAppendingPathComponent:@"CallDirectoryData"];
    NSString* filePath = containerURL.path;
    
    if (!filePath || ![filePath isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    if([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:nil];
    }
    
    if (![fileManager createFileAtPath:filePath contents:nil attributes:nil]) {
        return NO;
    }
    
    BOOL result = [[self dataToString] writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [self clearPhoneNumber];
    
    return result;
}

- (NSMutableDictionary *)dataList {
    if (!_dataList) {
        _dataList = [NSMutableDictionary dictionary];
    }
    return _dataList;
}

@end
