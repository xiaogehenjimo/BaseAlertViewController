//
//  ULBaseBottomPopAlertViewController.h
//  UpLive
//
//  Created by xuqinqiang on 2022/1/25.
//  Copyright © 2022 AsiaInnovations. All rights reserved.
//  底部弹出的弹窗采用动画 建议使用 ULPopAlertAnimationBottomInBottomOut

#import "ULBaseAlertViewController.h"
@class ULNavBottomPopAlertViewController;

NS_ASSUME_NONNULL_BEGIN

///因为组件化 文件存放的位置不对 需要拿到父类中定义
@protocol ULNavBottomPopAlertViewControllerProtocol
@property(nonatomic, weak) ULNavBottomPopAlertViewController *parentCtrl;
@end

@interface ULBaseBottomPopAlertViewController : ULBaseAlertViewController
/// 中间的内容视图 所有的子视图添加到此视图中
@property (nonatomic, strong, readonly) UIView *wrapView;
/// 是否隐藏关闭按钮 默认不隐藏
@property (nonatomic, assign) BOOL hiddenCloseBtn;
/*
 是否开启拖拽退出手势 默认不开启
 拖动退出与下拉刷新不能共存,不能共存,不能共存
*/
@property (nonatomic, assign) BOOL enableSlidePanGesture;
/// 拖动消失距离占内容视图高度的百分比 默认弹窗高度的50% ![enablePanGesture开启后生效]!
@property (nonatomic, assign) CGFloat dragDistanceRatio;
/// 快速滑动消失速度 默认800 ![enablePanGesture开启后生效]!
@property (nonatomic, assign) CGFloat dragDismissSpeed;

/// 重新设置关闭按钮图片
/// @param img img
- (void)setCloseBtnImg:(UIImage *)img;

@end

NS_ASSUME_NONNULL_END
