//
//  ULBaseAlertViewController.h
//  UpLive
//
//  Created by xuqinqiang on 2022/1/25.
//  Copyright © 2022 AsiaInnovations. All rights reserved.
//  项目中弹窗控制器基类

#import "ULBaseViewController.h"
#import "NSObject+ULPriority.h"
@class ULBaseAlertViewController;

#define kMostAlertWidth 300 //大部分弹窗背景的宽 子类使用 用于统一弹窗的尺寸

typedef NS_ENUM(NSInteger, ULPopAlertAnimationType) {
    ULPopAlertAnimationBottomInBottomOut = 1,   //底部弹出底部消失
    ULPopAlertAnimationBottomInTopOut,          //底部弹出顶部消失
    ULPopAlertAnimationTopInTopOut,             //顶部弹出顶部消失
    ULPopAlertAnimationTopInBottomOut,          //顶部弹出底部消失
    ULPopAlertAnimationPush,                    //右侧弹出右侧消失(类似push动画)
    ULPopAlertAnimationPushRTL,                 //左侧弹出左侧消失(类似push动画)
    ULPopAlertAnimationAlpha,                   //渐变
    ULPopAlertAnimationScal,                    //缩放
    ULPopAlertAnimationNone,                    //无动画
};

typedef void(^ULBaseAlertViewLifeCycleBlock)(ULBaseAlertViewController *alertView);

/// 弹窗生命周期协议 目前只支持这四种时机
@protocol ULBaseAlertViewLifeCycleProtocol <NSObject>
/// 弹窗将要展示的回调
@property (nonatomic, copy) ULBaseAlertViewLifeCycleBlock willShowBlock;
/// 弹窗已经展示的回调
@property (nonatomic, copy) ULBaseAlertViewLifeCycleBlock didShowBlock;
/// 弹窗将要消失回调
@property (nonatomic, copy) ULBaseAlertViewLifeCycleBlock willDismissBlock;
/// 弹窗已经消失回调
@property (nonatomic, copy) ULBaseAlertViewLifeCycleBlock didDismissBlock;

/// 弹框即将显示
/// 子类可重写此方法
- (void)ul_alertViewWillShow;

/// 弹窗显示动画结束后回调
/// 子类可以重写此方法
- (void)ul_alertViewDidShow;

/// 弹窗即将消失
/// 子类可重写此方法
- (void)ul_alertViewWillDismiss;

/// 弹窗消失动画结束后回调
/// 子类可重写此方法
- (void)ul_alertViewDidDismiss;

@end

/// 批量消除弹窗相关协议 根据业务需求进行使用
@protocol ULBaseAlertViewBatchDismissProtocol <NSObject>
/// 弹窗的业务tag 列如:赋值为直播间roomId
@property (nonatomic, copy) NSString *businessIdentifier;

/// 是否包含这个类型的弹窗
/// - Parameter vcClassStr: 弹窗的类名字符串
+ (BOOL)isContainAlert:(NSString *)vcClassStr;

/// 隐藏 alertTag 类型的所有弹窗 慎用!
/// - Parameter alertTag: 弹窗类型
+ (void)dismissAlertViewWithTag:(NSInteger)alertTag;

/// 隐藏 alertTag 类型的所有弹窗 慎用!
/// - Parameters:
///   - alertTag: 弹窗类型
///   - animation: 动画类型
+ (void)dismissAlertViewWithTag:(NSInteger)alertTag
                      animation:(ULPopAlertAnimationType)animation;

/// 隐藏 businessIdentifier 业务类型的所有弹窗 慎用!
/// - Parameter businessIdentifier: 业务类型标识
+ (void)dismissAlertWithBusinessIdentifier:(NSString *)businessIdentifier;

/// 隐藏 businessIdentifier 业务类型的所有弹窗 慎用!
/// - Parameters:
///   - businessIdentifier: 业务类型标识
///   - animation: 动画类型
+ (void)dismissAlertWithBusinessIdentifier:(NSString *)businessIdentifier
                                 animation:(ULPopAlertAnimationType)animation;

/// 隐藏 alertClass 类型的所有弹窗 慎用!
/// - Parameter alertClass: alertClass
+ (void)dismissAlertViewWithClass:(NSString *)alertClass;

/// 隐藏 alertClass 类型的所有弹窗 慎用!
/// - Parameters:
///   - alertClass: alertClass
///   - animation: 动画类型
+ (void)dismissAlertViewWithClass:(NSString *)alertClass
                        animation:(ULPopAlertAnimationType)animation;

/// 获取此类型的所有弹窗
+ (NSArray<__kindof ULBaseAlertViewController *> *)getAlertViewWithClass:(NSString *)alertClass;

/// 清除 所有弹窗 慎用!
/// ⚠️ showInWindow 与 showInView 可直接消除
/// ⚠️ show 类型的弹框 只是单纯从数组中移除
/// 无动画类型
+ (void)removeAllAlertView;

@end

NS_ASSUME_NONNULL_BEGIN

@interface ULBaseAlertViewController : ULBaseViewController <ULBaseAlertViewLifeCycleProtocol, ULBaseAlertViewBatchDismissProtocol>
/**
 1.此视图与控制器视图尺寸一致 用于实现显示,消失动画 默认透明色
 2.弹窗的内容需要添加在此view上
 */
@property (nonatomic, strong, readonly) UIView *contentView;
/// 自定义容器高度 通过 configCustomHeight 进行设置
@property (nonatomic, assign, readonly) CGFloat customHeight;
/// 动画类型
@property (nonatomic, assign) ULPopAlertAnimationType animationType;
/// 显示动画的时间 默认 0.25s
@property (nonatomic, assign) CGFloat animationTime;
/// 点击空白处是否退出 默认不退出
@property (nonatomic, assign) BOOL tapBlankDismiss;
/// 是否禁用弹性效果 默认不禁用
@property (nonatomic, assign) BOOL forbiddenFlexible;
/// 是否启用动画背景颜色 default: NO
/// 开启后背景颜色动画到 animationBgColor 动画消失
@property (nonatomic, assign) BOOL enableAnimationBgColor;
/// 动画渐变到的颜色 default:black alpha:0.4
@property (nonatomic, strong) UIColor *animationBgColor;
/// 弹窗的tag 用于区分多个弹窗
@property (nonatomic, assign) NSInteger alertTag;
/// 消失的回调 (❗️❗️已弃用 请使用生命周期回调❗️❗️)
@property (nonatomic, copy) dispatch_block_t dismissBlock __attribute__((deprecated("已过期, 请用生命周期回调")));
/// 显示完成的回调 (❗️❗️已弃用 请使用生命周期回调❗️❗️)
@property (nonatomic, copy) dispatch_block_t showBlock __attribute__((deprecated("已过期, 请用生命周期回调")));
/// 弹窗等级
@property (nonatomic, assign) ULAlertPriorityLevel priorityLevel;
/// 圆角大小，默认值为12
@property (nonatomic, assign) CGFloat cornerRadius;
/// 是否展示中
@property (nonatomic, assign, readonly) BOOL isShowing;

/// present 显示 默认动画 ULPopAlertAnimationBottomInBottomOut
- (void)show;

/// present 弹窗 默认动画 ULPopAlertAnimationBottomInBottomOut
/// @param presentVc 通过制定的 vc 弹出
- (void)showWithPresentVc:(UIViewController *)presentVc;

/// present 显示 可指定动画类型
/// @param animation 动画类型
- (void)showWithAnimation:(ULPopAlertAnimationType)animation;

/// present 弹窗
/// @param animation 动画类型
/// @param presentVc 通过制定的 vc 弹出
- (void)showWithAnimation:(ULPopAlertAnimationType)animation
                presentVc:(UIViewController *)presentVc;

/// 在 window 上显示 默认动画 ULPopAlertAnimationBottomInBottomOut
- (void)showInWindow;

/// 在 window 上显示
/// @param animation 动画类型
- (void)showInWindowWithAnimation:(ULPopAlertAnimationType)animation;

/// 在view上显示 默认动画 ULPopAlertAnimationBottomInBottomOut
/// @param view 此 view 要是全屏的 或者是控制器 不然效果不好
- (void)showInView:(UIView *)view;

/// 在view上显示
/// @param view 此 view 要是全屏的 或者是控制器 不然效果不好
/// @param animation 动画类型
- (void)showInView:(UIView *)view
         animation:(ULPopAlertAnimationType)animation;

/// 退出弹框
- (void)dismiss;

/// 退出弹框
/// @param animation 动画类型
- (void)dismissWithAnimation:(ULPopAlertAnimationType)animation;

/// 退出弹框 (❗️❗️已弃用 请使用不带参的 dismissWithAnimation❗️❗️)
/// @param animation 动画类型
/// @param handleBlock YES:执行消失回调 NO:不执行
- (void)dismissWithAnimation:(ULPopAlertAnimationType)animation
                 handleBlock:(BOOL)handleBlock DEPRECATED_MSG_ATTRIBUTE("请使用不带参的 dismissWithAnimation");

/// 配置自定义容器高度
- (void)configCustomHeight:(CGFloat)customHeight;

/// 空白按钮点击回调，子类重写点击
- (void)p_blankBtnPress;

@end

NS_ASSUME_NONNULL_END
