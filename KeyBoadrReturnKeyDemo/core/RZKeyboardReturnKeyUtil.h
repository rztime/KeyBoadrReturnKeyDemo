//
//  RZKeyboardReturnKeyUtil.h
//  KeyBoadrReturnKeyDemo
//
//  Created by rztime on 2017/9/8.
//  Copyright © 2017年 rztime. All rights reserved.
//  全局的键盘的右下角return按钮的管理，显示“下一项”或“完成”（next or done）

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NextBehavior) {
    NextBehaviorByPosition = 0,     // 默认通过位置跳转 默认以此
    NextBehaviorByTag = 1           // 通过tag值从小到大跳转
};

/**
 全局的键盘的右下角return按钮的管理，显示“下一项”或“完成”（next or done）
 */
@interface RZKeyboardReturnKeyUtil : NSObject

/**
 全局单例

 @return <#return value description#>
 */
+ (instancetype)shareInstance;

/**
 是否可以使用，默认为NO
 */
@property (nonatomic, assign) BOOL enable;

/**
 点击下一项时，跳转到下一个输入框的顺序依据 默认通过文本框在view上的位置跳转
 */
@property (nonatomic, assign) NextBehavior nextBehavior;

@end
