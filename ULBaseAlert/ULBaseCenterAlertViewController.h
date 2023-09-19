//
//  ULBaseCenterAlertViewController.h
//  UpLive
//
//  Created by xuqinqiang on 2022/1/25.
//  Copyright © 2022 AsiaInnovations. All rights reserved.
//  中间弹出的弹框基类 弹窗的内容需要添加到提供的内容视图上
//  中间弹窗采用的动画 建议使用
//  ULPopAlertAnimationAlpha, //渐变
//  ULPopAlertAnimationScal,  //缩放
//  ULPopAlertAnimationNone,  //无动画

#import "ULBaseAlertViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ULBaseCenterAlertViewController : ULBaseAlertViewController
/// 中间的内容视图 所有的子视图添加到此视图中
@property (nonatomic, strong, readonly) UIView *wrapView;
/// 是否隐藏关闭按钮 默认不隐藏
@property (nonatomic, assign) BOOL hiddenCloseBtn;

/// 重新设置关闭按钮图片
/// @param img img
- (void)setCloseBtnImg:(UIImage *)img;

@end

NS_ASSUME_NONNULL_END
