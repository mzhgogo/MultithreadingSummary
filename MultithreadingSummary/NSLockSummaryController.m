//
//  NSLockSummaryController.m
//  MultithreadingSummary
//
//  Created by M on 2018/9/18.
//  Copyright © 2018年 Mgzh. All rights reserved.
//

#import "NSLockSummaryController.h"

@interface NSLockSummaryController ()

@end

@implementation NSLockSummaryController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"线程锁篇";
    
    [self testNSCondition];
}


/**
 @synchronized 取值or赋值 互补干扰；
 当标识相同时，才为满足互斥
 */
- (void)testsynchronized{
    NSMutableArray *tempArr = [NSMutableArray array];
    [tempArr addObject:@"default Value"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized(tempArr){
            NSLog(@"赋值开始 tempArr %@",tempArr);
            [tempArr addObject:@"New Value B"];
            sleep(3);
            [tempArr addObject:@"New Value E"];
            NSLog(@"赋值结束 tempArr %@",tempArr);
        }
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(1);//延时1s，确保在赋值中间进行
        @synchronized(tempArr){
            NSLog(@"取值开始 tempArr %@",tempArr);
            sleep(3);
            [tempArr removeObject:@"default Value"];
            NSLog(@"取值结束 tempArr %@",tempArr);
        }
    });
}

- (void)testdispatch_semaphore{
    NSMutableArray *tempArr = [NSMutableArray array];
    [tempArr addObject:@"default Value"];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"赋值开始 tempArr %@",tempArr);
            sleep(3);
            [tempArr addObject:@"New Value"];
            NSLog(@"赋值结束 tempArr %@",tempArr);
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized(tempArr){
            NSLog(@"取值开始 tempArr %@",tempArr);
            sleep(3);
            [tempArr removeObject:@"default Value"];
            NSLog(@"取值结束 tempArr %@",tempArr);
        }
    });
}

- (void)testNSLock{
    NSMutableArray *tempArr = [NSMutableArray array];
    [tempArr addObject:@"default Value"];
    NSLock *lock = [[NSLock alloc]init];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [lock lock];
        NSLog(@"赋值开始 tempArr %@",tempArr);
        [tempArr addObject:@"New Value B"];
        sleep(3);
        [tempArr addObject:@"New Value E"];
        NSLog(@"赋值结束 tempArr %@",tempArr);
        [lock unlock];
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(1);//延时1s
        [lock lock];//🔐锁住了，会阻塞当前线程
        //tryLock:会尝试加锁，如果锁不可用(已经被锁住)，并不会阻塞线程，并返回NO。
        //lockBeforeDate:方法会在所指定Date之前尝试加锁，如果在指定时间之前都不能加锁，则返回NO。
        NSLog(@"取值开始 tempArr %@",tempArr);
        [tempArr removeObject:@"default Value"];
        sleep(3);
        NSLog(@"取值结束 tempArr %@",tempArr);
        [lock unlock];
    });
}


- (void)testNSConditionLock{
    NSMutableArray *tempArr = [NSMutableArray array];
    NSConditionLock *lock = [[NSConditionLock alloc]init];
    
    NSInteger HAS_DATA = 1;
    NSInteger NO_DATA = 0;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (1) {
            [lock lockWhenCondition:NO_DATA];
            [tempArr addObject:[[NSObject alloc] init]];
            NSLog(@"数组总量:%zi",tempArr.count);
            [lock unlockWithCondition:HAS_DATA];
            sleep(1);
        }
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (1) {
            NSLog(@"wait for product");
            [lock lockWhenCondition:HAS_DATA];
            [tempArr removeObjectAtIndex:0];
            NSLog(@"custome a product");
            [lock unlockWithCondition:NO_DATA];
        }
    });
}

- (void)testNSCondition{
    NSCondition *condition = [[NSCondition alloc] init];
    NSMutableArray *products = [NSMutableArray array];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (1) {
            NSLog(@"减去锁之前！！！");
            [condition lock];
            NSLog(@"减去锁之后！！！");
            if ([products count] == 0) {
                NSLog(@"wait for product");
                [condition wait];
            }
            [products removeObjectAtIndex:0];
            NSLog(@"custome a product");
            [condition unlock];
        }
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);//延时1s执行
        while (1) {
            NSLog(@"添加锁之前！！！");
            [condition lock];
            NSLog(@"添加锁之后！！！");
            [products addObject:[[NSObject alloc] init]];
            NSLog(@"produce a product,总量:%zi",products.count);
            [condition signal];
            [condition unlock];
            sleep(1);
        }
        
    });
    
}

- (void)testNSRecursiveLock{
    NSRecursiveLock *lock = [[NSRecursiveLock alloc] init];
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        static void (^RecursiveMethod)(int);
        RecursiveMethod = ^(int value) {
            [lock lock];
            if (value > 0) {
                
                NSLog(@"value = %d", value);
                sleep(1);
                RecursiveMethod(value - 1);
            }
            [lock unlock];
        };
        RecursiveMethod(5);
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
