//
//  MRFlipTransitionAnimator.h
//  LayerContentScaleTest
//
//  Created by mmt on 20/6/14.
//  Copyright (c) 2014 Michael WU. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MRFlipTransitionPresentingStyle) {
    MRFlipTransitionPresentingFromBottom = 0,
    MRFlipTransitionPresentingFromInfinityAway
};

@interface MRFlipTransition : NSObject <UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate>

@property (nonatomic, strong)   UIImage *coverImage;

- (instancetype)initWithPresentingViewController:(UIViewController *)controller presentBlock:(UIViewController *(^)(void))block;
- (void)presentFrom:(MRFlipTransitionPresentingStyle)direction completion:(void(^)(void))completion;
- (void)dismissTo:(MRFlipTransitionPresentingStyle)direction completion:(void(^)(void))completion;

- (void)updateContentSnapshot:(UIView *)view afterScreenUpdate:(BOOL)update;

@end
