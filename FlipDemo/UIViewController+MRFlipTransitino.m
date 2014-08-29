//
//  UIViewController+MRFlipTransitino.m
//  FlipDemo
//
//  Created by Michael WU on 29/8/14.
//  Copyright (c) 2014 Michael WU. All rights reserved.
//
//  Solved by @bcherry on Stackoverflow:
//  http://stackoverflow.com/questions/24338700/from-view-controller-disappears-using-uiviewcontrollercontexttransitioning
//

#import "UIViewController+MRFlipTransitino.h"

@implementation UIViewController (MRFlipTransitino)

- (UIView *)viewForTransitionContext:(id <UIViewControllerContextTransitioning>)transitionContext
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([transitionContext respondsToSelector:@selector(viewForKey:)])
    {
        NSString *key = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey] == self ? UITransitionContextFromViewKey : UITransitionContextToViewKey;
        return [transitionContext viewForKey:key];
    }
    else
    {
        return self.view;
    }
#else
    return self.view;
#endif
}

@end
