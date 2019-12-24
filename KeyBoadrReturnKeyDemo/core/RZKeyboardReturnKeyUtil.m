//
//  RZKeyboardReturnKeyUtil.m
//  KeyBoadrReturnKeyDemo
//
//  Created by rztime on 2017/9/8.
//  Copyright © 2017年 rztime. All rights reserved.
//

#import "RZKeyboardReturnKeyUtil.h"
#import <UIKit/UIKit.h>
#import <BlocksKit/A2DynamicDelegate.h>
#import <BlocksKit/UITextField+BlocksKit.h>


@interface NSArray (rz_safeObj)

- (id)rz_safeObjectAtIndex:(NSInteger)index;

@end

@implementation NSArray (rz_safeObj)

- (id)rz_safeObjectAtIndex:(NSInteger)index {
    if (index >= self.count) {
        return nil;
    }
    if (index < 0) {
        return nil;
    }
    return self[index];
}

@end


@interface RZKeyboardReturnKeyUtil()<UITextFieldDelegate>

@property (nonatomic, weak)	  UIViewController		    *currentViewController;	// 当前响应的textField所在的控制器

@property (nonatomic, strong) NSArray				    *textFieldArrays;		// 当前控制器中所有的textField

@property (nonatomic, weak)	  UITextField				*currentTextField;		// 当前响应焦点的textField

@property (nonatomic, weak)	  id<UITextFieldDelegate>   delegate;				// 当前响应焦点的textField原delegate

@end

@implementation RZKeyboardReturnKeyUtil
+ (void)load {
    [self performSelectorOnMainThread:@selector(shareInstance) withObject:nil waitUntilDone:NO];
}

+ (instancetype)shareInstance {
    static RZKeyboardReturnKeyUtil *util = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        util = [[RZKeyboardReturnKeyUtil alloc] init];
    });
    return util;
}

- (instancetype)init {
    if (self = [super init]) {
        [self addNotication];
        self.nextBehavior = NextBehaviorByPosition;
    }
    return self;
}

// 注册通知，只有获得焦点和失去焦点时，得到通知
- (void)addNotication {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidBeginEditingNotification:) name:UITextFieldTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidEndEditingNotification:) name:UITextFieldTextDidEndEditingNotification object:nil];
}

- (void)dealloc {
	self.currentTextField.delegate = _delegate;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)clearCache {
	_delegate = nil;
	_currentTextField = nil;
}

// 获得焦点
- (void)textFieldDidBeginEditingNotification:(NSNotification *)notifacation {
    if (!self.enable) {
		[self clearCache];
        return ;
    }
    if ([notifacation.object isKindOfClass:NSClassFromString(@"UISearchBarTextField")]) {
		[self clearCache];
        return ;
    }
	UITextField *text = notifacation.object;
	// 有特殊功能的输入框，不纳入管理
	if (text.returnKeyType == UIReturnKeyDefault || text.returnKeyType == UIReturnKeyNext || text.returnKeyType == UIReturnKeyDone || !text.returnKeyType) {
		// 得到当前textField的控制器
		_currentTextField = notifacation.object;
		if ([self canNext]) {   // 判断是否还有下一个
			_currentTextField.returnKeyType = UIReturnKeyNext;
		} else {
			_currentTextField.returnKeyType = UIReturnKeyDone;
		}
		// 因为BlockKit也复写了textField的delegate，所以这里判断一下，取真实的delegate。
		NSString *delegateClass = [NSString stringWithFormat:@"%s", object_getClassName(_currentTextField.delegate)];
		if([delegateClass isEqualToString:@"A2DynamicUITextFieldDelegate"]) {
			A2DynamicDelegate *delegate = _currentTextField.delegate;
			_delegate = delegate.realDelegate;
		} else {
			_delegate = _currentTextField.delegate;
		}
		// 覆盖代理
		_currentTextField.delegate = self;
		
		[self textFieldDidBeginEditing:_currentTextField];
	} else {
		[self clearCache];
	}
}

// 失去焦点
- (void)textFieldDidEndEditingNotification:(NSNotification *)notifacation {
    // 失去焦点，将delegate还原
	if (notifacation.object == self.currentTextField) {
		[self textFieldDidEndEditing:self.currentTextField];
		((UITextField *)notifacation.object).delegate = _delegate;
	}
}

#pragma mark - 判断是否还有下一个输入框
// 是否有下一个输入框
- (BOOL)canNext {
    // 得到当前控制器
    self.currentViewController = [self viewController:self.currentTextField];
    // 获取所有的输入框
    self.textFieldArrays = [self getAllTextField];
    // 得到当前输入框的位置索引
    NSInteger index = [self.textFieldArrays indexOfObject:self.currentTextField];
    if (index == NSNotFound) {
        return NO;
    }
    UITextField *nextField = [self.textFieldArrays rz_safeObjectAtIndex:index+1];
    if (nextField) {    // 有下一个输入框
        return YES;
    }
    return NO;
}

// 当前输入框所在的容器
- (UIViewController *)viewController:(UIView *)textField {
    for (UIView* next = textField; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}

#pragma mark - 获取当前控制器的所有的文本框
// 获得当前控制器的所有的文本框
- (NSArray *)getAllTextField {
    // 获得所有的文本框，默认按照位置排序
    NSArray *textArray = [self deepResponderViews:self.currentViewController.view];
    // 如果设置按照tag排序，则重新排序
    if (self.nextBehavior == NextBehaviorByTag) {
        return [textArray sortedArrayUsingComparator:^NSComparisonResult(UIView *view1, UIView *view2) {
            if ([view1 respondsToSelector:@selector(tag)] && [view2 respondsToSelector:@selector(tag)]) {
                if ([view1 tag] < [view2 tag]) {
                    return NSOrderedAscending;
                } else if ([view1 tag] > [view2 tag]) {
                    return NSOrderedDescending;
                } else {
                    return NSOrderedSame;
                }
            } else {
                return NSOrderedSame;
            }
        }];
    }
    return textArray;
}

// 通过递归，来获得控件中的所有的textField
- (NSArray*)deepResponderViews:(UIView *)superView {
    NSMutableArray *textFields = [[NSMutableArray alloc] init];
    for (UIView *textField in superView.subviews) {
        if ([self canBecomeFirstResponder:textField]) {
            [textFields addObject:textField];
        }
        //Sometimes there are hidden or disabled views and textField inside them still recorded, so we added some more validations here
        //Uncommented else
        if (textField.subviews.count && [textField isUserInteractionEnabled] && ![textField isHidden] && [textField alpha]!=0.0) {
            [textFields addObjectsFromArray:[self deepResponderViews:textField]];
        }
    }
    //subviews are returning in incorrect order. Sorting according the frames 'y'.
    __weak typeof(self) weakself = self;
    return [textFields sortedArrayUsingComparator:^NSComparisonResult(UIView *view1, UIView *view2) {
        CGRect frame1 = [view1 convertRect:view1.bounds toView:weakself.currentViewController.view];
        CGRect frame2 = [view2 convertRect:view2.bounds toView:weakself.currentViewController.view];
        
        CGFloat x1 = CGRectGetMinX(frame1);
        CGFloat y1 = CGRectGetMinY(frame1);
        CGFloat x2 = CGRectGetMinX(frame2);
        CGFloat y2 = CGRectGetMinY(frame2);
        
        if (y1 < y2) {
            return NSOrderedAscending;
        } else if (y1 > y2) {
            return NSOrderedDescending;
        }
        //Else both y are same so checking for x positions
        else if (x1 < x2) {
            return NSOrderedAscending;
        } else if (x1 > x2) {
           return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    return textFields;
}

// 是否是可以响应的文本框
-(BOOL)canBecomeFirstResponder:(UIView *)view {
    BOOL canBecomeFirstResponder = NO;
    if ([view isKindOfClass:[UITextField class]]) {
        canBecomeFirstResponder = [(UITextField*)view isEnabled];
    } else if ([view isKindOfClass:[UITextView class]]) {
        canBecomeFirstResponder = [(UITextView*)view isEditable];
    }
    if (canBecomeFirstResponder == YES) {
        canBecomeFirstResponder = ([view isUserInteractionEnabled] && ![view isHidden] && [view alpha]!=0.0 && ![self isAlertViewTextField:view]  && ![self isSearchBarTextField:view]);
    }
    return canBecomeFirstResponder;
}

// 是否是alertView中的文本框
-(BOOL)isAlertViewTextField:(UIView *)view {
    UIResponder *alertViewController = [self viewController:view];
    BOOL isAlertViewTextField = NO;
    while (alertViewController && isAlertViewTextField == NO) {
        if ([alertViewController isKindOfClass:[UIAlertController class]]) {
            isAlertViewTextField = YES;
            break;
        }
        alertViewController = [alertViewController nextResponder];
    }
    return isAlertViewTextField;
}

// 是否是搜索框
-(BOOL)isSearchBarTextField:(UIView *)view {
    UIResponder *searchBar = [self viewController:view];
    BOOL isSearchBarTextField = NO;
    while (searchBar && isSearchBarTextField == NO) {
        if ([searchBar isKindOfClass:[UISearchBar class]]) {
            isSearchBarTextField = YES;
            break;
        } else if ([searchBar isKindOfClass:[UIViewController class]]) {   //If found viewcontroller but still not found UISearchBar then it's not the search bar textfield
            break;
        }
        searchBar = [searchBar nextResponder];
    }
    return isSearchBarTextField;
}

#pragma mark - 输入框的代理
#pragma mark - 传递delegate, 重写delegate，并实现textField原delegate实现的方法
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {        // return NO to disallow editing.
    BOOL result = YES;
    if (_delegate && [_delegate respondsToSelector:@selector(textFieldShouldBeginEditing:)] && _delegate != self) {
        result = [_delegate textFieldShouldBeginEditing:textField];
    }
    return result;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {           // became first responder
    if (_delegate && [_delegate respondsToSelector:@selector(textFieldDidBeginEditing:)] && _delegate != self) {
        [_delegate textFieldDidBeginEditing:textField];
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {          // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
    BOOL result = YES;
    if (_delegate && [_delegate respondsToSelector:@selector(textFieldShouldEndEditing:)] && _delegate != self) {
        result = [_delegate textFieldShouldEndEditing:textField];
    }
    return result;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {             // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
    if (_delegate && [_delegate respondsToSelector:@selector(textFieldDidEndEditing:)] && _delegate != self) {
        [_delegate textFieldDidEndEditing:textField];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField reason:(UITextFieldDidEndEditingReason)reason NS_AVAILABLE_IOS(10_0) { // if implemented, called in place of textFieldDidEndEditing:
    if (_delegate && [_delegate respondsToSelector:@selector(textFieldDidEndEditing:reason:)] && _delegate != self) {
        [_delegate textFieldDidEndEditing:textField reason:reason];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {   // return NO to not change text
    BOOL result = YES;
    if (_delegate && [_delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)] && _delegate != self) {
        result = [_delegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
    }
    return result;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    BOOL result = YES;
    if (_delegate && [_delegate respondsToSelector:@selector(textFieldShouldClear:)] && _delegate != self) {
        result = [_delegate textFieldShouldClear:textField];
    }
    return result;
}

#pragma mark - 点击了return按钮
// 点击了return按钮
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    BOOL result = YES;
    if (_delegate && [_delegate respondsToSelector:@selector(textFieldShouldReturn:)] && _delegate != self) {
        result = [_delegate textFieldShouldReturn:textField];
    }
    // 如果原textField已实现此方法，且不允许执行之下的，则返回
    if (!result) {
        return NO;
    }
	// 有特殊功能的输入框，不纳入管理
	if (textField.returnKeyType == UIReturnKeyDefault || textField.returnKeyType == UIReturnKeyNext || textField.returnKeyType == UIReturnKeyDone || !textField.returnKeyType) {
		// 获取当前textField在数组中的索引
		NSInteger index = [self.textFieldArrays indexOfObject:textField];
		if (index == NSNotFound) {
			[textField endEditing:YES];
			return YES;
		}
		// 获取下一个文本框
		UITextField *nextTextField = [self.textFieldArrays rz_safeObjectAtIndex:index + 1];
		if (nextTextField) {
			[nextTextField becomeFirstResponder];
			if ([nextTextField isKindOfClass:[UITextView class]]) {
				return NO;
			}
			return YES;
		}
		[textField endEditing:YES];
	}
	return YES;
}

@end

