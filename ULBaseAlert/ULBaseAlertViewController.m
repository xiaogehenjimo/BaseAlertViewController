//
//  ULBaseAlertViewController.m
//  UpLive
//
//  Created by xuqinqiang on 2022/1/25.
//  Copyright © 2022 AsiaInnovations. All rights reserved.
//

#import "ULBaseAlertViewController.h"
#import <Masonry/Masonry.h>
#import <ULMacroModule/ULRectMacros.h>
#import <AIBasicModule/UIView+AICategory.h>
#import <AIBasicModule/AIThreadManager.h>
#import <ReactiveObjC/ReactiveObjC.h>

/// 用于管理弹窗,仅用于持有弹窗对象
@interface OTAlertViewManager : NSObject
/// 弹窗数组
@property (nonatomic, strong, readonly) NSMutableArray *alertArr;
@end

@implementation OTAlertViewManager

+ (instancetype)sharedManager {
    static OTAlertViewManager *alertManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        alertManager = [[OTAlertViewManager alloc] init];
    });
    return alertManager;
}

- (instancetype)init {
    if (self = [super init]) {
        _alertArr = [NSMutableArray array];
    }
    return self;
}

- (void)addAlert:(ULBaseAlertViewController *)alert {
    @synchronized (self) {
        [self.alertArr addObject:alert];
    }
}

- (void)removeAlert:(ULBaseAlertViewController *)alert {
    @synchronized (self) {
        if ([self.alertArr containsObject:alert]) {
            [self.alertArr removeObject:alert];
        }
    }
}

- (void)removeAllAlert {
    @synchronized (self) {
        [self.alertArr removeAllObjects];
    }
}

- (NSArray<__kindof ULBaseAlertViewController *> *)getAllAlertList {
    @synchronized (self) {
        return self.alertArr.copy;
    }
}

- (NSArray<__kindof ULBaseAlertViewController *> *)getAlertViewWithTag:(NSInteger)alertTag {
    @synchronized (self) {
        NSMutableArray<__kindof ULBaseAlertViewController *> *tmpArr = [NSMutableArray array];
        for (ULBaseAlertViewController *tempVC in self.alertArr) {
            if (tempVC.alertTag == alertTag) {
                [tmpArr addObject:tempVC];
            }
        }
        return tmpArr.copy;
    }
}

- (NSArray<__kindof ULBaseAlertViewController *> *)getAlertViewWithBusinessIdentifier:(NSString *)businessIdentifier {
    @synchronized (self) {
        NSMutableArray<__kindof ULBaseAlertViewController *> *tmpArr = [NSMutableArray array];
        for (ULBaseAlertViewController *tempVC in self.alertArr) {
            if ([tempVC.businessIdentifier isEqualToString:businessIdentifier]) {
                [tmpArr addObject:tempVC];
            }
        }
        return tmpArr.copy;
    }
}

- (NSArray<__kindof ULBaseAlertViewController *> *)getAlertViewWithClass:(NSString *)alertClass {
    @synchronized (self) {
        NSMutableArray<__kindof ULBaseAlertViewController *> *tmpArr = [NSMutableArray array];
        for (ULBaseAlertViewController *tempVC in self.alertArr) {
            if ([alertClass isEqualToString:NSStringFromClass(tempVC.class)]) {
                [tmpArr addObject:tempVC];
            }
        }
        return tmpArr.copy;
    }
}

- (BOOL)isContainAlert:(NSString *)vcClassStr {
    @synchronized (self) {
        BOOL isContain = NO;
        for (ULBaseAlertViewController *tempVC in self.alertArr) {
            if ([vcClassStr isEqualToString:NSStringFromClass(tempVC.class)]) {
                isContain = YES;
                break;
            }
        }
        return isContain;
    }
}

@end

//*************************************************************

#define dismissTime 0.25 //默认的消失动画时间

@interface ULBaseAlertViewController () <UIGestureRecognizerDelegate>
/**
 1.此视图与控制器视图尺寸一致 用于实现显示 消失动画 默认透明色
 2.弹窗的内容需要添加在此view上
 */
@property (nonatomic, strong) UIView *contentView;
/// 点击空白退出的按钮
@property (nonatomic, strong) UIButton *blankBtn;
/// 是否添加到window或view
@property (nonatomic, assign) BOOL inWindow;
/// 自定义容器高度
@property (nonatomic, assign) CGFloat customHeight;
/// 系统回调
@property (nonatomic, copy) dispatch_block_t systemDismissBlock;
/// 渐变背景动画开始颜色 default:black alpha:0.01
@property (nonatomic, strong) UIColor *animationBgStartColor;
@end

@implementation ULBaseAlertViewController
@synthesize businessIdentifier = _businessIdentifier;
@synthesize willShowBlock = _willShowBlock;
@synthesize didShowBlock = _didShowBlock;
@synthesize willDismissBlock = _willDismissBlock;
@synthesize didDismissBlock = _didDismissBlock;

- (void)dealloc {
    NSLog(@"%@ dealloc", NSStringFromClass(self.class));
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self p_commonInit];
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        [self p_commonInit];
    }
    return self;
}

- (void)p_commonInit {
    _cornerRadius = 12;
    _customHeight = MainScreenHeight;
    _priorityLevel = ULAlertPriorityLevel_Default;
    _animationTime = 0.5;
    _animationType = ULPopAlertAnimationBottomInBottomOut;
    _animationBgColor = [UIColor ai_colorWithHexString:@"#000000" alpha:0.4];
    _animationBgStartColor = [UIColor ai_colorWithHexString:@"#000000" alpha:0.01];
    self.modalPresentationStyle = UIModalPresentationCustom;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navBgImageView.hidden = YES;
    if (!self.enableAnimationBgColor || self.animationType == ULPopAlertAnimationNone) {
        self.view.backgroundColor = self.animationBgColor;
    } else {
        self.view.backgroundColor = self.animationBgStartColor;
    }
    self.view.ai_width = MainScreenWidth;
    self.view.ai_height = _customHeight;
    self.contentView.ai_height = _customHeight;
    [self.view addSubview:self.contentView];
    self.contentView.ai_y = _customHeight;
    [self.contentView addSubview:self.blankBtn];
    [_blankBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
}

/// 配置自定义容器高度
- (void)configCustomHeight:(CGFloat)customHeight {
    _customHeight = customHeight;
}

/// present 弹窗 默认动画 ULPopAlertAnimationBottomInBottomOut
- (void)show {
    [self showWithAnimation:_animationType];
}

/// present 弹窗 默认动画 ULPopAlertAnimationBottomInBottomOut
/// @param presentVc 通过制定的 vc 弹出
- (void)showWithPresentVc:(UIViewController *)presentVc {
    [self showWithAnimation:_animationType presentVc:presentVc];
}

/// present 弹窗
/// @param animation 动画类型
- (void)showWithAnimation:(ULPopAlertAnimationType)animation {
    UIViewController *rootVc = [self getRootViewController];
    [self showWithAnimation:animation presentVc:rootVc];
}

/// present 弹窗
/// @param animation 动画类型
/// @param presentVc 通过制定的 vc 弹出
- (void)showWithAnimation:(ULPopAlertAnimationType)animation
                presentVc:(UIViewController *)presentVc {
    _animationType = animation;
    if (!presentVc) {
        presentVc = [self getRootViewController];
    }
    @weakify(self)
    [AIThreadManager dispatch_main_async_safe:^{
        @strongify(self)
        [MainWindow endEditing:YES];
        //把 self 添加到数组里
        [[OTAlertViewManager sharedManager] addAlert:self];
        NSLog(@"弹窗present 数组个数%ld", [OTAlertViewManager sharedManager].alertArr.count);
        [presentVc presentViewController:self animated:NO completion:^{
            [self alertViewShowWithAnimation];
        }];
    }];
}

/// 在 window 上显示弹窗 默认动画 ULPopAlertAnimationBottomInBottomOut
- (void)showInWindow {
    [self showInWindowWithAnimation:self.animationType];
}

/// 在 window 上显示弹窗
/// @param animation 动画类型
- (void)showInWindowWithAnimation:(ULPopAlertAnimationType)animation {
    _animationType = animation;
    _inWindow = YES;
    [AIThreadManager dispatch_main_async_safe:^{
        [MainWindow endEditing:YES];
        //1.把 self.view 添加到window的窗口上
        [MainWindow addSubview:self.view];
        [self alertViewShowWithAnimation];
        //2.再把 self 添加到数组里
        [[OTAlertViewManager sharedManager] addAlert:self];
        NSLog(@"弹窗添加到:%@ 数组个数%ld", MainWindow, [OTAlertViewManager sharedManager].alertArr.count);
    }];
}

/// 在view上显示 默认动画 ULPopAlertAnimationBottomInBottomOut
/// @param view 此 view 要是全屏的 或者是控制器 不然效果不好
- (void)showInView:(UIView *)view {
    [self showInView:view animation:self.animationType];
}

/// 在view上显示
/// @param view 此 view 要是全屏的 或者是控制器 不然效果不好
/// @param animation 动画类型
- (void)showInView:(UIView *)view
         animation:(ULPopAlertAnimationType)animation {
    if (!view) {return;}
    _animationType = animation;
    _inWindow = YES;
    [AIThreadManager dispatch_main_async_safe:^{
        [view endEditing:YES];
        //1.把 self.view 添加到view上
        [view addSubview:self.view];
        [view bringSubviewToFront:self.view];
        [self alertViewShowWithAnimation];
        //2.再把 self 添加到数组里
        [[OTAlertViewManager sharedManager] addAlert:self];
        NSLog(@"弹窗添加到:%@ 数组个数%ld", view, [OTAlertViewManager sharedManager].alertArr.count);
    }];
}

/// 退出弹框
- (void)dismiss {
    [AIThreadManager dispatch_main_async_safe:^{
        [self alertViewDismissWithAnimation:YES];
    }];
}

/// 退出弹框
/// @param animation 动画类型
- (void)dismissWithAnimation:(ULPopAlertAnimationType)animation {
    [self dismissWithAnimation:animation handleBlock:YES];
}

/// 退出弹框
/// @param animation 动画类型
/// @param handleBlock YES:执行消失回调 NO:不执行
- (void)dismissWithAnimation:(ULPopAlertAnimationType)animation
                 handleBlock:(BOOL)handleBlock {
    _animationType = animation;
    [AIThreadManager dispatch_main_async_safe:^{
        [self alertViewDismissWithAnimation:handleBlock];
    }];
}

#pragma mark - private

/// 弹窗显示
- (void)alertViewShowWithAnimation {
    [self p_alertViewWillShow];
    CGFloat damping = self.forbiddenFlexible ? 1 : 0.85;//可以禁用弹性效果
    switch (_animationType) {
        case ULPopAlertAnimationBottomInBottomOut: //底部弹出底部消失
        case ULPopAlertAnimationBottomInTopOut: {//底部弹出顶部消失
            self.contentView.ai_y = self.customHeight;
            [UIView animateWithDuration:self.animationTime delay:0 usingSpringWithDamping:damping initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.contentView.ai_y = 0;
            } completion:^(BOOL finished) {
                [self p_alertViewDidShow];
            }];
        }
            break;
        case ULPopAlertAnimationTopInTopOut://顶部弹出顶部消失
        case ULPopAlertAnimationTopInBottomOut: {//顶部弹出底部消失
            self.contentView.ai_y = -self.customHeight;
            [UIView animateWithDuration:self.animationTime delay:0 usingSpringWithDamping:damping initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.contentView.ai_y = 0;
            } completion:^(BOOL finished) {
                [self p_alertViewDidShow];
            }];
        }
            break;
        case ULPopAlertAnimationPush: {//右侧弹出右侧消失 push动画
            self.contentView.ai_x = MainScreenWidth;
            self.contentView.ai_y = 0;
            [UIView animateWithDuration:self.animationTime delay:0 usingSpringWithDamping:damping initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.contentView.ai_x = 0;
            } completion:^(BOOL finished) {
                [self p_alertViewDidShow];
            }];
        }
            break;
        case ULPopAlertAnimationPushRTL: {//左侧弹出左侧消失 push动画
            self.contentView.ai_x = -MainScreenWidth;
            self.contentView.ai_y = 0;
            [UIView animateWithDuration:self.animationTime delay:0 usingSpringWithDamping:damping initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.contentView.ai_x = 0;
            } completion:^(BOOL finished) {
                [self p_alertViewDidShow];
            }];
        }
            break;
        case ULPopAlertAnimationAlpha: {//渐变
            self.contentView.ai_y = 0;
            self.contentView.alpha = 0;
            [UIView animateWithDuration:self.animationTime animations:^{
                self.contentView.alpha = 1;
            } completion:^(BOOL finished) {
                [self p_alertViewDidShow];
            }];
        }
            break;
        case ULPopAlertAnimationScal: {//缩放
            self.contentView.ai_y = 0;
            self.contentView.transform = CGAffineTransformScale(CGAffineTransformIdentity, CGFLOAT_MIN, CGFLOAT_MIN);
             [UIView animateWithDuration:self.animationTime *.6 animations:^{
                 self.contentView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
             } completion:^(BOOL finished) {
                 [UIView animateWithDuration:self.animationTime * .4 animations:^{
                     self.contentView.transform = CGAffineTransformIdentity;
                 } completion:^(BOOL finished) {
                     [self p_alertViewDidShow];
                 }];
             }];
        }
            break;
        case ULPopAlertAnimationNone: {//无动画
            self.contentView.ai_y = 0;
            [self p_alertViewDidShow];
        }
            break;
            
        default:
            break;
    }
}

/// 弹窗消失
- (void)alertViewDismissWithAnimation:(BOOL)handleBlock {
    [self p_alertViewWillDismiss];
    switch (_animationType) {
        case ULPopAlertAnimationBottomInBottomOut: //底部弹出底部消失
        case ULPopAlertAnimationTopInBottomOut: {//顶部弹出底部消失
            [UIView animateWithDuration:dismissTime animations:^{
                self.contentView.ai_y = self.customHeight;
            } completion:^(BOOL finished) {
                [self viewDismiss:handleBlock];
            }];
        }
            break;
        case ULPopAlertAnimationBottomInTopOut: //底部弹出顶部消失
        case ULPopAlertAnimationTopInTopOut: {//顶部弹出顶部消失
            [UIView animateWithDuration:dismissTime animations:^{
                self.contentView.ai_y = -self.customHeight;
            } completion:^(BOOL finished) {
                [self viewDismiss:handleBlock];
            }];
        }
            break;
        case ULPopAlertAnimationAlpha: {//渐变
            [UIView animateWithDuration:dismissTime animations:^{
                self.contentView.alpha = 0;
            } completion:^(BOOL finished) {
                [self viewDismiss:handleBlock];
            }];
        }
            break;
        case ULPopAlertAnimationPush: {//右侧弹出右侧消失 push动画
            [UIView animateWithDuration:dismissTime animations:^{
                self.contentView.ai_x = MainScreenWidth;
            } completion:^(BOOL finished) {
                [self viewDismiss:handleBlock];
            }];
        }
            break;
        case ULPopAlertAnimationPushRTL: {//左侧弹出左侧消失 push动画
            [UIView animateWithDuration:dismissTime animations:^{
                self.contentView.ai_x = -MainScreenWidth;
            } completion:^(BOOL finished) {
                [self viewDismiss:handleBlock];
            }];
        }
            break;
        case ULPopAlertAnimationScal: {//缩放
            [UIView animateWithDuration:dismissTime *.4 animations:^{
                self.contentView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:dismissTime * .6 animations:^{
                    self.contentView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.001, 0.001);
                } completion:^(BOOL finished) {
                    [self viewDismiss:handleBlock];
                }];
            }];
            [UIView animateWithDuration:dismissTime * .8 animations:^{
                self.contentView.alpha = 0;
            }];
        }
            break;
        case ULPopAlertAnimationNone: {//无动画
            self.contentView.hidden = YES;
            [self viewDismiss:handleBlock];
        }
            break;
            
        default:
            break;
    }
}

/// 退出弹窗
/// @param handleBlock 是否执行消失回调
- (void)viewDismiss:(BOOL)handleBlock {
    if (_inWindow) {
        [[OTAlertViewManager sharedManager] removeAlert:self];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        if (self.dismissBlock && handleBlock) {
            self.dismissBlock();
        }
        [self p_alertViewDidDismiss];
    } else {
        @weakify(self);
        [self p_dismissTopPresentViewController:^{
            @strongify(self);
            [[OTAlertViewManager sharedManager] removeAlert:self];
            [self.view removeFromSuperview];
            [self removeFromParentViewController];
            [super dismissViewControllerAnimated:NO completion:^{
                @strongify(self);
                if (self.dismissBlock && handleBlock) {
                    self.dismissBlock();
                }
                [self p_alertViewDidDismiss];
            }];
        }];
    }
    NSLog(@"弹窗被移除数组个数%ld", [OTAlertViewManager sharedManager].alertArr.count);
}

- (void)setTapBlankDismiss:(BOOL)tapBlankDismiss {
    _tapBlankDismiss = tapBlankDismiss;
    self.blankBtn.enabled = _tapBlankDismiss;
}

/// 空白按钮点击回调
- (void)p_blankBtnPress {
    [self dismiss];
}

/// 消除当前弹框顶部的所有 present 出来的控制器
/// - Parameter finishBlock: 处理完成的回调
- (void)p_dismissTopPresentViewController:(dispatch_block_t)finishBlock {
    UIViewController *presentingViewController = self.presentedViewController;
    NSMutableArray<UIViewController *> *tmpArr = [NSMutableArray array];
    if (presentingViewController) {
        [tmpArr addObject:presentingViewController]; //先加上它的上一个
        while (presentingViewController.presentedViewController) {//上一个的上一个
            [tmpArr addObject:presentingViewController.presentedViewController];
            presentingViewController = presentingViewController.presentedViewController;
        }
    }
    [self p_dismissTopPresentViewController:tmpArr.copy finishBlock:finishBlock];
}

/// 消除当前弹框顶部的所有 present 出来的控制器
/// - Parameters:
///   - alertList: 当前弹窗顶部的弹窗数组
///   - finishBlock: 处理完成的回调
- (void)p_dismissTopPresentViewController:(NSArray *)alertList
                              finishBlock:(dispatch_block_t)finishBlock {
    __block NSMutableArray *tmpList = [NSMutableArray arrayWithArray:alertList?:@[]];
    UIViewController *last = tmpList.lastObject;
    if (!last) {
        if (finishBlock) {
            finishBlock();
        }
        return;
    }
    @weakify(self);
    [last dismissViewControllerAnimated:NO completion:^{
        @strongify(self);
        [tmpList removeLastObject];
        [self p_dismissTopPresentViewController:tmpList.copy finishBlock:finishBlock];
    }];
}

#pragma mark -
#pragma mark - ULBaseAlertViewLifeCycleProtocol

/// 弹窗显示动画结束后回调
- (void)p_alertViewDidShow {
    if (self.didShowBlock) {
        self.didShowBlock(self);
    }
    [self ul_alertViewDidShow];
}

/// 弹窗显示动画结束后回调
/// 子类可以重写此方法
- (void)ul_alertViewDidShow {
    if (self.showBlock) {
        self.showBlock();
    }
    _isShowing = YES;
}

/// 弹窗即将显示
- (void)p_alertViewWillShow {
    if (self.willShowBlock) {
        self.willShowBlock(self);
    }
    /// 渐变背景动画
    if (self.enableAnimationBgColor && self.animationType != ULPopAlertAnimationNone) {
        self.view.backgroundColor = self.animationBgStartColor;
        [UIView animateWithDuration:self.animationTime animations:^{
            self.view.backgroundColor = self.animationBgColor;
        }];
    }
    [self ul_alertViewWillShow];
}

/// 弹窗即将显示
/// 子类可以重写此方法
- (void)ul_alertViewWillShow {
    
}

/// 弹窗将要消失回调
- (void)p_alertViewWillDismiss {
    if (self.willDismissBlock) {
        self.willDismissBlock(self);
    }
    // 渐变背景动画
    if (self.enableAnimationBgColor && self.animationType != ULPopAlertAnimationNone) {
        [UIView animateWithDuration:dismissTime animations:^{
            self.view.backgroundColor = self.animationBgStartColor;
        }];
    }
    [self ul_alertViewWillDismiss];
}

/// 弹窗即将消失
/// 供子类重写
- (void)ul_alertViewWillDismiss {
    
}

/// 弹窗消失动画结束后回调
- (void)p_alertViewDidDismiss {
    if (self.systemDismissBlock) {
        self.systemDismissBlock();
        self.systemDismissBlock = nil;
    } else if (self.didDismissBlock) {
        self.didDismissBlock(self);
    }
    [self ul_alertViewDidDismiss];
}

/// 弹窗消失动画结束后回调
/// 子类可重写此方法
- (void)ul_alertViewDidDismiss {
    _isShowing = NO;
}

#pragma mark - get

/// 获取弹窗控制器
- (UIViewController *)getRootViewController {
    UIViewController *rootVc = [self theTopViewControler];
    if (!rootVc) {
        rootVc = [MainWindow rootViewController];
    }
    return rootVc;
}

/// 获取当前最顶端控制器 需要替换为项目里的其它方法
- (UIViewController *)theTopViewControler {
    //获取根控制器
    UIViewController *rootVC = [[UIApplication sharedApplication].delegate window].rootViewController;
    UIViewController *parent = rootVC;
    //遍历 如果是presentViewController
    while ((parent = rootVC.presentedViewController) != nil ) {
        rootVC = parent;
    }
    while ([rootVC isKindOfClass:[UINavigationController class]]) {
        rootVC = [(UINavigationController *)rootVC topViewController];
    }
    return rootVC;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MainScreenWidth, MainScreenHeight)];
        _contentView.backgroundColor = [UIColor clearColor];
    }
    return _contentView;
}

- (UIButton *)blankBtn {
    if (!_blankBtn) {
        _blankBtn = [[UIButton alloc] init];
        _blankBtn.backgroundColor = [UIColor clearColor];
        [_blankBtn addTarget:self action:@selector(p_blankBtnPress) forControlEvents:UIControlEventTouchUpInside];
    }
    return _blankBtn;
}

@end

#pragma mark - ******************** 批量消除弹窗相关操作 ********************
#pragma mark - 批量消除弹窗相关操作

@interface ULBaseAlertViewController (batchDimiss)

@end

@implementation ULBaseAlertViewController (batchDimiss)

#pragma mark -
#pragma mark - ULBaseAlertViewBatchDismissProtocol

/// 是否包含这个类型的弹窗
+ (BOOL)isContainAlert:(NSString *)vc {
    return [[OTAlertViewManager sharedManager] isContainAlert:vc];
}

/// 隐藏 alertTag 类型的所有弹窗 慎用!
/// - Parameter alertTag: 弹窗类型
+ (void)dismissAlertViewWithTag:(NSInteger)alertTag {
    [self dismissAlertViewWithTag:alertTag animation:ULPopAlertAnimationAlpha];
}

/// 隐藏 alertTag 类型的所有弹窗 慎用!
/// - Parameters:
///   - alertTag: 弹窗类型
///   - animation: 动画类型
+ (void)dismissAlertViewWithTag:(NSInteger)alertTag
                      animation:(ULPopAlertAnimationType)animation {
    NSArray<__kindof ULBaseAlertViewController *> *alertList = [[OTAlertViewManager sharedManager] getAlertViewWithTag:alertTag];
    for (ULBaseAlertViewController *alert in alertList) {
        [alert dismissWithAnimation:animation];
    }
}

/// 隐藏 businessIdentifier 业务类型的所有弹窗 慎用!
/// - Parameter businessIdentifier: 业务类型标识
+ (void)dismissAlertWithBusinessIdentifier:(NSString *)businessIdentifier {
    [self dismissAlertWithBusinessIdentifier:businessIdentifier animation:ULPopAlertAnimationNone];
}

/// 隐藏 businessIdentifier 业务类型的所有弹窗 慎用!
/// - Parameters:
///   - businessIdentifier: 业务类型标识
///   - animation: 动画类型
+ (void)dismissAlertWithBusinessIdentifier:(NSString *)businessIdentifier
                                 animation:(ULPopAlertAnimationType)animation {
    NSArray<__kindof ULBaseAlertViewController *> *alertList = [[OTAlertViewManager sharedManager] getAlertViewWithBusinessIdentifier:businessIdentifier];
    for (ULBaseAlertViewController *alert in alertList) {
        [alert dismissWithAnimation:animation];
    }
}

/// 隐藏 alertClass 类型的所有弹窗 慎用!
/// - Parameter alertClass: alertClass
+ (void)dismissAlertViewWithClass:(NSString *)alertClass {
    [self dismissAlertViewWithClass:alertClass animation:ULPopAlertAnimationAlpha];
}

/// 隐藏 alertClass 类型的所有弹窗 慎用!
/// - Parameters:
///   - alertClass: alertClass
///   - animation: 动画类型
+ (void)dismissAlertViewWithClass:(NSString *)alertClass
                        animation:(ULPopAlertAnimationType)animation {
    NSArray<__kindof ULBaseAlertViewController *> *alertList = [self getAlertViewWithClass:alertClass];
    for (ULBaseAlertViewController *alert in alertList) {
        [alert dismissWithAnimation:animation];
    }
}

/// 获取此类型的所有弹窗
+ (NSArray<__kindof ULBaseAlertViewController *> *)getAlertViewWithClass:(NSString *)alertClass {
    return [[OTAlertViewManager sharedManager] getAlertViewWithClass:alertClass];
}

/// 清除 所有弹窗 慎用!
/// ⚠️ showInWindow 与 showInView 可直接消除
/// ⚠️ show 类型的弹框 只是单纯从数组中移除
/// 无动画类型
+ (void)removeAllAlertView {
    NSArray *alertList = [[OTAlertViewManager sharedManager] getAllAlertList];
    for (ULBaseAlertViewController *childVC in alertList) {
        if ([childVC isKindOfClass:[ULBaseAlertViewController class]]) {
            if (childVC.inWindow) {//showInView 或者 showInWindow
                [childVC dismissWithAnimation:ULPopAlertAnimationNone]; //无动画消除弹窗
            }
        }
    }
    [[OTAlertViewManager sharedManager] removeAllAlert];
}

@end

#pragma mark - ******************** 覆写父类 ********************
#pragma mark - 覆写父类

@implementation ULBaseAlertViewController (overWrite)

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    if (![[self theTopViewControler] isKindOfClass:ULBaseAlertViewController.class]) { // 容错 basealert的调用父类方法
        [super dismissViewControllerAnimated:flag completion:completion];
        return;
    }
    self.systemDismissBlock = completion;
    if (flag) {
        [self dismiss];
    } else {
        [self dismissWithAnimation:(ULPopAlertAnimationNone)];
    }
}

@end


