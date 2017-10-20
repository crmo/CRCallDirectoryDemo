//
//  ViewController.m
//  CRCallDirectoryDemo
//
//  Created by CRMO on 2017/10/19.
//  Copyright © 2017年 CRMO. All rights reserved.
//

#import "ViewController.h"
#import "CRCallDirectoryManager.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *phoneText;
@property (weak, nonatomic) IBOutlet UITextField *indtifierText;
@property (nonatomic, strong) CRCallDirectoryManager *manager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
#warning extension Bundle ID和App Group ID需要根据实际项目调整
    self.manager = [[CRCallDirectoryManager alloc] initWithExtensionIdentifier:@"com.crmo.CRCallDirectoryDemo.CallDirectory"
                                            ApplicationGroupIdentifier:@"group.com.crmo.CallKitDemo"];
}

- (IBAction)add:(id)sender {
    BOOL result = [self.manager addPhoneNumber:self.phoneText.text label:self.indtifierText.text];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加结果"
                                                                   message:[NSString stringWithFormat:@"%d", result]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)reload:(id)sender {
    // 先检查设置是否打开
    [self.manager getEnableStatus:^(CXCallDirectoryEnabledStatus enabledStatus, NSError *error) {
        if (error) {
            // CXErrorCodeCallDirectoryManagerError
            [self alertMessage:@"获取权限发生错误"];
            return;
        }
        
        if (enabledStatus == CXCallDirectoryEnabledStatusUnknown) {
            [self alertMessage:@"获取权限-未知状态"];
        } else if (enabledStatus == CXCallDirectoryEnabledStatusDisabled) {
            [self alertMessage:@"请在设置-电话-来电阻止与身份识别中开启权限"];
        } else if (enabledStatus == CXCallDirectoryEnabledStatusEnabled) {
            // 有权限，调用reload
            [self.manager reload:^(NSError *error) {
                if (error) {
                   // CXErrorCodeCallDirectoryManagerError
                    [self alertMessage:@"写入系统错误"];
                } else {
                    [self alertMessage:@"写入系统成功"];
                }
            }];
        }
    }];
}

- (void)alertMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    });
}
@end
