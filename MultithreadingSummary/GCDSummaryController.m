//
//  GCDSummaryController.m
//  MultithreadingSummary
//
//  Created by M gzh on 2018/6/3.
//  Copyright © 2018年 Mgzh. All rights reserved.
//

#import "GCDSummaryController.h"

@interface GCDSummaryController ()

@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation GCDSummaryController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //    [self testGCDGroupApi2:3];
    [self testGCDTimeApi];
}

#pragma mark 1、创建队列
- (void)testGCDQueueCreate{
    //******主队列-属于串行队列   用于刷新 UI，任何需要刷新 UI 的工作都要在主队列执行，所以一般耗时的任务都要放到别的线程执行。
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    //******全局并行队列  并行任务一般都加入到这个队列。这是系统提供的一个并发队列。
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //******自己创建的队列
    //串行队列
    dispatch_queue_t serialQueue1 = dispatch_queue_create("com.mgzh.MultithreadingSummary.001", NULL);
    dispatch_queue_t serialQueue2 = dispatch_queue_create("com.mgzh.MultithreadingSummary.002", DISPATCH_QUEUE_SERIAL);
    //并行队列
    dispatch_queue_t concurrentQueue3 = dispatch_queue_create("com.mgzh.MultithreadingSummary.003", DISPATCH_QUEUE_CONCURRENT);
    //自定义优先级的队列 参数1并发or串行 参数2优先级 参数3大于0或者小于QOS_MIN_RELATIVE_PRIORITY返回NULL
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
    dispatch_queue_t customPriorityQueue4 = dispatch_queue_create("com.mgzh.MultithreadingSummary.004", attr);
}

//把多种队列加入指定类型队列中，按指定类型队列类型执行  ps：多个串行queue之间为并行执行
- (void)testGCDQueueDemo1{
    dispatch_queue_t targetSerialQueue = dispatch_queue_create("com.mgzh.MultithreadingSummary.001", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t serialQueue1 = dispatch_queue_create("com.mgzh.MultithreadingSummary.002", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t concurrentQueue2 = dispatch_queue_create("com.mgzh.MultithreadingSummary.003", DISPATCH_QUEUE_CONCURRENT);
    //设置参考
    dispatch_set_target_queue(serialQueue1, targetSerialQueue);
    dispatch_set_target_queue(concurrentQueue2, targetSerialQueue);
    
    dispatch_async(concurrentQueue2, ^{
        NSLog(@"job1 in");
        sleep(2);
        NSLog(@"job1 out");
    });
    dispatch_async(concurrentQueue2, ^{
        NSLog(@"job2 in");
        sleep(2);
        NSLog(@"job2 out");
    });
    dispatch_async(serialQueue1, ^{
        NSLog(@"job3 in");
        sleep(2);
        NSLog(@"job3 out");
    });
    
}

#pragma mark - 屏障/栅栏函数
//仅当是自己创建的并发队列时有效！！;同步会阻塞当前线程，异步则不会，对其队列中queue中上下任务无影响
- (void)testGCDBarrierApi{
    //    dispatch_queue_t testQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //    dispatch_queue_t testQueue = dispatch_queue_create("com.mgzh.MultithreadingSummary.002", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t testQueue = dispatch_queue_create("com.mgzh.MultithreadingSummary.003", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(testQueue, ^{
        NSLog(@"1");
        sleep(2);
        NSLog(@"11");
    });
    dispatch_async(testQueue, ^{
        NSLog(@"2");
        sleep(2);
        NSLog(@"22");
    });
    dispatch_barrier_sync(testQueue, ^{
        NSLog(@"3");
        sleep(2);
        NSLog(@"33");
    });
    NSLog(@"是否会阻塞当前线程");
    dispatch_async(testQueue, ^{
        NSLog(@"44");
    });
}

#pragma mark - 队列组操作函数

/**
 队列组可以将很多队列添加到一个组里，这样做的好处是，当这个组里所有的任务都执行完了，队列组会通过一个方法通知我们
 在dispatch_group_async内执行的任务可以通过dispatch_group_notify监听执行结果
 dispatch_group_notify 为异步执行，不会阻塞当前线程；它会等待所有任务执行完毕后 block才会执行
 dispatch_group_wait 为同步等待，会阻塞当前线程（当group上任务在指定时间内完成->[返回值为0] 或者超过设置的超时时间->返[回值为non-zero] 会结束等待往下执行）
 */
- (void)testGCDGroupApi1:(NSInteger)imageCount{
    NSMutableArray *resultArr=[NSMutableArray array];
    for (NSInteger i=0; i<imageCount; i++) {
        [resultArr addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"",@"imgUrl", nil]];
    }
    
    dispatch_queue_t sysGlobalQuue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t groupQueue = dispatch_group_create();
    
    for (NSInteger i=0; i<imageCount; i++) {
        dispatch_group_async(groupQueue, sysGlobalQuue, ^{
            int sleepTime = [self getRandomNumber:1 to:4];
            sleep(sleepTime);
            NSLog(@"%@后请求成功 %@",@(sleepTime),@(i));
            [resultArr replaceObjectAtIndex:i withObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@url",@(i)],@"imgUrl", nil]];
        });
    }
    dispatch_group_notify(groupQueue, sysGlobalQuue, ^{
        NSLog(@"任务结束 %@",resultArr);
    });
    NSLog(@"notify 之后执行");
    long groupWait = dispatch_group_wait(groupQueue, dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC));
    NSLog(@"group wait 之后执行 %@",@(groupWait));
}

/**
 当要执行的任务不能在dispatch_group_async内执行时，如使用Afnetwroking网络请求，则可以通过dispatch_group_enter、dispatch_group_leave来
 实现任务通知
 */
- (void)testGCDGroupApi2:(NSInteger)imageCount{
    NSMutableArray *resultArr=[NSMutableArray array];
    for (NSInteger i=0; i<imageCount; i++) {
        [resultArr addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"",@"imgUrl", nil]];
    }
    
    dispatch_queue_t sysGlobalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t groupQueue = dispatch_group_create();
    
    for (NSInteger i=0; i<imageCount; i++) {
        dispatch_group_enter(groupQueue);
        dispatch_async(sysGlobalQueue, ^{
            int sleepTime = [self getRandomNumber:1 to:4];
            sleep(sleepTime);
            NSLog(@"%@后请求成功 %@",@(sleepTime),@(i));
            [resultArr replaceObjectAtIndex:i withObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@url",@(i)],@"imgUrl", nil]];
            dispatch_group_leave(groupQueue);
        });
    }
    dispatch_group_notify(groupQueue, sysGlobalQueue, ^{
        NSLog(@"任务结束 %@",resultArr);
    });
    //不让它阻塞当前线程
    dispatch_async(sysGlobalQueue, ^{
        long groupWait = dispatch_group_wait(groupQueue, dispatch_time(DISPATCH_TIME_NOW, 10*NSEC_PER_SEC));
        NSLog(@"group wait 之后执行 %@",@(groupWait));
    });
}

#pragma mark - GCD Source 函数
/**
 定时器
 2018-06-03 19:15:35.703434+0800 MultithreadingSummary[10146:337240] 现在秒 2
 2018-06-03 19:15:36.667909+0800 MultithreadingSummary[10146:337240] 现在秒 1
 2018-06-03 19:15:37.667722+0800 MultithreadingSummary[10146:337240] 现在秒 0
 2018-06-03 19:15:38.668666+0800 MultithreadingSummary[10146:337276] end <NSThread: 0x60000046dc40>{number = 3, name = (null)}
 */
- (void)testGCDSourceTimer{
    __block NSInteger timeOut = 3 ;
    //参数type：dispatch源可处理的事件  参数handle：可以理解为句柄、索引或id，假如要监听进程，需要传入进程的ID 参数mask：可以理解为描述，提供更详细的描述，让它知道具体要监听什么
    dispatch_source_t sourceQueue = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
    dispatch_source_set_timer(sourceQueue, dispatch_walltime(NULL, 0), 1.0*NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(sourceQueue, ^{
        if (timeOut<=0) {
            dispatch_source_cancel(sourceQueue);
            NSLog(@"end %@",[NSThread currentThread]);
        }else{
            timeOut --;
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"现在秒 %@",@(timeOut));
            });
        }
    });
    dispatch_resume(sourceQueue);
}

/**
 进度条系列
 2018-06-03 19:32:55.942558+0800 MultithreadingSummary[10496:350182] 线程：<NSThread: 0x60000026d300>{number = 3, name = (null)}~~~~~~~~i = 0
 2018-06-03 19:32:55.942779+0800 MultithreadingSummary[10496:350183] 线程：<NSThread: 0x604000669880>{number = 4, name = (null)}~~~~~~~~i = 1
 2018-06-03 19:32:55.942912+0800 MultithreadingSummary[10496:350185] 线程：<NSThread: 0x60000026d340>{number = 6, name = (null)}~~~~~~~~i = 3
 2018-06-03 19:32:55.942922+0800 MultithreadingSummary[10496:350186] 线程：<NSThread: 0x60000026cc40>{number = 5, name = (null)}~~~~~~~~i = 2
 2018-06-03 19:32:55.942997+0800 MultithreadingSummary[10496:350212] 线程：<NSThread: 0x60000026d3c0>{number = 7, name = (null)}~~~~~~~~i = 4
 2018-06-03 19:32:55.943070+0800 MultithreadingSummary[10496:350213] 线程：<NSThread: 0x60000026d440>{number = 8, name = (null)}~~~~~~~~i = 5
 2018-06-03 19:32:55.943095+0800 MultithreadingSummary[10496:350214] 线程：<NSThread: 0x604000669a40>{number = 9, name = (null)}~~~~~~~~i = 6
 2018-06-03 19:32:55.943119+0800 MultithreadingSummary[10496:350215] 线程：<NSThread: 0x60000026d480>{number = 10, name = (null)}~~~~~~~~i = 7
 2018-06-03 19:32:55.943168+0800 MultithreadingSummary[10496:350216] 线程：<NSThread: 0x60000026d5c0>{number = 11, name = (null)}~~~~~~~~i = 8
 2018-06-03 19:32:55.943225+0800 MultithreadingSummary[10496:350217] 线程：<NSThread: 0x604000669cc0>{number = 12, name = (null)}~~~~~~~~i = 9
 2018-06-03 19:32:55.943186+0800 MultithreadingSummary[10496:350184] beforeTotal 0 dataValue 8 进度百分比 0.2666666666666667
 2018-06-03 19:32:55.943250+0800 MultithreadingSummary[10496:350218] 线程：<NSThread: 0x60000026d540>{number = 13, name = (null)}~~~~~~~~i = 10
 2018-06-03 19:32:55.943294+0800 MultithreadingSummary[10496:350220] 线程：<NSThread: 0x60000026d680>{number = 14, name = (null)}~~~~~~~~i = 12
 2018-06-03 19:32:55.943312+0800 MultithreadingSummary[10496:350219] 线程：<NSThread: 0x60000026d6c0>{number = 15, name = (null)}~~~~~~~~i = 11
 2018-06-03 19:32:55.943427+0800 MultithreadingSummary[10496:350182] 线程：<NSThread: 0x60000026d300>{number = 3, name = (null)}~~~~~~~~i = 13
 2018-06-03 19:32:55.943445+0800 MultithreadingSummary[10496:350183] 线程：<NSThread: 0x604000669880>{number = 4, name = (null)}~~~~~~~~i = 14
 2018-06-03 19:32:55.943545+0800 MultithreadingSummary[10496:350185] 线程：<NSThread: 0x60000026d340>{number = 6, name = (null)}~~~~~~~~i = 15
 2018-06-03 19:32:55.943588+0800 MultithreadingSummary[10496:350186] 线程：<NSThread: 0x60000026cc40>{number = 5, name = (null)}~~~~~~~~i = 16
 2018-06-03 19:32:55.943666+0800 MultithreadingSummary[10496:350212] 线程：<NSThread: 0x60000026d3c0>{number = 7, name = (null)}~~~~~~~~i = 17
 2018-06-03 19:32:55.943876+0800 MultithreadingSummary[10496:350221] 线程：<NSThread: 0x60000026d900>{number = 16, name = (null)}~~~~~~~~i = 18
 2018-06-03 19:32:55.943909+0800 MultithreadingSummary[10496:350213] 线程：<NSThread: 0x60000026d440>{number = 8, name = (null)}~~~~~~~~i = 19
 2018-06-03 19:32:55.943962+0800 MultithreadingSummary[10496:350222] 线程：<NSThread: 0x60400066a2c0>{number = 17, name = (null)}~~~~~~~~i = 21
 2018-06-03 19:32:55.943936+0800 MultithreadingSummary[10496:350214] 线程：<NSThread: 0x604000669a40>{number = 9, name = (null)}~~~~~~~~i = 20
 2018-06-03 19:32:55.944269+0800 MultithreadingSummary[10496:350223] 线程：<NSThread: 0x60000026de40>{number = 18, name = (null)}~~~~~~~~i = 22
 2018-06-03 19:32:55.944335+0800 MultithreadingSummary[10496:350224] 线程：<NSThread: 0x60000026df00>{number = 19, name = (null)}~~~~~~~~i = 23
 2018-06-03 19:32:55.944357+0800 MultithreadingSummary[10496:350225] 线程：<NSThread: 0x60000026df40>{number = 20, name = (null)}~~~~~~~~i = 24
 2018-06-03 19:32:55.944425+0800 MultithreadingSummary[10496:350226] 线程：<NSThread: 0x60000026dfc0>{number = 21, name = (null)}~~~~~~~~i = 25
 2018-06-03 19:32:55.944529+0800 MultithreadingSummary[10496:350227] 线程：<NSThread: 0x60000026e040>{number = 22, name = (null)}~~~~~~~~i = 26
 2018-06-03 19:32:55.944569+0800 MultithreadingSummary[10496:350228] 线程：<NSThread: 0x60000026e0c0>{number = 23, name = (null)}~~~~~~~~i = 27
 2018-06-03 19:32:55.944627+0800 MultithreadingSummary[10496:350229] 线程：<NSThread: 0x604000669d40>{number = 24, name = (null)}~~~~~~~~i = 28
 2018-06-03 19:32:55.944655+0800 MultithreadingSummary[10496:350230] 线程：<NSThread: 0x60000026e140>{number = 25, name = (null)}~~~~~~~~i = 29
 2018-06-03 19:32:55.945655+0800 MultithreadingSummary[10496:350184] beforeTotal 8 dataValue 22 进度百分比 1
 */
- (void)testGCDSourceMergeData{
    __block NSUInteger totalComplete = 0;
    dispatch_source_t sourceQueue = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_global_queue(0, 0));
    dispatch_source_set_event_handler(sourceQueue, ^{
        NSUInteger dataValue = dispatch_source_get_data(sourceQueue);
        NSInteger beforeTotal = totalComplete;
        totalComplete += dataValue;
        NSLog(@"beforeTotal %@ dataValue %@ 进度百分比 %@",@(beforeTotal),@(dataValue),@((CGFloat)totalComplete/30));
    });
    dispatch_resume(sourceQueue);
    for (NSInteger i=0; i<30; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            dispatch_source_merge_data(sourceQueue, 1);
            NSLog(@"线程：%@~~~~~~~~i = %@", [NSThread currentThread],@(i));
        });
    }
}

#pragma mark - GCD Block
/**
 可以监听block任务执行的情况，如执行完毕之后的通知，超时未完成之后处理等
 其dispatch_block_notify、dispatch_block_wait 与 GCDGroup功能一样
 */
- (void)testGCDBlockApi{
    dispatch_queue_t sysGlobalQueue = dispatch_get_global_queue(0, 0);
    dispatch_block_t gcdBlock = dispatch_block_create(0, ^{
        sleep(2);
        NSLog(@"do something done %@",[NSThread currentThread]);
    });
    dispatch_async(sysGlobalQueue, gcdBlock);
    //创建自定义优先级等block
    //    dispatch_block_t customGCDBlock = dispatch_block_create_with_qos_class(0, QOS_CLASS_DEFAULT, 0, ^{
    //        sleep(3);
    //        NSLog(@"do something done %@",[NSThread currentThread]);
    //    });
    //    dispatch_async(sysGlobalQueue, customGCDBlock);
    dispatch_block_notify(gcdBlock, sysGlobalQueue, ^{
        NSLog(@"notify");
    });
    NSLog(@"notify 之后");
    //不让它阻塞当前线程
    dispatch_async(sysGlobalQueue, ^{
        long blockWait = dispatch_block_wait(gcdBlock, dispatch_time(DISPATCH_TIME_NOW, 5*NSEC_PER_SEC));
        NSLog(@"wait 之后 %@",@(blockWait));
    });
}

#pragma mark - 信号量
/**
 dispatch_semaphore_t 声明必须为全局的，要不然发送信号量的地方获取不到
 */
- (void)testGCDSignalApi{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(5);
        NSLog(@"发送信号");
        dispatch_semaphore_signal(self.semaphore);
    });
    NSLog(@"开始任务111");
    self.semaphore = dispatch_semaphore_create(0);
    NSLog(@"开始任务222");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"可以执行");
}

#pragma mark - 延时添加函数
/**
 dispatch_after 并不是延时之后立即执行，而是延时之后立即提交block；如果提交的队列中有还未执行完的任务，那么提交的block需要等待之后才能执行
 */
- (void)testGCDAfterApi1{
    NSLog(@"beagin show");
    dispatch_async(dispatch_get_main_queue(), ^{
        sleep(5);
        NSLog(@"耗时操作执行完毕");
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"延时block执行了");
    });
}
- (void)testGCDAfterApi2{
    dispatch_queue_t serialQueue = dispatch_queue_create("com.mgzh.MultithreadingSummary.001", DISPATCH_QUEUE_SERIAL);
    NSLog(@"beagin show");
    dispatch_async(serialQueue, ^{
        sleep(5);
        NSLog(@"第一个block 执行完毕");
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), serialQueue, ^{
        NSLog(@"延时block执行了");
    });
}

#pragma mark - 只执行一次函数
/**
 多次调用，只执行一次； ！！！dispatch_once_t 声明必须为全局或静态变量！！！
 */
- (void)testGCDOnceApi{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"我被执行了");
    });
}

#pragma mark - GCD time
/**
 2018-06-03 19:49:47.118081+0800 MultithreadingSummary[10814:361479] begin
 2018-06-03 19:49:49.119992+0800 MultithreadingSummary[10814:361479] execute block
 */
- (void)testGCDTimeApi{
    //
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC);
    //第一个参数是一个结构体, 创建的是一个绝对的时间点,比如 2016年10月10日8点30分30秒, 如果你不需要自某一个特定的时刻开始,可以传 NUll,表示自动获取当前时区的当前时间作为开始时刻,
    dispatch_time_t wallTime = dispatch_walltime(0, 2*NSEC_PER_SEC);
    NSLog(@"begin");
    dispatch_after(wallTime, dispatch_get_main_queue(), ^{
        NSLog(@"execute block");
    });
}

#pragma mark - 串行、并行 + 同步、异步 测试【同步阻塞当前队列、异步不会阻塞当前队列】
/**
 主队列同步
 
 2018-06-03 17:42:48.772026+0800 MultithreadingSummary[8666:272724] beagin <NSThread: 0x60000007c780>{number = 1, name = main}
 (lldb) -- 卡死
 */
- (void)testGCDSyncMainQueue{
    NSLog(@"beagin %@",[NSThread currentThread]);
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"task %@",[NSThread currentThread]);
    });
    NSLog(@"end %@",[NSThread currentThread]);
}

/**
 串行队列同步  在主线程执行，阻塞当前(主main)线程；没有卡死
 2018-06-03 17:49:13.850796+0800 MultithreadingSummary[8799:278023] beagin <NSThread: 0x60400007bdc0>{number = 1, name = main}
 2018-06-03 17:49:13.850988+0800 MultithreadingSummary[8799:278023] task1 int <NSThread: 0x60400007bdc0>{number = 1, name = main}
 2018-06-03 17:49:15.852525+0800 MultithreadingSummary[8799:278023] task1 out <NSThread: 0x60400007bdc0>{number = 1, name = main}
 2018-06-03 17:49:15.852880+0800 MultithreadingSummary[8799:278023] task2 int <NSThread: 0x60400007bdc0>{number = 1, name = main}
 2018-06-03 17:49:17.853647+0800 MultithreadingSummary[8799:278023] task2 out <NSThread: 0x60400007bdc0>{number = 1, name = main}
 2018-06-03 17:49:17.854004+0800 MultithreadingSummary[8799:278023] end <NSThread: 0x60400007bdc0>{number = 1, name = main}
 */
- (void)testGCDSyncSerialQueue{
    NSLog(@"beagin %@",[NSThread currentThread]);
    dispatch_queue_t serialQueue = dispatch_queue_create("com.mgzh.MultithreadingSummary.008", DISPATCH_QUEUE_SERIAL);
    dispatch_sync(serialQueue, ^{
        NSLog(@"task1 int %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"task1 out %@",[NSThread currentThread]);
    });
    dispatch_sync(serialQueue, ^{
        NSLog(@"task2 int %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"task2 out %@",[NSThread currentThread]);
    });
    NSLog(@"end %@",[NSThread currentThread]);
}

/**
 并行队列同步  在主线程执行，阻塞当前(主main)线程；按顺序执行，和串行队列执行无区别
 2018-06-03 17:50:56.944494+0800 MultithreadingSummary[8848:279783] beagin <NSThread: 0x60000007fcc0>{number = 1, name = main}
 2018-06-03 17:50:56.944692+0800 MultithreadingSummary[8848:279783] task1 int <NSThread: 0x60000007fcc0>{number = 1, name = main}
 2018-06-03 17:50:58.946193+0800 MultithreadingSummary[8848:279783] task1 out <NSThread: 0x60000007fcc0>{number = 1, name = main}
 2018-06-03 17:50:58.946561+0800 MultithreadingSummary[8848:279783] task2 int <NSThread: 0x60000007fcc0>{number = 1, name = main}
 2018-06-03 17:51:00.948116+0800 MultithreadingSummary[8848:279783] task2 out <NSThread: 0x60000007fcc0>{number = 1, name = main}
 2018-06-03 17:51:00.948479+0800 MultithreadingSummary[8848:279783] end <NSThread: 0x60000007fcc0>{number = 1, name = main}
 */
- (void)testGCDSyncConCurrentQueue{
    NSLog(@"beagin %@",[NSThread currentThread]);
    //系统和自定义测试结果一样
    dispatch_queue_t conCurrentQueue = dispatch_queue_create("com.mgzh.MultithreadingSummary.008", DISPATCH_QUEUE_CONCURRENT);
//    dispatch_queue_t conCurrentQueue = dispatch_get_global_queue(0, 0);
    dispatch_sync(conCurrentQueue, ^{
        NSLog(@"task1 int %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"task1 out %@",[NSThread currentThread]);
    });
    dispatch_sync(conCurrentQueue, ^{
        NSLog(@"task2 int %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"task2 out %@",[NSThread currentThread]);
    });
    NSLog(@"end %@",[NSThread currentThread]);
}

/**
 主队列异步  不会阻塞当前(主main)线程；注意！！！ 没有开启子线程！！！ 结论 异步并不一定开启子线程
 2018-06-03 18:01:14.520631+0800 MultithreadingSummary[9041:288072] beagin <NSThread: 0x6040000798c0>{number = 1, name = main}
 2018-06-03 18:01:14.520894+0800 MultithreadingSummary[9041:288072] end <NSThread: 0x6040000798c0>{number = 1, name = main}
 2018-06-03 18:01:14.555994+0800 MultithreadingSummary[9041:288072] task1 int <NSThread: 0x6040000798c0>{number = 1, name = main}
 2018-06-03 18:01:16.557027+0800 MultithreadingSummary[9041:288072] task1 out <NSThread: 0x6040000798c0>{number = 1, name = main}
 2018-06-03 18:01:16.557234+0800 MultithreadingSummary[9041:288072] task2 int <NSThread: 0x6040000798c0>{number = 1, name = main}
 2018-06-03 18:01:18.558694+0800 MultithreadingSummary[9041:288072] task2 out <NSThread: 0x6040000798c0>{number = 1, name = main}
 */
- (void)testGCDAsyncMainQueue{
    NSLog(@"beagin %@",[NSThread currentThread]);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"task1 int %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"task1 out %@",[NSThread currentThread]);
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"task2 int %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"task2 out %@",[NSThread currentThread]);
    });
    NSLog(@"end %@",[NSThread currentThread]);
}

/**
 串行队列异步执行  不会阻塞当前线程；任务按照顺序执行 耗时4s 无节约时间
 2018-06-03 17:53:01.516737+0800 MultithreadingSummary[8907:281838] beagin <NSThread: 0x604000072e00>{number = 1, name = main}
 2018-06-03 17:53:01.516993+0800 MultithreadingSummary[8907:281838] end <NSThread: 0x604000072e00>{number = 1, name = main}
 2018-06-03 17:53:01.517036+0800 MultithreadingSummary[8907:281894] task1 int <NSThread: 0x60400027cdc0>{number = 3, name = (null)}
 2018-06-03 17:53:03.521877+0800 MultithreadingSummary[8907:281894] task1 out <NSThread: 0x60400027cdc0>{number = 3, name = (null)}
 2018-06-03 17:53:03.522273+0800 MultithreadingSummary[8907:281894] task2 int <NSThread: 0x60400027cdc0>{number = 3, name = (null)}
 2018-06-03 17:53:05.527824+0800 MultithreadingSummary[8907:281894] task2 out <NSThread: 0x60400027cdc0>{number = 3, name = (null)}
 */
- (void)testGCDAsyncSerialQueue{
    NSLog(@"beagin %@",[NSThread currentThread]);
    dispatch_queue_t serialQueue = dispatch_queue_create("com.mgzh.MultithreadingSummary.008", DISPATCH_QUEUE_SERIAL);
    dispatch_async(serialQueue, ^{
        NSLog(@"task1 int %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"task1 out %@",[NSThread currentThread]);
    });
    dispatch_async(serialQueue, ^{
        NSLog(@"task2 int %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"task2 out %@",[NSThread currentThread]);
    });
    NSLog(@"end %@",[NSThread currentThread]);
}

/**
 并行队列异步执行 任务同步执行，耗时2s 节约时间！
 2018-06-03 18:04:23.297574+0800 MultithreadingSummary[9107:290700] beagin <NSThread: 0x604000073fc0>{number = 1, name = main}
 2018-06-03 18:04:23.297814+0800 MultithreadingSummary[9107:290700] end <NSThread: 0x604000073fc0>{number = 1, name = main}
 2018-06-03 18:04:23.297852+0800 MultithreadingSummary[9107:290748] task1 int <NSThread: 0x60400047e200>{number = 3, name = (null)}
 2018-06-03 18:04:23.297854+0800 MultithreadingSummary[9107:290879] task2 int <NSThread: 0x600000262500>{number = 4, name = (null)}
 2018-06-03 18:04:25.299541+0800 MultithreadingSummary[9107:290879] task2 out <NSThread: 0x600000262500>{number = 4, name = (null)}
 2018-06-03 18:04:25.299541+0800 MultithreadingSummary[9107:290748] task1 out <NSThread: 0x60400047e200>{number = 3, name = (null)}
 */
- (void)testGCDAsyncConCurrentQueue{
    NSLog(@"beagin %@",[NSThread currentThread]);
    //系统和自定义测试结果一样
    dispatch_queue_t conCurrentQueue = dispatch_queue_create("com.mgzh.MultithreadingSummary.008", DISPATCH_QUEUE_CONCURRENT);
    //    dispatch_queue_t conCurrentQueue = dispatch_get_global_queue(0, 0);
    dispatch_async(conCurrentQueue, ^{
        NSLog(@"task1 int %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"task1 out %@",[NSThread currentThread]);
    });
    dispatch_async(conCurrentQueue, ^{
        NSLog(@"task2 int %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"task2 out %@",[NSThread currentThread]);
    });
    NSLog(@"end %@",[NSThread currentThread]);
}

#pragma mark - 多线程死锁
/**
 2018-06-03 17:42:48.772026+0800 MultithreadingSummary[8666:272724] beagin <NSThread: 0x60000007c780>{number = 1, name = main}
 (lldb) -- 卡死
 */
- (void)testGCDeadLockDemo0{
    NSLog(@"beagin %@",[NSThread currentThread]);
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"task %@",[NSThread currentThread]);
    });
    NSLog(@"end %@",[NSThread currentThread]);
}

/**
 2018-06-03 18:27:53.880329+0800 MultithreadingSummary[9473:305596] begin <NSThread: 0x600000262d00>{number = 1, name = main}
 2018-06-03 18:27:53.880625+0800 MultithreadingSummary[9473:305596] 任务 A <NSThread: 0x600000262d00>{number = 1, name = main}
 2018-06-03 18:27:53.880800+0800 MultithreadingSummary[9473:305596] end <NSThread: 0x600000262d00>{number = 1, name = main}
 */
- (void)testGCDeadLockDemo1{
    NSLog(@"begin %@",[NSThread currentThread]);
    dispatch_queue_t serialQueue = dispatch_queue_create("com.mgzh.MultithreadingSummary.008", DISPATCH_QUEUE_SERIAL);
    dispatch_sync(serialQueue, ^{
        NSLog(@"任务 A %@",[NSThread currentThread]);
    });
    NSLog(@"end %@",[NSThread currentThread]);
}

/**
 2018-06-03 18:25:20.441856+0800 MultithreadingSummary[9407:303289] begin <NSThread: 0x600000074340>{number = 1, name = main}
 2018-06-03 18:25:20.442148+0800 MultithreadingSummary[9407:303289] end <NSThread: 0x600000074340>{number = 1, name = main}
 2018-06-03 18:25:20.442380+0800 MultithreadingSummary[9407:303343] 任务 A Begin <NSThread: 0x604000460280>{number = 3, name = (null)}
 (lldb) - 死锁
 */
- (void)testGCDeadLockDemo2{
    NSLog(@"begin %@",[NSThread currentThread]);
    dispatch_queue_t serialQueue = dispatch_queue_create("com.mgzh.MultithreadingSummary.008", DISPATCH_QUEUE_SERIAL);
    dispatch_async(serialQueue, ^{
        NSLog(@"任务 A Begin %@",[NSThread currentThread]);
        dispatch_sync(serialQueue, ^{
            NSLog(@"任务B %@",[NSThread currentThread]);
        });
        NSLog(@"任务 A End %@",[NSThread currentThread]);
    });
    NSLog(@"end %@",[NSThread currentThread]);
}

/**
 生成一个随机数 范围在[from,to]
 */
-(int)getRandomNumber:(int)from to:(int)to{
    return (int)(from + (arc4random() % (to - from + 1)));
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
