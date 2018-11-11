//
//  NSOperationSummaryController.m
//  MultithreadingSummary
//
//  Created by M on 2018/9/18.
//  Copyright © 2018年 Mgzh. All rights reserved.
//

#import "NSOperationSummaryController.h"

@interface NSOperationSummaryController ()

@end

@implementation NSOperationSummaryController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setMaxConcurrentOperationCount];
}

/**
 使用子类NSInvocationOperation
 */
- (void)useNSInvocationOperation{
    NSInvocationOperation *invocationOp = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(taskDemo1) object:nil];
    [invocationOp start];
}
- (void)taskDemo1{
    NSLog(@"job1 in 当前线程 %@",[NSThread currentThread]);
    sleep(2);
    NSLog(@"job1 out 当前线程 %@",[NSThread currentThread]);
}

/**
 使用子类NSBlockOperation
 */
- (void)userNSBlockOperation{
    NSBlockOperation *blockOp = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"job1 in 当前线程 %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"job1 out 当前线程 %@",[NSThread currentThread]);
    }];
    /*
     Adds the specified block to the receiver’s list of blocks to perform.
     The specified block should not make any assumptions about its execution environment.
     Calling this method while the receiver is executing or has already finished causes an NSInvalidArgumentException exception to be thrown
     可以 并行异步执行
     */
    [blockOp addExecutionBlock:^{
        NSLog(@"job2 in 当前线程 %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"job2 out 当前线程 %@",[NSThread currentThread]);
    }];
    [blockOp addExecutionBlock:^{
        NSLog(@"job3 in 当前线程 %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"job3 out 当前线程 %@",[NSThread currentThread]);
    }];
    [blockOp start];
}

#pragma mark - -----------------------------------NSOperationQueue

/**
 * 使用 addOperation: 将操作加入到操作队列中   并发异步执行
 */
- (void)NSOperationQueueAddOperation{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSInvocationOperation *op1 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(taskDemo1) object:nil];
    NSInvocationOperation *op2 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(taskDemo1) object:nil];
    NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"job31 in 当前线程 %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"job31 out 当前线程 %@",[NSThread currentThread]);
    }];
    [op3 addExecutionBlock:^{
        NSLog(@"job32 in 当前线程 %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"job32 out 当前线程 %@",[NSThread currentThread]);
    }];
    
    [queue addOperation:op1]; // [op1 start]
    [queue addOperation:op2]; // [op2 start]
    [queue addOperation:op3]; // [op3 start]
}

/**
 * 使用 addOperationWithBlock: 将操作加入到操作队列中  并发异步执行
 */
- (void)NSOperationQueueAddOperationWithBlock {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        NSLog(@"job1 in 当前线程 %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"job1 out 当前线程 %@",[NSThread currentThread]);
    }];
    [queue addOperationWithBlock:^{
        NSLog(@"job2 in 当前线程 %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"job2 out 当前线程 %@",[NSThread currentThread]);
    }];
    [queue addOperationWithBlock:^{
        NSLog(@"job3 in 当前线程 %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"job3 out 当前线程 %@",[NSThread currentThread]);
    }];
}


/**
 * 设置 MaxConcurrentOperationCount（最大并发操作数）
 */
- (void)setMaxConcurrentOperationCount{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    /*
     maxConcurrentOperationCount 默认情况下为-1，表示不进行限制，可进行并发执行。
     maxConcurrentOperationCount 为1时，队列为串行队列。只能串行执行。
     maxConcurrentOperationCount 大于1时，为并发队列。操作并发执行，最大值不会超过系统限制。 实际值为：min{自己设定的值，系统设定的默认最大值}。
     其他 -- maxConcurrentOperationCount 为0时，不执行任务；小于0且不为-1时，崩溃
     */
    queue.maxConcurrentOperationCount = -2;
    
    [queue addOperationWithBlock:^{
        NSLog(@"job1 in 当前线程 %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"job1 out 当前线程 %@",[NSThread currentThread]);
    }];
    [queue addOperationWithBlock:^{
        NSLog(@"job2 in 当前线程 %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"job2 out 当前线程 %@",[NSThread currentThread]);
    }];
    [queue addOperationWithBlock:^{
        NSLog(@"job3 in 当前线程 %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"job3 out 当前线程 %@",[NSThread currentThread]);
    }];
}


/**
 * 操作依赖
 * 使用方法：addDependency:
 */
- (void)addDependency {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"job1 in 当前线程 %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"job1 out 当前线程 %@",[NSThread currentThread]);
    }];
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"job2 in 当前线程 %@",[NSThread currentThread]);
        sleep(2);
        NSLog(@"job2 out 当前线程 %@",[NSThread currentThread]);
    }];
    [op2 addDependency:op1]; // 让op2 依赖于 op1，则先执行op1，在执行op2
    [queue addOperation:op1];
    [queue addOperation:op2];
}


/**
 * 线程间通信
 */
- (void)communication {
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    [queue addOperationWithBlock:^{
        // 异步进行耗时操作
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"1---%@", [NSThread currentThread]); // 打印当前线程
        }
        
        // 回到主线程
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // 进行一些 UI 刷新等操作
            for (int i = 0; i < 2; i++) {
                [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
                NSLog(@"2---%@", [NSThread currentThread]); // 打印当前线程
            }
        }];
    }];
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
