//
//  ULBaseBottomPopAlertViewController.m
//  UpLive
//
//  Created by xuqinqiang on 2022/1/25.
//  Copyright © 2022 AsiaInnovations. All rights reserved.
//

#import "ULBaseBottomPopAlertViewController.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import <AIBasicModule/UIView+AICategory.h>
#import <AIBasicModule/AIHotSpotsButton.h>
#import <AIBasicModule/NSNumber+ULDecimalNumber.h>
#import <Masonry/Masonry.h>
#import "UIColor+AICategory.h"

@interface ULBaseBottomPopAlertViewController () <UIGestureRecognizerDelegate>
/// 内容容器
@property (nonatomic, strong) UIView *wrapView;
/// 关闭按钮
@property (nonatomic, strong) AIHotSpotsButton *closeBtn;
/// 内容视图起始位置
@property (nonatomic, assign) CGRect originFrame;
/// 拖拽手势
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
/// 变量为了持有列表视图
@property (nonatomic, weak) UIScrollView *scrollView;
/// 是否是拖拽的列表视图
@property (nonatomic, assign) BOOL isDragScrollView;
/// 上一次拖动过渡的值
@property (nonatomic, assign) CGFloat lastTransitionY;
@end

@implementation ULBaseBottomPopAlertViewController

- (void)viewDidLoad {
    /// 底部弹出 底部消失 内部指定死值
    self.animationBgColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    [super viewDidLoad];
    self.dragDistanceRatio = 0.5;
    self.dragDismissSpeed = 800;
    self.forbiddenFlexible = YES;
    self.tapBlankDismiss = YES;
    [self prepareSubViews];
    //添加拖动手势
    [self.wrapView addGestureRecognizer:self.panGesture];
    self.panGesture.enabled = self.enableSlidePanGesture;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self p_radiusWithRadius:self.cornerRadius corner:UIRectCornerTopLeft | UIRectCornerTopRight];
    CGRect frame = self.wrapView.frame;
    frame.size.height = self.customHeight; //这玩意有默认值的
    self.originFrame = frame;
}

- (void)prepareSubViews {
    // 没有给容器的高度 需要子视图撑起
    [self.contentView addSubview:self.wrapView];
    [self.wrapView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.and.trailing.and.bottom.mas_equalTo(0);
    }];
    
    [self.wrapView addSubview:self.closeBtn];
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(-20);
        make.top.mas_equalTo(15);
    }];
    self.closeBtn.hidden = self.hiddenCloseBtn;
}

#pragma mark - public

/// 重新设置关闭按钮图片
/// @param img img
- (void)setCloseBtnImg:(UIImage *)img {
    [_closeBtn setImage:img forState:UIControlStateNormal];
}

/// 重新设置时候隐藏关闭按钮
/// @param hiddenCloseBtn 是否关闭
- (void)setHiddenCloseBtn:(BOOL)hiddenCloseBtn{
    _hiddenCloseBtn = hiddenCloseBtn;
    self.closeBtn.hidden = hiddenCloseBtn;
}

/// 会存在多个界面同时修改此变量的情况
/// @param enablePanGesture 是否开启滑动退出手势
- (void)setEnableSlidePanGesture:(BOOL)enableSlidePanGesture {
    _enableSlidePanGesture = enableSlidePanGesture;
    self.panGesture.enabled = enableSlidePanGesture;
}

#pragma mark - private

/// 切圆角
/// @param radius 圆角大小
/// @param corner 圆角位置
- (void)p_radiusWithRadius:(CGFloat)radius
                    corner:(UIRectCorner)corner {
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.wrapView.bounds
                                               byRoundingCorners:corner
                                                     cornerRadii:CGSizeMake(radius, radius)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.wrapView.bounds;
    maskLayer.path = path.CGPath;
    self.wrapView.layer.mask = nil;
    self.wrapView.layer.mask = maskLayer;
}

#pragma mark -
#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == self.panGesture) {
        UIView *touchView = touch.view;
        while (touchView != nil) {
            if ([touchView isKindOfClass:[UIScrollView class]]) {
                self.scrollView = (UIScrollView *)touchView;
                self.isDragScrollView = YES;
                break;
            } else if (touchView == self.wrapView) {
                self.isDragScrollView = NO;
                break;
            }
            touchView = (UIView *)[touchView nextResponder];
        }
    }
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

// 是否与其他手势共存
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer == self.panGesture) {
        if ([otherGestureRecognizer isKindOfClass:NSClassFromString(@"UIScrollViewPanGestureRecognizer")] || [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
            if ([otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark -
#pragma mark - 拖拽手势相关

- (void)p_onPanGesture:(UIPanGestureRecognizer *)panGesture {
    CGPoint translation = [panGesture translationInView:self.wrapView];
    if (self.isDragScrollView) {//拖动的是滚动视图
        // 当UIScrollView在最顶部时，处理视图的滑动
        if (self.scrollView.contentOffset.y <= 0) {
            if (translation.y > 0) { // 向下拖拽
                self.scrollView.contentOffset = CGPointZero;
                self.scrollView.panGestureRecognizer.enabled = NO;
                self.isDragScrollView = NO;
                self.wrapView.ai_y += translation.y;
            }
        }
    } else {//不含有滚动视图的
        CGFloat contentM = (self.view.frame.size.height - self.wrapView.frame.size.height);
        if (translation.y > 0) { // 向下拖拽
            self.wrapView.ai_y += translation.y;
        } else if (translation.y < 0 && self.wrapView.frame.origin.y > contentM) { // 向上拖拽
            self.wrapView.ai_y = MAX((self.wrapView.frame.origin.y + translation.y), self.originFrame.origin.y);
        }
    }
    
    [panGesture setTranslation:CGPointZero inView:self.wrapView];
    
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        self.view.backgroundColor = self.animationBgColor;
    } else if (panGesture.state == UIGestureRecognizerStateChanged) {
        // 计算 当前 wrapView.y 相比较 wrapView 的起点移动了多少
        CGFloat wrapMoveDistance = self.wrapView.ai_y - self.originFrame.origin.y;
        CGFloat bgAlpha = wrapMoveDistance <= 0.0 ? 1.0 : (1.0 - wrapMoveDistance / self.wrapView.ai_height);
        bgAlpha = bgAlpha > 1.0 ? 1.0 : bgAlpha;
        bgAlpha = bgAlpha <= 0.0 ? 0.01 : bgAlpha;
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4 * bgAlpha];
    } else if (panGesture.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [panGesture velocityInView:self.wrapView];
        
        self.scrollView.panGestureRecognizer.enabled = YES;
        
        CGFloat dragAnimationTime = 0.25 * 0.5; //消失动画的持续时间
        //拖拽松开回位Block
        @weakify(self);
        dispatch_block_t dragReboundBlock = ^{
            @strongify(self);
            BOOL isOriginY = [@(self.wrapView.ai_y) compare:@(self.originFrame.origin.y)] == NSOrderedSame;
            [UIView animateWithDuration:dragAnimationTime
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                self.wrapView.ai_y = self.originFrame.origin.y;
                if (!isOriginY) {//不在顶点 做渐变动画
                    self.view.backgroundColor = self.animationBgColor;
                }
            } completion:^(BOOL finished) {
                
            }];
            if (isOriginY) { //在顶端还做动画的话 会闪烁一下
                self.view.backgroundColor = self.animationBgColor;
            }
        };
        
        BOOL isCanDismiss = NO;
        
        CGFloat dragDistance = self.wrapView.ai_height * self.dragDistanceRatio; //消失临界值
        if ((fabs(self.wrapView.ai_y - self.originFrame.origin.y) >= dragDistance && dragDistance != 0) || (velocity.y > self.dragDismissSpeed && !self.isDragScrollView)) {
            isCanDismiss = YES;
        }
        
        if (isCanDismiss) {
            [UIView animateWithDuration:dragAnimationTime animations:^{
                self.wrapView.ai_y = self.customHeight;
                self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.01];
            } completion:^(BOOL finished) {
                self.enableAnimationBgColor = NO; //上边已经做了动画了 就不让父视图做渐变动画了
                [self dismissWithAnimation:ULPopAlertAnimationNone handleBlock:NO];
            }];
        } else {
            dragReboundBlock();
        }
    }
    
    self.lastTransitionY = translation.y;
}

#pragma mark - action

- (void)p_closeAction {
    [self dismiss];
}

#pragma mark - get

- (UIView *)wrapView {
    if (!_wrapView) {
        _wrapView = [[UIView alloc] init];
        _wrapView.backgroundColor = UIColor.whiteColor;
    }
    return _wrapView;
}

- (AIHotSpotsButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [[AIHotSpotsButton alloc] init];
        [_closeBtn zoomHotSpotsToSize:CGSizeMake(30, 30)];
#ifdef Channel_UpLive_New
        [_closeBtn setImage:[UIImage imageNamed:@"new_icon_close_gray"] forState:UIControlStateNormal];
#else
        [_closeBtn setImage:[UIImage imageNamed:@"chat_icon_close"] forState:UIControlStateNormal];
#endif
        [_closeBtn addTarget:self action:@selector(p_closeAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

- (UIPanGestureRecognizer *)panGesture {
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(p_onPanGesture:)];
        _panGesture.delegate = self;
    }
    return _panGesture;
}

@end
