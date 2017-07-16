//
//  TZKeyboardPop.h
//  tizhr
//
//  Created by Nataniel Martin on 16/02/15.
//  Copyright (c) 2015 appstud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
#define kCFCoreFoundationVersionNumber_iOS_8_0 1129.15
#endif

@class TZKeyboardPop;
@protocol TZKeyboardPopDelegate <NSObject>
@optional
- (void) didShowKeyboard;
- (void) didCancelKeyboard;
- (void) didReturnKeyPressedWithText:(NSString *)str;

@end

@interface TZKeyboardPop : NSObject <UITextFieldDelegate> {
    UIView *currentView;
}

@property (nonatomic, weak) id<TZKeyboardPopDelegate> delegate;
@property (nonatomic, assign) NSInteger tag;

- (id) initWithView:(UIView *)view;

- (void) setPlaceholderText:(NSString *)str;
- (void) setTextFieldText:(NSString *)str;
- (void) setTextFieldTextViewMode:(UITextFieldViewMode)mode;
- (void) setTextFieldTintColor:(UIColor *)color;

- (void) showKeyboard;

- (void) hide;

@end

