//
//  ULBaseCenterAlertViewController.m
//  UpLive
//
//  Created by xuqinqiang on 2022/1/25.
//  Copyright © 2022 AsiaInnovations. All rights reserved.
//

#import "ULBaseCenterAlertViewController.h"
#import "UIColor+AICategory.h"
#import "Masonry.h"
#import "AIHotSpotsButton.h"

@interface ULBaseCenterAlertViewController ()
/// 中间的内容视图 所有的子视图添加到此视图中
@property (nonatomic, strong) UIView *wrapView;
/// 关闭按钮
@property (nonatomic, strong) AIHotSpotsButton *closeBtn;
@end

@implementation ULBaseCenterAlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.forbiddenFlexible = YES;
    self.tapBlankDismiss = YES;
    [self createSubUI];
}

- (void)createSubUI {
    //没有给容器的高度 需要子类撑起
    [self.contentView addSubview:self.wrapView];
    [self.wrapView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(0);
        make.width.mas_equalTo(kMostAlertWidth);
    }];
    
    [self.wrapView addSubview:self.closeBtn];
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(-20);
        make.top.mas_equalTo(15);
    }];
    self.closeBtn.hidden = self.hiddenCloseBtn;
}

#pragma mark - public

/// 重新设置时候隐藏关闭按钮
/// @param hiddenCloseBtn 是否关闭
- (void)setHiddenCloseBtn:(BOOL)hiddenCloseBtn{
    _hiddenCloseBtn = hiddenCloseBtn;
    self.closeBtn.hidden = hiddenCloseBtn;
}
/// 重新设置关闭按钮图片
/// @param img img
- (void)setCloseBtnImg:(UIImage *)img {
    [_closeBtn setImage:img forState:UIControlStateNormal];
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
        _wrapView.layer.masksToBounds = YES;
        _wrapView.layer.cornerRadius = 20;
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

@end
