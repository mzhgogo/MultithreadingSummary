//
//  MainViewController.m
//  MultithreadingSummary
//
//  Created by M gzh on 2018/6/3.
//  Copyright © 2018年 Mgzh. All rights reserved.
//

#import "MainViewController.h"
#import "GCDSummaryController.h"
#import "NSOperationSummaryController.h"
#import "NSLockSummaryController.h"
#import "NSRunLoopSummaryController.h"
@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    /*
     1、进程是系统进行资源分配的基本单位，有独立的内存地址空间； 线程是CPU调度的基本单位，没有单独地址空间，有独立的栈，局部变量，寄存器， 程序计数器等。
     2、创建进程的开销大，包括创建虚拟地址空间等需要大量系统资源； 创建线程开销小，基本上只有一个内核对象和一个堆栈。 
     3、一个进程无法直接访问另一个进程的资源；同一进程内的多个线程共享进程的资源。 
     4、进程切换开销大，线程切换开销小；进程间通信开销大，线程间通信开销小。 
     5、线程属于进程，不能独立执行。每个进程至少要有一个线程，成为主线程
     
     
     进程和线程之间的区别；
     异步和同步的区别；异步一定会开新线程么？串行同步会不会卡死？同步一定会阻塞当前线程么(考察同步阻塞的是队列还是线程)
     主队列是串行还是并行队列
     多个串行队列之间是串行还是并行执行
     系统全局并发队列能否被挂起和恢复？
     abc三个任务，每个任务耗时2s；问并发同步、串行异步、并发异步 均耗时多少时间？未答对：并发同步在哪个线程(主还是子)执行？主队列异步在哪个线程执行？
     */
}
- (IBAction)goGCDAction:(UIButton *)sender {
    UIViewController *nextViewController;
    switch (sender.tag) {
        case 1001:
            nextViewController = [[GCDSummaryController alloc]init];
            break;
        case 1002:
            nextViewController = [[NSOperationSummaryController alloc]init];
            break;
        case 1003:
            nextViewController = [[NSRunLoopSummaryController alloc]init];
            break;
        case 1004:
            nextViewController = [[NSLockSummaryController alloc]init];
            break;
        default:
            break;
    }
    [self.navigationController pushViewController:nextViewController animated:YES];
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
