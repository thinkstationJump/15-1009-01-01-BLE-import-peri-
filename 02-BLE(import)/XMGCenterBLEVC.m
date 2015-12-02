//
//  XMGCenterBLEVC.m
//  02-BLE(import)
//
//  Created by xiaomage on 15/10/8.
//  Copyright © 2015年 小码哥. All rights reserved.
//

#import "XMGCenterBLEVC.h"

#import <CoreBluetooth/CoreBluetooth.h>

@interface XMGCenterBLEVC () <CBCentralManagerDelegate, CBPeripheralDelegate>

/** 中心管理者 */
@property (nonatomic, strong) CBCentralManager *cMgr;

/** 连接到的外设 */
@property (nonatomic, strong) CBPeripheral *peripheral;

@end

@implementation XMGCenterBLEVC

- (CBCentralManager *)cMgr
{
    if (!_cMgr) {
        /*
         设置主设备的代理,CBCentralManagerDelegate
         必须实现的：
         - (void)centralManagerDidUpdateState:(CBCentralManager *)central;//主设备状态改变调用，在初始化CBCentralManager的适合会打开设备，只有当设备正确打开后才能使用
         其他选择实现的代理中比较重要的：
         - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI; //找到外设
         - (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;//连接外设成功
         - (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//外设连接失败
         - (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//断开外设
         */
        _cMgr = [[CBCentralManager alloc] initWithDelegate:self
                                                     queue:dispatch_get_main_queue() options:nil];
    }
    return _cMgr;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // 设置标题
    self.title = @"XMGCenterBLEVC";
    // 修改view的背景色,for 美观
#warning 面试小细节
    // iOS5之前的系统时候,在通过照片设置view的背景颜色的时候,用下面方法,有闪屏的bug出现
    // self.view.backgroundColor = [UIColor colorWithPatternImage:(nonnull UIImage *)];
    // 当时是这样解决
    // self.view.layer.contents = (id)[UIImage imageNamed:xxx];
    self.view.backgroundColor = [UIColor orangeColor];
    
    // 调用get方法,先将中心管理者初始化
    [self cMgr];
    
#warning can only accept commands while in the powered on state不能在state非ON的情况下对我们的中心管理者进行操作
    // 搜索外设
    //[self.cMgr scanForPeripheralsWithServices:nil options:nil];
}
// 通常断开连接的操作在此处肯定要进行一次
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // 此处断开连接
    [self yf_dismissConentedWithPeripheral:self.peripheral];
}

#pragma mark - CBCentralManagerDelegate

// 只要中心管理者初始化,就会触发此代理方法
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    /*
     CBCentralManagerStateUnknown = 0,
     CBCentralManagerStateResetting,
     CBCentralManagerStateUnsupported,
     CBCentralManagerStateUnauthorized,
     CBCentralManagerStatePoweredOff,
     CBCentralManagerStatePoweredOn,
     */
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@"CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn:
        {
            NSLog(@"CBCentralManagerStatePoweredOn");
            // 在中心管理者成功开启后再进行一些操作
            // 搜索外设
            [self.cMgr scanForPeripheralsWithServices:nil // 通过某些服务筛选外设
                                              options:nil]; // dict,条件
            // 搜索成功之后,会调用我们找到外设的代理方法
            // - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI; //找到外设

        }
            break;
            
        default:
            break;
    }
}

// 发现外设后调用的方法
- (void)centralManager:(CBCentralManager *)central // 中心管理者
 didDiscoverPeripheral:(CBPeripheral *)peripheral // 外设
     advertisementData:(NSDictionary *)advertisementData // 外设携带的数据
                  RSSI:(NSNumber *)RSSI // 外设发出的蓝牙信号强度
{
    //NSLog(@"%s, line = %d, cetral = %@,peripheral = %@, advertisementData = %@, RSSI = %@", __FUNCTION__, __LINE__, central, peripheral, advertisementData, RSSI);
    
    /*
     peripheral = <CBPeripheral: 0x166668f0 identifier = C69010E7-EB75-E078-FFB4-421B4B951341, Name = "OBand-75", state = disconnected>, advertisementData = {
     kCBAdvDataChannel = 38;
     kCBAdvDataIsConnectable = 1;
     kCBAdvDataLocalName = OBand;
     kCBAdvDataManufacturerData = <4c69616e 0e060678 a5043853 75>;
     kCBAdvDataServiceUUIDs =     (
     FEE7
     );
     kCBAdvDataTxPowerLevel = 0;
     }, RSSI = -55
     根据打印结果,我们可以得到运动手环它的名字叫 OBand-75
     
     */
    
    // 需要对连接到的外设进行过滤
    // 1.信号强度(40以上才连接, 80以上连接)
    // 2.通过设备名(设备字符串前缀是 OBand)
    // 在此时我们的过滤规则是:有OBand前缀并且信号强度大于35
    // 通过打印,我们知道RSSI一般是带-的
    
    if ([peripheral.name hasPrefix:@"OBand"] && (ABS(RSSI.integerValue) > 35)) {
        // 在此处对我们的 advertisementData(外设携带的广播数据) 进行一些处理
        
        // 通常通过过滤,我们会得到一些外设,然后将外设储存到我们的可变数组中,
        // 这里由于附近只有1个运动手环, 所以我们先按1个外设进行处理
        
        // 标记我们的外设,让他的生命周期 = vc
        self.peripheral = peripheral;
        // 发现完之后就是进行连接
        [self.cMgr connectPeripheral:self.peripheral options:nil];
        NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
    }
}

// 中心管理者连接外设成功
- (void)centralManager:(CBCentralManager *)central // 中心管理者
  didConnectPeripheral:(CBPeripheral *)peripheral // 外设
{
    NSLog(@"%s, line = %d, %@=连接成功", __FUNCTION__, __LINE__, peripheral.name);
    // 连接成功之后,可以进行服务和特征的发现
    // 4.1 获取外设的服务们
    // 4.1.1 设置外设的代理
    self.peripheral.delegate = self;
    
    // 4.1.2 外设发现服务,传nil代表不过滤
    // 这里会触发外设的代理方法 - (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
    [self.peripheral discoverServices:nil];
}
// 外设连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%s, line = %d, %@=连接失败", __FUNCTION__, __LINE__, peripheral.name);
}

// 丢失连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%s, line = %d, %@=断开连接", __FUNCTION__, __LINE__, peripheral.name);
}
#pragma mark - 外设代理

// 发现外设的服务后调用的方法
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
    // 判断没有失败
    if (error) {
        NSLog(@"%s, line = %d, error = %@", __FUNCTION__, __LINE__, error.localizedDescription);
        return;
#warning 下面的方法中凡是有error的在实际开发中,都要进行判断
    }
    for (CBService *service in peripheral.services) {
// 发现服务后,让设备再发现服务内部的特征们 didDiscoverCharacteristicsForService
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

// 发现外设服务里的特征的时候调用的代理方法
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
    
    /**
     2015-10-08 16:15:14.708 02-BLE(import)[5210:60b] CBCentralManagerStatePoweredOn
     2015-10-08 16:15:15.719 02-BLE(import)[5210:60b] -[XMGCenterBLEVC centralManager:didDiscoverPeripheral:advertisementData:RSSI:], line = 151
     2015-10-08 16:15:15.722 02-BLE(import)[5210:60b] -[XMGCenterBLEVC centralManager:didDiscoverPeripheral:advertisementData:RSSI:], line = 151
     2015-10-08 16:15:17.784 02-BLE(import)[5210:60b] -[XMGCenterBLEVC centralManager:didConnectPeripheral:], line = 159, OBand-75=连接成功
     2015-10-08 16:15:18.506 02-BLE(import)[5210:60b] -[XMGCenterBLEVC peripheral:didDiscoverServices:], line = 185
     2015-10-08 16:15:18.904 02-BLE(import)[5210:60b] -[XMGCenterBLEVC peripheral:didDiscoverCharacteristicsForService:error:], line = 200
     2015-10-08 16:15:19.189 02-BLE(import)[5210:60b] -[XMGCenterBLEVC peripheral:didDiscoverCharacteristicsForService:error:], line = 200
     2015-10-08 16:15:56.159 02-BLE(import)[5210:60b] -[XMGCenterBLEVC centralManager:didDisconnectPeripheral:error:], line = 178, OBand-75=断开连接
     */
    
    for (CBCharacteristic *cha in service.characteristics) {
        //NSLog(@"%s, line = %d, char = %@", __FUNCTION__, __LINE__, cha);
        // 获取特征对应的描述 didUpdateValueForDescriptor
        [peripheral discoverDescriptorsForCharacteristic:cha];
        // 获取特征的值 didUpdateValueForCharacteristic
        [peripheral readValueForCharacteristic:cha];
        
        
        
    }
}
// 更新特征的value的时候会调用
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
    for (CBDescriptor *descriptor in characteristic.descriptors) {
        // 它会触发
        [peripheral readValueForDescriptor:descriptor];
    }
}
// 更新特征的描述的值的时候会调用
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
    
    
    // 这里当描述的值更新的时候,直接调用此方法即可
    [peripheral readValueForDescriptor:descriptor];
}
// 发现外设的特征的描述数组
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
    
    // 在此处读取描述即可
    for (CBDescriptor *descriptor in characteristic.descriptors) {
        // 它会触发
        [peripheral readValueForDescriptor:descriptor];
    }
}

#pragma mark - 自定义方法
// 一般第三方框架or自定义的方法,可以加前缀与系统自带的方法加以区分.最好还设置一个宏来取消前缀

// 5.外设写数据到特征中

// 需要注意的是特征的属性是否支持写数据
- (void)yf_peripheral:(CBPeripheral *)peripheral didWriteData:(NSData *)data forCharacteristic:(nonnull CBCharacteristic *)characteristic
{
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast												= 0x01,
     CBCharacteristicPropertyRead													= 0x02,
     CBCharacteristicPropertyWriteWithoutResponse									= 0x04,
     CBCharacteristicPropertyWrite													= 0x08,
     CBCharacteristicPropertyNotify													= 0x10,
     CBCharacteristicPropertyIndicate												= 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites								= 0x40,
     CBCharacteristicPropertyExtendedProperties										= 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)		= 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)	= 0x200
     };
     
     打印出特征的权限(characteristic.properties),可以看到有很多种,这是一个NS_OPTIONS的枚举,可以是多个值
     常见的又read,write,noitfy,indicate.知道这几个基本够用了,前俩是读写权限,后俩都是通知,俩不同的通知方式
     */
    NSLog(@"%s, line = %d, char.pro = %d", __FUNCTION__, __LINE__, characteristic.properties);
    // 此时由于枚举属性是NS_OPTIONS,所以一个枚举可能对应多个类型,所以判断不能用 = ,而应该用包含&
    if (characteristic.properties & CBCharacteristicPropertyWrite) {
        // 核心代码在这里
        [peripheral writeValue:data // 写入的数据
             forCharacteristic:characteristic // 写给哪个特征
                          type:CBCharacteristicWriteWithResponse];// 通过此响应记录是否成功写入
    }
}

// 6.通知的订阅和取消订阅
// 实际核心代码是一个方法
// 一般这两个方法要根据产品需求来确定写在何处
- (void)yf_peripheral:(CBPeripheral *)peripheral regNotifyWithCharacteristic:(nonnull CBCharacteristic *)characteristic
{
    // 外设为特征订阅通知 数据会进入 peripheral:didUpdateValueForCharacteristic:error:方法
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
}
- (void)yf_peripheral:(CBPeripheral *)peripheral CancleRegNotifyWithCharacteristic:(nonnull CBCharacteristic *)characteristic
{
    // 外设取消订阅通知 数据会进入 peripheral:didUpdateValueForCharacteristic:error:方法
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}

// 7.断开连接
- (void)yf_dismissConentedWithPeripheral:(CBPeripheral *)peripheral
{
    // 停止扫描
    [self.cMgr stopScan];
    // 断开连接
    [self.cMgr cancelPeripheralConnection:peripheral];
}

@end
