//
//  XMGPeripheralBLEVC.m
//  02-BLE(import)
//
//  Created by xiaomage on 15/10/8.
//  Copyright © 2015年 小码哥. All rights reserved.
//

#import "XMGPeripheralBLEVC.h"
#import <CoreBluetooth/CoreBluetooth.h>

static NSString *const Service1StrUUID = @"FFF0";
static NSString *const Service2StrUUID = @"FFE0";

static NSString *const notiyCharacteristicStrUUID = @"FFF1";
static NSString *const readwriteCharacteristicStrUUID = @"FFF2";
static NSString *const readCharacteristicStrUUID = @"FFE1";

static NSString *const LocalNameKey = @"XMGPeripheral";

@interface XMGPeripheralBLEVC () <CBPeripheralManagerDelegate>

/** 外设管理者 */
@property (nonatomic, strong) CBPeripheralManager *pMgr;

/** 定时器 */
@property (nonatomic, weak) NSTimer *timer;

@end

@implementation XMGPeripheralBLEVC
{
    CBPeripheralManager *_pMgr;
}

- (CBPeripheralManager *)pMgr
{
    if (!_pMgr) {
        _pMgr = [[CBPeripheralManager alloc] initWithDelegate:self
                                                        queue:dispatch_get_main_queue()
                                                      options:nil];
    }
    return _pMgr;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 调用get方法初始化,初始化后CBPeripheralManager状态改变会调用代理方法peripheralManagerDidUpdateState:
    // 模拟器永远也不会是CBPeripheralManagerStatePoweredOn状态
    [self pMgr];
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    /*
     typedef NS_ENUM(NSInteger, CBPeripheralManagerState) {
     CBPeripheralManagerStateUnknown = 0,
     CBPeripheralManagerStateResetting,
     CBPeripheralManagerStateUnsupported,
     CBPeripheralManagerStateUnauthorized,
     CBPeripheralManagerStatePoweredOff,
     CBPeripheralManagerStatePoweredOn,
     } NS_ENUM_AVAILABLE(NA, 6_0);
     */
    
    // 在开发中,NS_ENUM是可以直接用 == 号判断的,NS_OPTIONS类型的枚举要用&(包含)判断
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        // 如果是on的话,才会对它进行操作
        // 设置外设管理者中的内容(服务...)
        [self setupPMgr];
    }else
    {
        NSLog(@"not ON");
    }
}

// 外设管理者在添加服务的时候会调用此方法,(方法调用的次数与添加的服务数量相关)
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSLog(@"%s, line = %d, error = %@", __FUNCTION__, __LINE__, error.localizedDescription);
        return;
    }
    // 需要所有的服务添加完,然后再开启广播,此处由于只添加了1个服务,所以直接在代码中可以写执行
    // 实际开发中,需要结合笔记做一下判断的操作
    // CBAdvertisementDataLocalNameKey是由硬件产品决定的
    // CBAdvertisementDataServiceUUIDsKey此处的内容是所有服务的UUID,数组最好是通过可变数组中存储的已经添加的服务数组来确定(KVC)
    NSDictionary *adverInfo =@{CBAdvertisementDataLocalNameKey: LocalNameKey,
                               CBAdvertisementDataServiceUUIDsKey:@[[CBUUID UUIDWithString:Service1StrUUID]]};
    // 触发开启广播的代理方法 peripheralManagerDidStartAdvertising
    [peripheral startAdvertising:adverInfo];
    
}
// 开始广播后回触发的代理
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
}



/**.......>>>>>>>>>与中心管理者交互的一些方法 */
// 外设收到读的请求,然后读特征的值赋值给request
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
    // 判断是否可读
    if (request.characteristic.properties & CBCharacteristicPropertyRead) {
        NSData *data = request.characteristic.value;
        
        request.value = data;
        // 对请求成功做出响应
        [self.pMgr respondToRequest:request withResult:CBATTErrorSuccess];
    }else
    {
#warning 笔记中有误
        [self.pMgr respondToRequest:request withResult:CBATTErrorReadNotPermitted];
    }
}
// 外设收到写的请求,然后读request的值,写给特征
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests
{
    NSLog(@"%s, line = %d, requests = %@", __FUNCTION__, __LINE__, requests);
    CBATTRequest *request = requests.firstObject;
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        NSData *data = request.value;
        // 此处赋值要转类型,否则报错
        CBMutableCharacteristic *mChar = (CBMutableCharacteristic *)request.characteristic;
        mChar.value = data;
        // 对请求成功做出响应
        [self.pMgr respondToRequest:request withResult:CBATTErrorSuccess];
    }else
    {
        [self.pMgr respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}


// 与CBCentral的交互
// 订阅特征
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"%s, line = %d, 订阅了%@的数据", __FUNCTION__, __LINE__, characteristic.UUID);
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                      target:self
                                                    selector:@selector(yf_sendData:)
                                                    userInfo:characteristic
                                                     repeats:YES];
    
    self.timer = timer;
    
    /* 另一种方法 */
    //    NSTimer *testTimer = [NSTimer timerWithTimeInterval:2.0
    //                                                 target:self
    //                                               selector:@selector(yf_sendData:)
    //                                               userInfo:characteristic
    //                                                repeats:YES];
    //    [[NSRunLoop currentRunLoop] addTimer:testTimer forMode:NSDefaultRunLoopMode];
    
}
// 取消订阅特征
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"%s, line = %d, 取消订阅了%@的数据", __FUNCTION__, __LINE__, characteristic.UUID);
    [self.timer invalidate];
    self.timer = nil;
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
}



#pragma mark - 私有方法
- (void)setupPMgr
{
    // 5.根据硬件工程师提供的信息来确定UUID
    
    // 4.创建特征的描述
    CBMutableDescriptor *desT = [[CBMutableDescriptor alloc] initWithType:[CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString]
                                                                    value:@"1v1class"];
    
    // 3.创建特征(服务的特征)
    CBMutableCharacteristic *cha0 = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:readCharacteristicStrUUID]
                                                                      properties:CBCharacteristicPropertyRead
                                                                           value:nil // 此处它的值也是硬件工程师确定
                                                                      permissions:CBAttributePermissionsReadable];
    cha0.descriptors = @[desT];
    // 2.设置添加到外设管理者中的服务
    // 首先想到外设的内部结构
    // 通常UUID都是硬件工程师确定的
    CBUUID *ser0UUID = [CBUUID UUIDWithString:Service1StrUUID];
    CBMutableService *ser0 = [[CBMutableService alloc] initWithType:ser0UUID primary:YES];
    ser0.characteristics = @[cha0];
    // 1.添加服务到外设管理者中
    // 在添加服务的时候,会触发代理方法 peripheralManager: didAddService:
    [self.pMgr addService:ser0];
}



// 计时器每隔两秒调用的方法
- (BOOL)yf_sendData:(NSTimer *)timer
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yy:MM:dd:HH:mm:ss";
    
    NSString *now = [dateFormatter stringFromDate:[NSDate date]];
    NSLog(@"now = %@", now);
    
    // 执行回应central通知数据
    return  [self.pMgr updateValue:[now dataUsingEncoding:NSUTF8StringEncoding]
                 forCharacteristic:timer.userInfo
              onSubscribedCentrals:nil];
}
@end
