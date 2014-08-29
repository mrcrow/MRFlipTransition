//
//  UIViewController+MRFlipTransitino.h
//  FlipDemo
//
//  Created by Michael WU on 29/8/14.
//  Copyright (c) 2014 Michael WU. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (MRFlipTransitino)

- (UIView *)viewForTransitionContext:(id <UIViewControllerContextTransitioning>)transitionContext;

@end
