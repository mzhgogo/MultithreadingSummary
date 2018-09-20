//
//  NSRunLoopSummaryController.m
//  MultithreadingSummary
//
//  Created by M on 2018/9/18.
//  Copyright © 2018年 Mgzh. All rights reserved.
//

#import "NSRunLoopSummaryController.h"

/**
 NSRunLoop 作用？用来干嘛的？让线程不断的处理任务，并不退出
 NSRunLoop 会在循环中不断检测，通过input source（输入源）和timer source（定时源）两种来源等待接收事件；然后对接收到的事件通知线程进行处理，并在没有事件的时候让线程进行休息
 NSRunLoop 启动时只能指定其中一个运行模式，要切换运行模式，只能退出当前loop
 
 
 NSDefaultRunLoopMode
 NSRunLoopCommonModes
 UITrackingRunLoopMode(跟踪用户交互事件，用于scrollview追踪触摸滑动，保证界面滑动时不受其他model影响)
 */
@interface NSRunLoopSummaryController ()

@end

@implementation NSRunLoopSummaryController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    UITextView *textView = [[UITextView alloc]initWithFrame:CGRectMake(30, 100, 200, 100)];
    textView.backgroundColor = [UIColor yellowColor];
    textView.text = @"我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字我是测试文字";
    [self.view addSubview:textView];
    
    //添加到默认的runloop中
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(run) userInfo:nil repeats:YES];
    //未默认添加
    NSTimer *timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(run) userInfo:nil repeats:YES];
    //[[NSRunLoop currentRunLoop]addTimer:timer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop]addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)run{
    NSLog(@" - run - ");
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
